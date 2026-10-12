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
    @Published var isLoading = false
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

    // MARK: - Internal State
    // Internal (not private) so the feature extensions in `CloudKitService+*.swift` can share it.

    // Lazy to defer CKContainer creation until first use — prevents crash in test
    // environments where entitlements are absent (CODE_SIGNING_ALLOWED=NO).
    lazy var container: CKContainer = CKContainer(identifier: containerIdentifier)
    lazy var privateDatabase: CKDatabase = container.privateCloudDatabase
    var sharedDatabase: CKDatabase { container.sharedCloudDatabase }

    let containerIdentifier: String
    let coupleZoneName = "CoupleZone"
    var coupleZoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: coupleZoneName, ownerName: CKCurrentUserDefaultName)
    }

    var coupleRecord: CKRecord?
    var shareRecord: CKShare?

    // MARK: - Initialization

    init(containerIdentifier: String? = nil) {
        self.containerIdentifier = containerIdentifier ?? AppConfiguration.cloudKitContainerIdentifier
    }

    // MARK: - Setup

    /// Lets the UI proceed without contacting CloudKit (unsigned simulator previews and tests).
    func skipInitialLoad() {
        hasLoadedInitialState = true
    }

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
            if !CloudKitError.isQueryabilityError(error) {
                handleError(error)
            } else {
                PekisLogger.cloudKit.warning(
                    "checkExistingCouple: queryability error, using cache: \(error.localizedDescription, privacy: .public)"
                )
            }
        }
    }

    // MARK: - Couple Management

    func createCouple(name: String) async throws -> Couple {
        guard let userID = currentUserID else {
            throw CloudKitError.notAuthenticated
        }

        isLoading = true
        defer { isLoading = false }

        try await createZoneIfNeeded()

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
            if CloudKitError.isZoneMissingError(error) {
                try await createZoneIfNeeded()
                let savedRecord = try await privateDatabase.save(record)
                self.coupleRecord = savedRecord
                if let couple = Couple(record: savedRecord) {
                    self.couple = couple
                    couple.saveToCache()
                    return couple
                }
            }
            throw CloudKitError.saveFailed(error)
        }
    }

    func acceptShare(_ metadata: CKShare.Metadata) async throws {
        PekisLogger.cloudKit.debug("acceptShare: start, currentUserID=\(self.currentUserID ?? "nil", privacy: .public)")
        isLoading = true
        defer { isLoading = false }

        try await waitForCurrentUserID()

        PekisLogger.cloudKit.debug("acceptShare: calling container.accept()")
        do {
            _ = try await container.accept(metadata)
            PekisLogger.cloudKit.debug("acceptShare: container.accept() succeeded")
        } catch {
            PekisLogger.cloudKit.error("acceptShare: container.accept() failed: \(error.localizedDescription, privacy: .public)")
            throw CloudKitError.shareFailed(error)
        }

        guard var couple = await fetchSharedCoupleAfterAccept() else {
            PekisLogger.cloudKit.error("acceptShare: could not fetch shared couple after 3 attempts")
            throw CloudKitError.shareNotFound
        }

        if let userID = currentUserID, couple.partnerBIdentifier == nil {
            PekisLogger.cloudKit.debug("acceptShare: setting partnerBIdentifier and saving couple")
            couple.partnerBIdentifier = userID
            do {
                try await saveUpdatedCouple(couple)
            } catch {
                PekisLogger.cloudKit.error("acceptShare: saveUpdatedCouple failed: \(error.localizedDescription, privacy: .public)")
                errorMessage = "Joined successfully, but couldn't save your profile. Please try again."
                needsPartnerName = true
                return
            }
        } else {
            self.couple = couple
            couple.saveToCache()
        }
        needsPartnerName = couple.partnerBName == nil || couple.partnerBName?.isEmpty == true
        PekisLogger.cloudKit.debug("acceptShare: done, needsPartnerName=\(self.needsPartnerName, privacy: .public)")
    }

    /// Waits for `currentUserID` if the app launched cold from a share URL (this races with `setup()`).
    private func waitForCurrentUserID() async throws {
        guard currentUserID == nil else { return }
        PekisLogger.cloudKit.debug("acceptShare: currentUserID nil, waiting up to 5s for setup()")
        for _ in 0..<5 {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            if currentUserID != nil { return }
        }
        PekisLogger.cloudKit.error("acceptShare: timed out waiting for currentUserID — user may not be signed into iCloud")
        throw CloudKitError.notAuthenticated
    }

    /// Fetches the shared couple, retrying because CloudKit has a propagation delay after `accept()`.
    private func fetchSharedCoupleAfterAccept() async -> Couple? {
        let maxAttempts = 3
        PekisLogger.cloudKit.debug("acceptShare: fetching shared couple (up to \(maxAttempts, privacy: .public) attempts)")
        for attempt in 1...maxAttempts {
            if let found = try? await fetchSharedCouple() {
                PekisLogger.cloudKit.debug("acceptShare: found shared couple on attempt \(attempt, privacy: .public)")
                return found
            }
            PekisLogger.cloudKit.debug("acceptShare: attempt \(attempt, privacy: .public) found nothing")
            if attempt < maxAttempts {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
        return nil
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
}

// MARK: - Private Helpers

@MainActor
extension CloudKitService {
    func createZoneIfNeeded() async throws {
        try await CloudKitZoneSetup.createZoneIfNeeded(in: privateDatabase, zoneID: coupleZoneID)
    }

    var coupleDiscoveryConfiguration: CloudKitCoupleDiscovery.Configuration {
        CloudKitCoupleDiscovery.Configuration(
            privateDatabase: privateDatabase,
            sharedDatabase: sharedDatabase,
            coupleZoneID: coupleZoneID,
            currentUserID: currentUserID,
            cachedCoupleID: Couple.loadFromCache()?.id,
            inMemoryCoupleID: couple?.id
        )
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
            try await createZoneIfNeeded()
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
        guard let result = try await CloudKitCoupleDiscovery.fetchOwnedCouple(using: coupleDiscoveryConfiguration) else {
            return nil
        }
        self.coupleRecord = result.record
        return result.couple
    }

    func fetchSharedCouple() async throws -> Couple? {
        guard let result = try await CloudKitCoupleDiscovery.fetchSharedCouple(using: coupleDiscoveryConfiguration) else {
            return nil
        }
        self.coupleRecord = result.record
        return result.couple
    }

    func handleError(_ error: Error) {
        if CloudKitError.isQueryabilityError(error) {
            PekisLogger.cloudKit.warning(
                "handleError: suppressing queryability alert: \(error.localizedDescription, privacy: .public)"
            )
            return
        }

        if let cloudKitError = error as? CloudKitError {
            errorMessage = cloudKitError.errorDescription
            return
        }

        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated:
                errorMessage = CloudKitError.notAuthenticated.errorDescription
            case .networkUnavailable, .networkFailure:
                errorMessage = "Network unavailable. Data will sync when connection is restored."
            case .quotaExceeded:
                errorMessage = "iCloud storage is full. Please free up space."
            case .zoneNotFound:
                errorMessage = CloudKitError.zoneCreationFailed(ckError).errorDescription
            default:
                errorMessage = CloudKitError.unknown(ckError).errorDescription
            }
        } else {
            errorMessage = CloudKitError.unknown(error).errorDescription
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
