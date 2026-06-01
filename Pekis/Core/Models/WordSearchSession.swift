import Foundation
import CloudKit

enum WordSearchSessionStatus: String, Codable {
    case waiting
    case ready
    case finished
    case cancelled
}

struct WordSearchSession: Codable, Identifiable {
    static let recordType = "WordSearchSession"

    let id: String
    let coupleID: String
    let partnerAIdentifier: String
    let partnerBIdentifier: String
    let seed: UInt64
    var partnerAReadyAt: Date?
    var partnerBReadyAt: Date?
    var scheduledStartAt: Date?
    var partnerAScore: Int?
    var partnerBScore: Int?
    var winnerID: String?
    var status: WordSearchSessionStatus
    let createdAt: Date
    var updatedAt: Date
    var expiresAt: Date

    init(couple: Couple, partnerBIdentifier: String, seed: UInt64, now: Date = Date(), lifetime: TimeInterval = 900) {
        self.id = Self.recordName(for: couple.id)
        self.coupleID = couple.id
        self.partnerAIdentifier = couple.partnerAIdentifier
        self.partnerBIdentifier = partnerBIdentifier
        self.seed = seed
        self.status = .waiting
        self.createdAt = now
        self.updatedAt = now
        self.expiresAt = now.addingTimeInterval(lifetime)
    }

    static func recordName(for coupleID: String) -> String {
        "word-search-session-\(coupleID)"
    }

    var bothPlayersReady: Bool {
        partnerAReadyAt != nil && partnerBReadyAt != nil
    }

    var hasAnyReadyPlayer: Bool {
        partnerAReadyAt != nil || partnerBReadyAt != nil
    }

    func containsParticipant(_ userID: String) -> Bool {
        userID == partnerAIdentifier || userID == partnerBIdentifier
    }

    func readyAt(for userID: String) -> Date? {
        switch userID {
        case partnerAIdentifier:
            return partnerAReadyAt
        case partnerBIdentifier:
            return partnerBReadyAt
        default:
            return nil
        }
    }

    func otherPlayerID(for userID: String) -> String? {
        switch userID {
        case partnerAIdentifier:
            return partnerBIdentifier
        case partnerBIdentifier:
            return partnerAIdentifier
        default:
            return nil
        }
    }

    func isExpired(at date: Date) -> Bool {
        expiresAt <= date
    }

    mutating func markReady(for userID: String, at date: Date) {
        switch userID {
        case partnerAIdentifier:
            partnerAReadyAt = date
        case partnerBIdentifier:
            partnerBReadyAt = date
        default:
            break
        }
    }

    mutating func clearReady(for userID: String) {
        switch userID {
        case partnerAIdentifier:
            partnerAReadyAt = nil
            partnerAScore = nil
        case partnerBIdentifier:
            partnerBReadyAt = nil
            partnerBScore = nil
        default:
            break
        }
    }

    mutating func setScore(_ score: Int, for userID: String) {
        switch userID {
        case partnerAIdentifier:
            partnerAScore = score
        case partnerBIdentifier:
            partnerBScore = score
        default:
            break
        }
    }

    mutating func scheduleCountdown(from now: Date, countdown: TimeInterval, lifetime: TimeInterval = 900) {
        scheduledStartAt = now.addingTimeInterval(countdown)
        status = .ready
        refreshExpiration(from: now, lifetime: lifetime)
    }

    mutating func refreshExpiration(from now: Date, lifetime: TimeInterval = 900) {
        updatedAt = now
        expiresAt = now.addingTimeInterval(lifetime)
    }
}

// MARK: - CloudKit Record Conversion

extension WordSearchSession {
    enum RecordKey: String {
        case coupleID
        case partnerAIdentifier
        case partnerBIdentifier
        case seed
        case partnerAReadyAt
        case partnerBReadyAt
        case scheduledStartAt
        case partnerAScore
        case partnerBScore
        case winnerID
        case status
        case createdAt
        case updatedAt
        case expiresAt
    }

    init?(record: CKRecord) {
        guard record.recordType == Self.recordType,
              let coupleID = record[RecordKey.coupleID.rawValue] as? String,
              let partnerAIdentifier = record[RecordKey.partnerAIdentifier.rawValue] as? String,
              let partnerBIdentifier = record[RecordKey.partnerBIdentifier.rawValue] as? String,
              let seedNumber = record[RecordKey.seed.rawValue] as? NSNumber,
              let statusRawValue = record[RecordKey.status.rawValue] as? String,
              let status = WordSearchSessionStatus(rawValue: statusRawValue)
        else {
            return nil
        }

        self.id = record.recordID.recordName
        self.coupleID = coupleID
        self.partnerAIdentifier = partnerAIdentifier
        self.partnerBIdentifier = partnerBIdentifier
        self.seed = seedNumber.uint64Value
        self.partnerAReadyAt = record[RecordKey.partnerAReadyAt.rawValue] as? Date
        self.partnerBReadyAt = record[RecordKey.partnerBReadyAt.rawValue] as? Date
        self.scheduledStartAt = record[RecordKey.scheduledStartAt.rawValue] as? Date
        self.partnerAScore = (record[RecordKey.partnerAScore.rawValue] as? NSNumber)?.intValue
        self.partnerBScore = (record[RecordKey.partnerBScore.rawValue] as? NSNumber)?.intValue
        self.winnerID = record[RecordKey.winnerID.rawValue] as? String
        self.status = status
        self.createdAt = record[RecordKey.createdAt.rawValue] as? Date ?? Date()
        self.updatedAt = record[RecordKey.updatedAt.rawValue] as? Date ?? createdAt
        self.expiresAt = record[RecordKey.expiresAt.rawValue] as? Date ?? updatedAt
    }

    func toRecord(in zoneID: CKRecordZone.ID? = nil) -> CKRecord {
        let recordID: CKRecord.ID
        if let zoneID {
            recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        } else {
            recordID = CKRecord.ID(recordName: id)
        }

        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record[RecordKey.coupleID.rawValue] = coupleID
        record[RecordKey.partnerAIdentifier.rawValue] = partnerAIdentifier
        record[RecordKey.partnerBIdentifier.rawValue] = partnerBIdentifier
        record[RecordKey.seed.rawValue] = NSNumber(value: seed)
        record[RecordKey.partnerAReadyAt.rawValue] = partnerAReadyAt
        record[RecordKey.partnerBReadyAt.rawValue] = partnerBReadyAt
        record[RecordKey.scheduledStartAt.rawValue] = scheduledStartAt
        record[RecordKey.partnerAScore.rawValue] = partnerAScore.map(NSNumber.init(value:))
        record[RecordKey.partnerBScore.rawValue] = partnerBScore.map(NSNumber.init(value:))
        record[RecordKey.winnerID.rawValue] = winnerID
        record[RecordKey.status.rawValue] = status.rawValue
        record[RecordKey.createdAt.rawValue] = createdAt
        record[RecordKey.updatedAt.rawValue] = updatedAt
        record[RecordKey.expiresAt.rawValue] = expiresAt
        return record
    }
}