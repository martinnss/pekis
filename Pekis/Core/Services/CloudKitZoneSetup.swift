import CloudKit
import Foundation

enum CloudKitZoneSetup {
    static func createZoneIfNeeded(in database: CKDatabase, zoneID: CKRecordZone.ID) async throws {
        let zone = CKRecordZone(zoneID: zoneID)

        do {
            _ = try await database.save(zone)
            return
        } catch let error as CKError where error.code == .serverRecordChanged {
            return
        } catch let error as CKError where error.code == .zoneNotFound {
            do {
                _ = try await database.save(zone)
                return
            } catch let retryError as CKError where retryError.code == .serverRecordChanged {
                return
            } catch {
                if try await zoneExists(in: database, zoneID: zoneID) { return }
                throw CloudKitError.zoneCreationFailed(error)
            }
        } catch {
            if try await zoneExists(in: database, zoneID: zoneID) { return }
            throw CloudKitError.zoneCreationFailed(error)
        }
    }

    static func zoneExists(in database: CKDatabase, zoneID: CKRecordZone.ID) async throws -> Bool {
        let zones = try await database.allRecordZones()
        return zones.contains { $0.zoneID == zoneID }
    }
}
