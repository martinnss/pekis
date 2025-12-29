import Foundation
import CloudKit
import Combine

/// CloudKit service implementation for private couple data synchronization
/// All data stays in users' private iCloud containers - developer has zero access
@MainActor
final class CloudKitService: ObservableObject, CloudKitServiceProtocol {

    // MARK: - Published Properties

    @Published private(set) var currentUserID: String?
    @Published private(set) var couple: Couple?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var pendingShareMetadata: CKShare.Metadata?

    var isPaired: Bool {
        guard let couple = couple else { return false }
        return couple.partnerBIdentifier != nil
    }

    // MARK: - Private Properties

    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private var sharedDatabase: CKDatabase { container.sharedCloudDatabase }

    private let coupleZoneName = "CoupleZone"
    private var coupleZoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: coupleZoneName, ownerName: CKCurrentUserDefaultName)
    }

    private var coupleRecord: CKRecord?
    private var shareRecord: CKShare?

    // MARK: - Initialization

    init(containerIdentifier: String = "iCloud.molivares.PekisGame") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.privateDatabase = container.privateCloudDatabase
    }

    // MARK: - Setup

    func setup() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Get current user ID
            let userID = try await container.userRecordID()
            currentUserID = userID.recordName

            // Ensure the custom zone exists
            try await createZoneIfNeeded()

            // Check for existing couple
            await checkExistingCouple()
        } catch {
            handleError(error)
        }
    }

    func checkExistingCouple() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // First check private database for owned couple
            if let ownedCouple = try await fetchOwnedCouple() {
                self.couple = ownedCouple
                ownedCouple.saveToCache()
                return
            }

            // Then check shared database for partner's couple
            if let sharedCouple = try await fetchSharedCouple() {
                self.couple = sharedCouple
                sharedCouple.saveToCache()
                return
            }

            // No couple found - load from cache for offline access
            if let cachedCouple = Couple.loadFromCache() {
                self.couple = cachedCouple
            }
        } catch {
            // On error, try loading from cache
            if let cachedCouple = Couple.loadFromCache() {
                self.couple = cachedCouple
            }
            handleError(error)
        }
    }

    // MARK: - Zone Management

    private func createZoneIfNeeded() async throws {
        let zone = CKRecordZone(zoneID: coupleZoneID)

        do {
            _ = try await privateDatabase.save(zone)
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Zone already exists, that's fine
        } catch let error as CKError where error.code == .zoneNotFound {
            // Zone doesn't exist, create it
            _ = try await privateDatabase.save(zone)
        }
    }

    // MARK: - Couple Management

    func createCouple(name: String) async throws -> Couple {
        guard let userID = currentUserID else {
            throw CloudKitError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        let newCouple = Couple(
            partnerAIdentifier: userID,
            partnerAName: name
        )

        let record = newCouple.toRecord(in: coupleZoneID)

        do {
            let savedRecord = try await privateDatabase.save(record)
            self.coupleRecord = savedRecord

            if let couple = Couple(record: savedRecord) {
                self.couple = couple
                couple.saveToCache()
                return couple
            } else {
                throw CloudKitError.saveFailed(NSError(domain: "", code: -1))
            }
        } catch {
            throw CloudKitError.saveFailed(error)
        }
    }

    func acceptShare(_ metadata: CKShare.Metadata) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            // Accept the share
            _ = try await container.accept(metadata)

            // Fetch the shared couple record
            if let sharedCouple = try await fetchSharedCouple() {
                // Update with partner B info
                var updatedCouple = sharedCouple
                updatedCouple.partnerBName = "" // Will be set separately

                self.couple = updatedCouple
                updatedCouple.saveToCache()
            }
        } catch {
            throw CloudKitError.shareFailed(error)
        }
    }

    func updateReunionDate(_ date: Date) async throws {
        guard var currentCouple = couple else {
            throw CloudKitError.coupleNotFound
        }

        isLoading = true
        defer { isLoading = false }

        currentCouple.reunionDate = date

        try await saveUpdatedCouple(currentCouple)
    }

    func updateMyName(_ name: String) async throws {
        guard var currentCouple = couple, let userID = currentUserID else {
            throw CloudKitError.coupleNotFound
        }

        isLoading = true
        defer { isLoading = false }

        if currentCouple.partnerAIdentifier == userID {
            currentCouple.partnerAName = name
        } else {
            currentCouple.partnerBName = name
        }

        try await saveUpdatedCouple(currentCouple)
    }

    private func saveUpdatedCouple(_ updatedCouple: Couple) async throws {
        // Fetch existing record or create new one
        let record: CKRecord
        if let existing = coupleRecord {
            record = existing
            updatedCouple.updateRecord(record)
        } else {
            record = updatedCouple.toRecord(in: coupleZoneID)
        }

        do {
            let savedRecord = try await privateDatabase.save(record)
            self.coupleRecord = savedRecord

            if let couple = Couple(record: savedRecord) {
                self.couple = couple
                couple.saveToCache()
            }
        } catch {
            throw CloudKitError.saveFailed(error)
        }
    }

    // MARK: - Love Notes

    func sendLoveNote(content: String) async throws {
        guard let couple = couple, let userID = currentUserID else {
            throw CloudKitError.coupleNotFound
        }

        isLoading = true
        defer { isLoading = false }

        let note = LoveNote(
            coupleID: couple.id,
            authorID: userID,
            content: content
        )

        let record = note.toRecord(in: coupleZoneID)

        do {
            _ = try await privateDatabase.save(record)
        } catch {
            throw CloudKitError.saveFailed(error)
        }
    }

    func fetchLoveNotes() async throws -> [LoveNote] {
        guard let couple = couple else {
            throw CloudKitError.coupleNotFound
        }

        let predicate = NSPredicate(format: "coupleID == %@", couple.id)
        let query = CKQuery(recordType: LoveNote.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            // Fetch from private database (owned records)
            var notes: [LoveNote] = []

            let privateResults = try await privateDatabase.records(matching: query)
            for (_, result) in privateResults.matchResults {
                if case .success(let record) = result,
                   let note = LoveNote(record: record) {
                    notes.append(note)
                }
            }

            // Fetch from shared database (partner's records)
            let sharedResults = try await sharedDatabase.records(matching: query)
            for (_, result) in sharedResults.matchResults {
                if case .success(let record) = result,
                   let note = LoveNote(record: record) {
                    if !notes.contains(where: { $0.id == note.id }) {
                        notes.append(note)
                    }
                }
            }

            // Sort and cache
            notes.sort { $0.createdAt > $1.createdAt }
            LoveNote.saveToCache(notes)

            return notes
        } catch {
            // Return cached notes on error
            let cached = LoveNote.loadFromCache()
            if !cached.isEmpty {
                return cached
            }
            throw CloudKitError.fetchFailed(error)
        }
    }

    // MARK: - This or That

    func saveThisOrThatAnswer(questionIndex: Int, selectedOption: Int) async throws {
        guard let couple = couple, let userID = currentUserID else {
            throw CloudKitError.coupleNotFound
        }

        isLoading = true
        defer { isLoading = false }

        let answer = ThisOrThatAnswer(
            coupleID: couple.id,
            authorID: userID,
            questionIndex: questionIndex,
            selectedOption: selectedOption
        )

        let record = answer.toRecord(in: coupleZoneID)

        do {
            _ = try await privateDatabase.save(record)
        } catch {
            throw CloudKitError.saveFailed(error)
        }
    }

    func fetchThisOrThatAnswers() async throws -> [ThisOrThatAnswer] {
        guard let couple = couple else {
            throw CloudKitError.coupleNotFound
        }

        let predicate = NSPredicate(format: "coupleID == %@", couple.id)
        let query = CKQuery(recordType: ThisOrThatAnswer.recordType, predicate: predicate)

        do {
            var answers: [ThisOrThatAnswer] = []

            // Fetch from private database
            let privateResults = try await privateDatabase.records(matching: query)
            for (_, result) in privateResults.matchResults {
                if case .success(let record) = result,
                   let answer = ThisOrThatAnswer(record: record) {
                    answers.append(answer)
                }
            }

            // Fetch from shared database
            let sharedResults = try await sharedDatabase.records(matching: query)
            for (_, result) in sharedResults.matchResults {
                if case .success(let record) = result,
                   let answer = ThisOrThatAnswer(record: record) {
                    if !answers.contains(where: { $0.id == answer.id }) {
                        answers.append(answer)
                    }
                }
            }

            // Cache results
            ThisOrThatAnswer.saveToCache(answers)

            return answers
        } catch {
            let cached = ThisOrThatAnswer.loadFromCache()
            if !cached.isEmpty {
                return cached
            }
            throw CloudKitError.fetchFailed(error)
        }
    }

    // MARK: - Sharing

    func getOrCreateShare() async throws -> CKShare {
        guard let coupleRecord = coupleRecord else {
            throw CloudKitError.coupleNotFound
        }

        // Check if share already exists
        if let existingShare = shareRecord {
            return existingShare
        }

        // Fetch existing share if any
        if let shareReference = coupleRecord.share {
            do {
                let share = try await privateDatabase.record(for: shareReference.recordID) as? CKShare
                if let share = share {
                    self.shareRecord = share
                    return share
                }
            } catch {
                // Share doesn't exist, create new one
            }
        }

        // Create new share
        let share = CKShare(rootRecord: coupleRecord)
        share[CKShare.SystemFieldKey.title] = "Pekis Couple" as CKRecordValue
        share.publicPermission = .none // Private sharing only

        do {
            let result = try await privateDatabase.modifyRecords(
                saving: [coupleRecord, share],
                deleting: []
            )

            for (_, saveResult) in result.saveResults {
                if case .success(let record) = saveResult {
                    if let savedShare = record as? CKShare {
                        self.shareRecord = savedShare
                        return savedShare
                    }
                }
            }

            throw CloudKitError.shareFailed(NSError(domain: "", code: -1))
        } catch {
            throw CloudKitError.shareFailed(error)
        }
    }

    // MARK: - Subscriptions

    func subscribeToChanges() async throws {
        let subscriptionID = "couple-zone-changes"

        // Check if subscription already exists
        do {
            _ = try await privateDatabase.subscription(for: subscriptionID)
            return // Already subscribed
        } catch {
            // Subscription doesn't exist, create it
        }

        let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true // Silent push
        subscription.notificationInfo = notificationInfo

        do {
            _ = try await privateDatabase.save(subscription)
        } catch {
            // Subscription might already exist
        }
    }

    func handleNotification() async {
        await checkExistingCouple()
    }

    // MARK: - Private Helpers

    private func fetchOwnedCouple() async throws -> Couple? {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: Couple.recordType, predicate: predicate)

        let results = try await privateDatabase.records(matching: query, inZoneWith: coupleZoneID)

        for (_, result) in results.matchResults {
            if case .success(let record) = result {
                self.coupleRecord = record
                return Couple(record: record)
            }
        }

        return nil
    }

    private func fetchSharedCouple() async throws -> Couple? {
        // Get all shared record zones
        let zones = try await sharedDatabase.allRecordZones()

        for zone in zones {
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: Couple.recordType, predicate: predicate)

            let results = try await sharedDatabase.records(matching: query, inZoneWith: zone.zoneID)

            for (_, result) in results.matchResults {
                if case .success(let record) = result {
                    self.coupleRecord = record
                    return Couple(record: record)
                }
            }
        }

        return nil
    }

    private func handleError(_ error: Error) {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated:
                errorMessage = CloudKitError.notAuthenticated.errorDescription
            case .networkUnavailable, .networkFailure:
                errorMessage = "Network unavailable. Data will sync when connection is restored."
            case .quotaExceeded:
                errorMessage = "iCloud storage is full. Please free up space."
            default:
                errorMessage = ckError.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview/Testing Support

#if DEBUG
@MainActor
final class MockCloudKitService: ObservableObject, CloudKitServiceProtocol {
    @Published var currentUserID: String? = "mock-user-123"
    @Published var couple: Couple? = Couple(
        partnerAIdentifier: "mock-user-123",
        partnerBIdentifier: "partner-456",
        partnerAName: "You",
        partnerBName: "Partner",
        reunionDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())
    )
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var pendingShareMetadata: CKShare.Metadata?

    var isPaired: Bool { couple?.partnerBIdentifier != nil }

    func setup() async {}
    func checkExistingCouple() async {}
    func createCouple(name: String) async throws -> Couple {
        let newCouple = Couple(partnerAIdentifier: currentUserID ?? "", partnerAName: name)
        couple = newCouple
        return newCouple
    }
    func acceptShare(_ metadata: CKShare.Metadata) async throws {}
    func updateReunionDate(_ date: Date) async throws {
        couple?.reunionDate = date
    }
    func updateMyName(_ name: String) async throws {}
    func sendLoveNote(content: String) async throws {}
    func fetchLoveNotes() async throws -> [LoveNote] { [] }
    func saveThisOrThatAnswer(questionIndex: Int, selectedOption: Int) async throws {}
    func fetchThisOrThatAnswers() async throws -> [ThisOrThatAnswer] { [] }
    func getOrCreateShare() async throws -> CKShare {
        fatalError("Not implemented for mock")
    }
    func subscribeToChanges() async throws {}
    func handleNotification() async {}
}
#endif
