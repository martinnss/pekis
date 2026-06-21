import Foundation
import CloudKit
import Combine
import OSLog

/// CloudKit service implementation for private couple data synchronization
/// All data stays in users' private iCloud containers - developer has zero access
///
/// IMPORTANT: CloudKit Sharing Setup
/// - Couple records are stored in the default zone to ensure proper sharing
/// - The container must be configured with CloudKit capability in Xcode
/// - The entitlements must include the container identifier matching Xcode
/// - Users must be signed into iCloud in Settings > Apple Account > iCloud
///
/// If sharing fails with "element don't available" error:
/// 1. Verify both users are signed into iCloud with their Apple IDs
/// 2. Check that the container exists in CloudKit Console
/// 3. Ensure the couple record was successfully saved (check Xcode console logs)
/// 4. Wait a few seconds before sharing - CloudKit may need time to sync
/// 5. Try tapping "Get Link" button to retry generating the share URL
@MainActor
final class CloudKitService: ObservableObject, CloudKitServiceProtocol {
    // MARK: - Published Properties

    @Published private(set) var currentUserID: String?
    @Published private(set) var couple: Couple? {
        didSet { WidgetBridge.update(couple: couple, currentUserID: currentUserID) }
    }
    @Published private(set) var isLoading = false
    /// True once the initial cold-launch couple check has finished. Drives the
    /// one-time full-screen LoadingView so later `isLoading` toggles (e.g. while
    /// creating a couple) don't tear the onboarding flow down and reset it.
    @Published private(set) var hasLoadedInitialState = false
    @Published var errorMessage: String?
    @Published var pendingShareMetadata: CKShare.Metadata?
    @Published var needsPartnerName = false

    var isPaired: Bool {
        guard let couple = couple else { return false }
        return couple.partnerBIdentifier != nil
    }

    // MARK: - Private Properties

    // Lazy to defer CKContainer creation until first use — prevents crash in test
    // environments where entitlements are absent (CODE_SIGNING_ALLOWED=NO).
    private lazy var container: CKContainer = CKContainer(identifier: containerIdentifier)
    private lazy var privateDatabase: CKDatabase = container.privateCloudDatabase
    private var sharedDatabase: CKDatabase { container.sharedCloudDatabase }

    private let containerIdentifier: String
    private let coupleZoneName = "CoupleZone"
    private var coupleZoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: coupleZoneName, ownerName: CKCurrentUserDefaultName)
    }

    private var coupleRecord: CKRecord?
    private var shareRecord: CKShare?

    // MARK: - Initialization

    init(containerIdentifier: String? = nil) {
        self.containerIdentifier = containerIdentifier ?? AppConfiguration.cloudKitContainerIdentifier
    }

    // MARK: - Setup

    func setup() async {
        isLoading = true
        defer { isLoading = false; hasLoadedInitialState = true }

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

        // Save couple in private custom zone (required for sharing)
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

        // Wait for currentUserID if app launched cold from a share URL (races with setup())
        if currentUserID == nil {
            for _ in 0..<5 {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                if currentUserID != nil { break }
            }
            guard currentUserID != nil else { throw CloudKitError.notAuthenticated }
        }

        do {
            _ = try await container.accept(metadata)
        } catch {
            throw CloudKitError.shareFailed(error)
        }

        // Retry fetching the shared couple — CloudKit has a propagation delay after accept()
        var sharedCouple: Couple?
        for attempt in 1...3 {
            if let found = try? await fetchSharedCouple() {
                sharedCouple = found
                break
            }
            if attempt < 3 {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }

        guard var couple = sharedCouple else { return }

        if let userID = currentUserID, couple.partnerBIdentifier == nil {
            couple.partnerBIdentifier = userID
            do {
                try await saveUpdatedCouple(couple)
            } catch {
                errorMessage = "Joined successfully, but couldn't save your profile. Please try again."
                needsPartnerName = true
                return
            }
        } else {
            self.couple = couple
            couple.saveToCache()
        }
        needsPartnerName = couple.partnerBName == nil || couple.partnerBName?.isEmpty == true
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

        // BUG 2 FIX: Use the fetched couple record's actual zone (has correct ownerName
        // for Partner B, who is in the sharedDatabase). Both partners write to the same
        // zone — Partner A via privateDatabase, Partner B via sharedDatabase.
        let zoneID = coupleRecord?.recordID.zoneID ?? coupleZoneID
        let record = note.toRecord(in: zoneID)
        let database = zoneID.ownerName == CKCurrentUserDefaultName ? privateDatabase : sharedDatabase

        do {
            _ = try await database.save(record)
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

        // BUG 2 FIX: Must specify inZoneWith — records(matching:) without a zone only
        // searches the DEFAULT zone, not our custom CoupleZone. Also route to the
        // correct database (private for Partner A, shared for Partner B). All records
        // for both partners live in Partner A's zone, so one database fetch is enough.
        let zoneID = coupleRecord?.recordID.zoneID ?? coupleZoneID
        let database = zoneID.ownerName == CKCurrentUserDefaultName ? privateDatabase : sharedDatabase

        do {
            var notes: [LoveNote] = []

            let results = try await database.records(matching: query, inZoneWith: zoneID)
            for (_, result) in results.matchResults {
                if case .success(let record) = result,
                   let note = LoveNote(record: record) {
                    notes.append(note)
                }
            }

            notes.sort { $0.createdAt > $1.createdAt }
            LoveNote.saveToCache(notes)
            return notes
        } catch {
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

        // BUG 2 FIX: same zone routing as sendLoveNote
        let zoneID = coupleRecord?.recordID.zoneID ?? coupleZoneID
        let record = answer.toRecord(in: zoneID)
        let database = zoneID.ownerName == CKCurrentUserDefaultName ? privateDatabase : sharedDatabase

        do {
            _ = try await database.save(record)
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

        // BUG 2 FIX: same zone + database routing as fetchLoveNotes
        let zoneID = coupleRecord?.recordID.zoneID ?? coupleZoneID
        let database = zoneID.ownerName == CKCurrentUserDefaultName ? privateDatabase : sharedDatabase

        do {
            var answers: [ThisOrThatAnswer] = []

            let results = try await database.records(matching: query, inZoneWith: zoneID)
            for (_, result) in results.matchResults {
                if case .success(let record) = result,
                   let answer = ThisOrThatAnswer(record: record) {
                    answers.append(answer)
                }
            }

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

    // MARK: - Moments

    func saveMoment(imageData: Data, prompt: String) async throws {
        guard let couple = couple, let userID = currentUserID else {
            throw CloudKitError.coupleNotFound
        }

        isLoading = true
        defer { isLoading = false }

        let moment = MomentShareRecord(
            coupleID: couple.id,
            authorID: userID,
            prompt: prompt
        )

        let zoneID = coupleRecord?.recordID.zoneID ?? coupleZoneID
        let record = moment.toRecord(in: zoneID)

        // Write JPEG data to a temp file — CKAsset requires a file URL
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(moment.id + ".jpg")
        do {
            try imageData.write(to: tempURL)
        } catch {
            throw CloudKitError.saveFailed(error)
        }
        defer { try? FileManager.default.removeItem(at: tempURL) }

        record[MomentShareRecord.RecordKey.photo.rawValue] = CKAsset(fileURL: tempURL)

        let database = zoneID.ownerName == CKCurrentUserDefaultName ? privateDatabase : sharedDatabase

        do {
            _ = try await database.save(record)
        } catch {
            throw CloudKitError.saveFailed(error)
        }
    }

    func fetchTodaysMoments() async throws -> [MomentShareRecord] {
        guard let couple = couple else {
            throw CloudKitError.coupleNotFound
        }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = NSPredicate(
            format: "coupleID == %@ AND createdAt >= %@",
            couple.id,
            startOfDay as NSDate
        )
        let query = CKQuery(recordType: MomentShareRecord.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let zoneID = coupleRecord?.recordID.zoneID ?? coupleZoneID
        let database = zoneID.ownerName == CKCurrentUserDefaultName ? privateDatabase : sharedDatabase

        do {
            var moments: [MomentShareRecord] = []
            let results = try await database.records(matching: query, inZoneWith: zoneID)
            for (_, result) in results.matchResults {
                if case .success(let record) = result,
                   let moment = MomentShareRecord(record: record) {
                    moments.append(moment)
                }
            }
            return moments
        } catch {
            throw CloudKitError.fetchFailed(error)
        }
    }

    // MARK: - Sharing

    func getOrCreateShare() async throws -> CKShare {
        // Ensure we have a live CKRecord — the couple may have been loaded from
        // cache with no in-memory CKRecord (e.g. after an app restart).
        if coupleRecord == nil {
            // 1. Try a zone query first (the normal path).
            _ = try? await fetchOwnedCouple()
        }
        if coupleRecord == nil, let cachedID = couple?.id {
            // 2. Fall back to a direct record fetch by the known UUID so a
            //    transient zone-query failure doesn't permanently lock the button.
            let recordID = CKRecord.ID(recordName: cachedID, zoneID: coupleZoneID)
            if let record = try? await privateDatabase.record(for: recordID) {
                self.coupleRecord = record
            }
        }
        guard let existingCoupleRecord = coupleRecord else { throw CloudKitError.coupleNotFound }

        // Check if share already exists and is valid
        if let existingShare = shareRecord, existingShare.url != nil {
            return existingShare
        }

        // Fetch a fresh copy of the couple record to avoid server-change conflicts
        let freshCoupleRecord: CKRecord
        do {
            freshCoupleRecord = try await privateDatabase.record(for: existingCoupleRecord.recordID)
            self.coupleRecord = freshCoupleRecord
        } catch {
            // If fetch fails, fall back to in-memory record
            freshCoupleRecord = existingCoupleRecord
        }

        // Try to re-use an existing share if it exists on the record
        if let shareReference = freshCoupleRecord.share {
            do {
                if let share = try await privateDatabase.record(for: shareReference.recordID) as? CKShare,
                   share.url != nil {
                    self.shareRecord = share
                    return share
                }
            } catch {
                // If fetching existing share fails, we'll recreate
            }
        }

        // Create a new share for the up-to-date couple record
        let share = CKShare(rootRecord: freshCoupleRecord)
        share[CKShare.SystemFieldKey.title] = "Pekis Couple" as CKRecordValue
        // Anyone with the invite link can join as a participant. Without this
        // (.none), CloudKit only authorizes participants added by Apple ID, so a
        // partner who taps the URL is rejected with "owner stopped sharing / no
        // permission." Read-write lets the partner sync moments back.
        share.publicPermission = .readWrite

        do {
            // Use changedKeys policy to avoid ETag conflicts when the record was just fetched
            let result = try await privateDatabase.modifyRecords(
                saving: [freshCoupleRecord, share],
                deleting: [],
                savePolicy: .changedKeys,
                atomically: true
            )

            var savedShare: CKShare?

            for (_, saveResult) in result.saveResults {
                switch saveResult {
                case .success(let record):
                    if let share = record as? CKShare {
                        savedShare = share
                        self.shareRecord = share
                    } else {
                        self.coupleRecord = record
                    }
                case .failure(let error):
                    throw CloudKitError.shareFailed(error)
                }
            }

            guard let finalShare = savedShare else {
                throw CloudKitError.shareFailed(
                    NSError(
                        domain: "CloudKitError",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Share creation failed - record not saved properly."]
                    )
                )
            }

            // Ensure the URL is present; if not, retry once after a short delay
            if finalShare.url == nil {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                if let refreshedShare = try await privateDatabase.record(for: finalShare.recordID) as? CKShare,
                   refreshedShare.url != nil {
                    self.shareRecord = refreshedShare
                    return refreshedShare
                }

                throw CloudKitError.shareFailed(
                    NSError(
                        domain: "CloudKitError",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Share URL is not available. This may be a CloudKit configuration issue."]
                    )
                )
            }

            return finalShare
        } catch {
            throw CloudKitError.shareFailed(error)
        }
    }

    // MARK: - Subscriptions

    func subscribeToChanges() async throws {
        // BUG 3 FIX: subscribe to BOTH databases.
        // Partner A receives changes in their private database (from Partner B's writes to the shared zone).
        // Partner B receives changes in the shared database (from Partner A's writes to their zone).
        await subscribeDatabase(privateDatabase, subscriptionID: "pekis-private-changes")
        await subscribeDatabase(sharedDatabase, subscriptionID: "pekis-shared-changes")
    }

    private func subscribeDatabase(_ database: CKDatabase, subscriptionID: String) async {
        // Check if subscription already exists
        if (try? await database.subscription(for: subscriptionID)) != nil { return }

        let subscription = CKDatabaseSubscription(subscriptionID: subscriptionID)
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true // Silent push — no visible banner
        subscription.notificationInfo = notificationInfo

        try? await database.save(subscription)
    }

    func handleNotification(userInfo: [AnyHashable: Any]) async {
        guard let dict = userInfo as? [String: NSObject],
              CKNotification(fromRemoteNotificationDictionary: dict) != nil else {
            return
        }
        await checkExistingCouple()
        NotificationCenter.default.post(name: .pekisCloudKitDataChanged, object: nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let pekisCloudKitDataChanged = Notification.Name("PekisCloudKitDataChanged")
}

// MARK: - Word Search Sessions

@MainActor
extension CloudKitService {
    func fetchWordSearchSession() async throws -> WordSearchSession? {
        guard let couple = couple else {
            throw CloudKitError.coupleNotFound
        }

        let zoneID = coupleRecord?.recordID.zoneID ?? coupleZoneID
        let database = zoneID.ownerName == CKCurrentUserDefaultName ? privateDatabase : sharedDatabase
        let recordID = CKRecord.ID(recordName: WordSearchSession.recordName(for: couple.id), zoneID: zoneID)

        do {
            let record = try await database.record(for: recordID)
            return WordSearchSession(record: record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        } catch {
            throw CloudKitError.fetchFailed(error)
        }
    }

    func saveWordSearchSession(_ session: WordSearchSession) async throws -> WordSearchSession {
        guard couple != nil else {
            throw CloudKitError.coupleNotFound
        }

        let zoneID = coupleRecord?.recordID.zoneID ?? coupleZoneID
        let database = zoneID.ownerName == CKCurrentUserDefaultName ? privateDatabase : sharedDatabase
        let record = session.toRecord(in: zoneID)

        do {
            let savedRecord = try await database.save(record)
            guard let savedSession = WordSearchSession(record: savedRecord) else {
                throw CloudKitError.saveFailed(
                    NSError(
                        domain: "CloudKitService",
                        code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "Saved Word Search session could not be decoded."]
                    )
                )
            }
            return savedSession
        } catch {
            throw CloudKitError.saveFailed(error)
        }
    }

    func deleteWordSearchSession() async throws {
        guard let couple = couple else {
            throw CloudKitError.coupleNotFound
        }

        let zoneID = coupleRecord?.recordID.zoneID ?? coupleZoneID
        let database = zoneID.ownerName == CKCurrentUserDefaultName ? privateDatabase : sharedDatabase
        let recordID = CKRecord.ID(recordName: WordSearchSession.recordName(for: couple.id), zoneID: zoneID)

        do {
            _ = try await database.deleteRecord(withID: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            return
        } catch {
            throw CloudKitError.saveFailed(error)
        }
    }
}

// MARK: - Private Helpers

@MainActor
private extension CloudKitService {
    func createZoneIfNeeded() async throws {
        let zone = CKRecordZone(zoneID: coupleZoneID)

        do {
            _ = try await privateDatabase.save(zone)
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Zone already exists, that's fine
        } catch let error as CKError where error.code == .zoneNotFound {
            _ = try await privateDatabase.save(zone)
        }
    }

    func saveUpdatedCouple(_ updatedCouple: Couple) async throws {
        // Re-fetch the server record when we don't have it in memory so we preserve
        // the changeTag and CKShare chaining. Without this, CloudKit rejects the save
        // with "SaveSemantics is failIfExists, existing record has chaining".
        if coupleRecord == nil {
            if (try? await fetchOwnedCouple()) == nil {
                _ = try? await fetchSharedCouple()
            }
        }

        let record: CKRecord
        if let existing = coupleRecord {
            record = existing
            updatedCouple.updateRecord(record)
        } else {
            record = updatedCouple.toRecord(in: coupleZoneID)
        }

        // Route to shared database when the record belongs to a partner's zone
        let ownerName = record.recordID.zoneID.ownerName
        let database = ownerName == CKCurrentUserDefaultName ? privateDatabase : sharedDatabase

        do {
            let savedRecord = try await database.save(record)
            self.coupleRecord = savedRecord

            if let couple = Couple(record: savedRecord) {
                self.couple = couple
                couple.saveToCache()
            }
        } catch {
            throw CloudKitError.saveFailed(error)
        }
    }

    func fetchOwnedCouple() async throws -> Couple? {
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

    func fetchSharedCouple() async throws -> Couple? {
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

    func handleError(_ error: Error) {
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

// MARK: - Disconnect

extension CloudKitService {
    func disconnectCouple() async throws {
        // Make sure we hold the live record so we can tell whether we own the zone.
        if coupleRecord == nil { _ = try? await fetchOwnedCouple() }
        if coupleRecord == nil { _ = try? await fetchSharedCouple() }

        if let record = coupleRecord {
            let zoneID = record.recordID.zoneID
            do {
                if zoneID.ownerName == CKCurrentUserDefaultName {
                    // Owner: deleting the zone erases the couple record, the
                    // share, and every shared record — for both partners.
                    _ = try await privateDatabase.deleteRecordZone(withID: coupleZoneID)
                } else {
                    // Participant: leaving the shared zone removes our access.
                    _ = try await sharedDatabase.deleteRecordZone(withID: zoneID)
                }
            } catch {
                // Still clear local state so the user is never stuck connected.
                PekisLogger.cloudKit.error("Disconnect cleanup failed: \(error.localizedDescription, privacy: .public)")
            }
        }

        resetAfterDisconnect()
    }

    private func resetAfterDisconnect() {
        coupleRecord = nil
        shareRecord = nil
        pendingShareMetadata = nil
        needsPartnerName = false
        errorMessage = nil
        couple = nil // didSet clears the widget snapshot
        Couple.clearCache()
        LoveNote.clearCache()
        ThisOrThatAnswer.clearCache()
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
    @Published var hasLoadedInitialState = true
    @Published var errorMessage: String?
    @Published var pendingShareMetadata: CKShare.Metadata?
    @Published var needsPartnerName: Bool = false

    private var wordSearchSession: WordSearchSession?

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
    func disconnectCouple() async throws { couple = nil }
    func sendLoveNote(content: String) async throws {}
    func fetchLoveNotes() async throws -> [LoveNote] { [] }
    func saveThisOrThatAnswer(questionIndex: Int, selectedOption: Int) async throws {}
    func fetchThisOrThatAnswers() async throws -> [ThisOrThatAnswer] { [] }
    func saveMoment(imageData: Data, prompt: String) async throws {}
    func fetchTodaysMoments() async throws -> [MomentShareRecord] { [] }
    func fetchWordSearchSession() async throws -> WordSearchSession? {
        wordSearchSession
    }
    func saveWordSearchSession(_ session: WordSearchSession) async throws -> WordSearchSession {
        wordSearchSession = session
        return session
    }
    func deleteWordSearchSession() async throws {
        wordSearchSession = nil
    }
    func getOrCreateShare() async throws -> CKShare {
        // Return a stub CKShare to avoid fatalError crashing previews
        throw CloudKitError.shareNotFound
    }
    func subscribeToChanges() async throws {}
    func handleNotification(userInfo: [AnyHashable: Any]) async {}
}
#endif
