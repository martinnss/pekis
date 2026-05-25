import Foundation
import CloudKit

/// Represents a couple relationship in CloudKit
/// Stored in the private database and shared via CKShare for partner sync
struct Couple: Codable, Identifiable {
    let id: String
    let partnerAIdentifier: String
    var partnerBIdentifier: String?
    var partnerAName: String
    var partnerBName: String?
    var reunionDate: Date?
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        partnerAIdentifier: String,
        partnerBIdentifier: String? = nil,
        partnerAName: String,
        partnerBName: String? = nil,
        reunionDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.partnerAIdentifier = partnerAIdentifier
        self.partnerBIdentifier = partnerBIdentifier
        self.partnerAName = partnerAName
        self.partnerBName = partnerBName
        self.reunionDate = reunionDate
        self.createdAt = createdAt
    }
}

// MARK: - CloudKit Record Conversion

extension Couple {
    static let recordType = "Couple"

    enum RecordKey: String {
        case partnerAIdentifier
        case partnerBIdentifier
        case partnerAName
        case partnerBName
        case reunionDate
        case createdAt
    }

    /// Initialize from a CloudKit record
    init?(record: CKRecord) {
        guard record.recordType == Couple.recordType else { return nil }

        self.id = record.recordID.recordName
        self.partnerAIdentifier = record[RecordKey.partnerAIdentifier.rawValue] as? String ?? ""
        self.partnerBIdentifier = record[RecordKey.partnerBIdentifier.rawValue] as? String
        self.partnerAName = record[RecordKey.partnerAName.rawValue] as? String ?? ""
        self.partnerBName = record[RecordKey.partnerBName.rawValue] as? String
        self.reunionDate = record[RecordKey.reunionDate.rawValue] as? Date
        self.createdAt = record[RecordKey.createdAt.rawValue] as? Date ?? Date()
    }

    /// Convert to a CloudKit record for saving
    func toRecord(in zoneID: CKRecordZone.ID? = nil) -> CKRecord {
        let recordID: CKRecord.ID
        if let zoneID = zoneID {
            recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        } else {
            recordID = CKRecord.ID(recordName: id)
        }

        let record = CKRecord(recordType: Couple.recordType, recordID: recordID)
        record[RecordKey.partnerAIdentifier.rawValue] = partnerAIdentifier
        record[RecordKey.partnerBIdentifier.rawValue] = partnerBIdentifier
        record[RecordKey.partnerAName.rawValue] = partnerAName
        record[RecordKey.partnerBName.rawValue] = partnerBName
        record[RecordKey.reunionDate.rawValue] = reunionDate
        record[RecordKey.createdAt.rawValue] = createdAt
        return record
    }

    /// Update an existing CloudKit record with current values
    func updateRecord(_ record: CKRecord) {
        record[RecordKey.partnerAIdentifier.rawValue] = partnerAIdentifier
        record[RecordKey.partnerBIdentifier.rawValue] = partnerBIdentifier
        record[RecordKey.partnerAName.rawValue] = partnerAName
        record[RecordKey.partnerBName.rawValue] = partnerBName
        record[RecordKey.reunionDate.rawValue] = reunionDate
        record[RecordKey.createdAt.rawValue] = createdAt
    }
}

// MARK: - Cache Support

extension Couple {
    static let cacheKey = "cached_couple"

    /// Save to UserDefaults for offline access
    func saveToCache() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Couple.cacheKey)
        }
    }

    /// Load from UserDefaults cache
    static func loadFromCache() -> Couple? {
        guard let data = UserDefaults.standard.data(forKey: Couple.cacheKey),
              let couple = try? JSONDecoder().decode(Couple.self, from: data) else {
            return nil
        }
        return couple
    }

    /// Clear cached couple data
    static func clearCache() {
        UserDefaults.standard.removeObject(forKey: Couple.cacheKey)
    }
}
