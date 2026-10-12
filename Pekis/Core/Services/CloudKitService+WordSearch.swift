import Foundation
import CloudKit
import Combine
import OSLog

// Short-lived Word Search session record used for shared-play coordination.
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
