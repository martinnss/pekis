import CloudKit
import Foundation
import OSLog

@MainActor
enum CloudKitCoupleDiscovery {
    struct Configuration {
        let privateDatabase: CKDatabase
        let sharedDatabase: CKDatabase
        let coupleZoneID: CKRecordZone.ID
        let currentUserID: String?
        let cachedCoupleID: String?
        let inMemoryCoupleID: String?
    }

    struct FetchResult {
        let couple: Couple
        let record: CKRecord
    }

    static func fetchOwnedCouple(using configuration: Configuration) async throws -> FetchResult? {
        do {
            let predicate = ownedCouplePredicate(currentUserID: configuration.currentUserID)
            let query = CKQuery(recordType: Couple.recordType, predicate: predicate)

            let results = try await configuration.privateDatabase.records(
                matching: query,
                inZoneWith: configuration.coupleZoneID
            )

            for (_, result) in results.matchResults {
                if case .success(let record) = result, let couple = Couple(record: record) {
                    return FetchResult(couple: couple, record: record)
                }
            }

            return try await fetchCoupleByCachedID(
                in: configuration.privateDatabase,
                zoneID: configuration.coupleZoneID,
                configuration: configuration
            )
        } catch {
            if CloudKitError.isQueryabilityError(error) {
                PekisLogger.cloudKit.warning(
                    "fetchOwnedCouple: queryability error, falling back to direct fetch: \(error.localizedDescription, privacy: .public)"
                )
                return try await fetchCoupleByCachedID(
                    in: configuration.privateDatabase,
                    zoneID: configuration.coupleZoneID,
                    configuration: configuration
                )
            }
            throw error
        }
    }

    static func fetchSharedCouple(using configuration: Configuration) async throws -> FetchResult? {
        let zones: [CKRecordZone]
        do {
            zones = try await configuration.sharedDatabase.allRecordZones()
        } catch {
            if CloudKitError.isQueryabilityError(error) {
                PekisLogger.cloudKit.warning(
                    "fetchSharedCouple: queryability error listing zones, falling back to direct fetch: \(error.localizedDescription, privacy: .public)"
                )
                return try await fetchSharedCoupleByCachedID(using: configuration)
            }
            throw error
        }

        for zone in zones {
            do {
                let predicate = NSPredicate(
                    format: "%K != %@",
                    Couple.RecordKey.partnerAIdentifier.rawValue,
                    ""
                )
                let query = CKQuery(recordType: Couple.recordType, predicate: predicate)

                let results = try await configuration.sharedDatabase.records(
                    matching: query,
                    inZoneWith: zone.zoneID
                )

                for (_, result) in results.matchResults {
                    if case .success(let record) = result, let couple = Couple(record: record) {
                        return FetchResult(couple: couple, record: record)
                    }
                }
            } catch {
                if CloudKitError.isQueryabilityError(error) {
                    PekisLogger.cloudKit.warning(
                        "fetchSharedCouple: queryability error in zone \(zone.zoneID.zoneName, privacy: .public), trying direct fetch"
                    )
                    if let result = try await fetchCoupleByCachedID(
                        in: configuration.sharedDatabase,
                        zoneID: zone.zoneID,
                        configuration: configuration
                    ) {
                        return result
                    }
                    continue
                }
                throw error
            }
        }

        return try await fetchSharedCoupleByCachedID(using: configuration)
    }

    private static func ownedCouplePredicate(currentUserID: String?) -> NSPredicate {
        if let currentUserID {
            return NSPredicate(
                format: "%K == %@",
                Couple.RecordKey.partnerAIdentifier.rawValue,
                currentUserID
            )
        }

        return NSPredicate(
            format: "%K != %@",
            Couple.RecordKey.partnerAIdentifier.rawValue,
            ""
        )
    }

    private static func fetchSharedCoupleByCachedID(using configuration: Configuration) async throws -> FetchResult? {
        guard let cachedID = configuration.cachedCoupleID ?? configuration.inMemoryCoupleID else { return nil }

        let zones = (try? await configuration.sharedDatabase.allRecordZones()) ?? []
        for zone in zones {
            if let result = try await fetchCoupleByCachedID(
                in: configuration.sharedDatabase,
                zoneID: zone.zoneID,
                configuration: configuration,
                recordName: cachedID
            ) {
                return result
            }
        }

        return nil
    }

    private static func fetchCoupleByCachedID(
        in database: CKDatabase,
        zoneID: CKRecordZone.ID,
        configuration: Configuration,
        recordName: String? = nil
    ) async throws -> FetchResult? {
        let cachedRecordName = recordName ?? configuration.cachedCoupleID ?? configuration.inMemoryCoupleID
        guard let cachedRecordName else { return nil }

        let recordID = CKRecord.ID(recordName: cachedRecordName, zoneID: zoneID)
        do {
            let record = try await database.record(for: recordID)
            guard let couple = Couple(record: record) else { return nil }
            return FetchResult(couple: couple, record: record)
        } catch let error as CKError where error.code == .unknownItem {
            return nil
        }
    }
}
