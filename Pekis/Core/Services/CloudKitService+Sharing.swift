import Foundation
import CloudKit
import Combine
import OSLog

// CKShare creation, change subscriptions, and push handling.
@MainActor
extension CloudKitService {
    func getOrCreateShare() async throws -> CKShare {
        let existingCoupleRecord = try await loadCoupleRecord()

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

        if let reusableShare = await fetchExistingShare(for: freshCoupleRecord) {
            self.shareRecord = reusableShare
            return reusableShare
        }

        do {
            return try await createShare(for: freshCoupleRecord)
        } catch {
            throw CloudKitError.shareFailed(error)
        }
    }

    /// Ensures a live `CKRecord` for the couple exists. It may have been loaded from cache
    /// with no in-memory record (for example after an app restart).
    private func loadCoupleRecord() async throws -> CKRecord {
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
        guard let record = coupleRecord else { throw CloudKitError.coupleNotFound }
        return record
    }

    /// Returns the share already attached to the record, if it exists and has a URL.
    private func fetchExistingShare(for record: CKRecord) async -> CKShare? {
        guard let shareReference = record.share else { return nil }
        // If fetching the existing share fails we simply recreate it.
        guard let share = try? await privateDatabase.record(for: shareReference.recordID) as? CKShare else { return nil }
        return share.url != nil ? share : nil
    }

    private func createShare(for record: CKRecord) async throws -> CKShare {
        let share = CKShare(rootRecord: record)
        share[CKShare.SystemFieldKey.title] = "Pekis Couple" as CKRecordValue
        // Anyone with the invite link can join as a participant. Without this
        // (.none), CloudKit only authorizes participants added by Apple ID, so a
        // partner who taps the URL is rejected with "owner stopped sharing / no
        // permission." Read-write lets the partner sync moments back.
        share.publicPermission = .readWrite

        // Use changedKeys policy to avoid ETag conflicts when the record was just fetched
        let result = try await privateDatabase.modifyRecords(
            saving: [record, share],
            deleting: [],
            savePolicy: .changedKeys,
            atomically: true
        )

        var savedShare: CKShare?
        for (_, saveResult) in result.saveResults {
            switch saveResult {
            case .success(let savedRecord):
                if let savedRecordShare = savedRecord as? CKShare {
                    savedShare = savedRecordShare
                    self.shareRecord = savedRecordShare
                } else {
                    self.coupleRecord = savedRecord
                }
            case .failure(let error):
                throw CloudKitError.shareFailed(error)
            }
        }

        guard let finalShare = savedShare else {
            throw Self.shareError(code: -2, message: "Share creation failed - record not saved properly.")
        }
        guard finalShare.url == nil else { return finalShare }

        // The URL can lag behind the save; retry once after a short delay.
        try await Task.sleep(nanoseconds: 1_000_000_000)
        if let refreshedShare = try await privateDatabase.record(for: finalShare.recordID) as? CKShare,
           refreshedShare.url != nil {
            self.shareRecord = refreshedShare
            return refreshedShare
        }
        throw Self.shareError(
            code: -1,
            message: "Share URL is not available. This may be a CloudKit configuration issue."
        )
    }

    private static func shareError(code: Int, message: String) -> CloudKitError {
        CloudKitError.shareFailed(
            NSError(domain: "CloudKitError", code: code, userInfo: [NSLocalizedDescriptionKey: message])
        )
    }

    func subscribeToChanges() async throws {
        // Subscribe to BOTH databases.
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
        notificationInfo.shouldSendContentAvailable = true // Silent push, no visible banner
        subscription.notificationInfo = notificationInfo

        _ = try? await database.save(subscription)
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

extension Notification.Name {
    static let pekisCloudKitDataChanged = Notification.Name("PekisCloudKitDataChanged")
}
