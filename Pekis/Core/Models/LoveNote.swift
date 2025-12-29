import Foundation
import CloudKit

/// Represents a love note sent between partners
/// Stored in the shared CloudKit zone for couple sync
struct LoveNote: Codable, Identifiable, Equatable {
    let id: String
    let coupleID: String
    let authorID: String
    let content: String
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        coupleID: String,
        authorID: String,
        content: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.coupleID = coupleID
        self.authorID = authorID
        self.content = content
        self.createdAt = createdAt
    }
}

// MARK: - CloudKit Record Conversion

extension LoveNote {
    static let recordType = "LoveNote"

    enum RecordKey: String {
        case coupleID
        case authorID
        case content
        case createdAt
    }

    /// Initialize from a CloudKit record
    init?(record: CKRecord) {
        guard record.recordType == LoveNote.recordType else { return nil }

        self.id = record.recordID.recordName
        self.coupleID = record[RecordKey.coupleID.rawValue] as? String ?? ""
        self.authorID = record[RecordKey.authorID.rawValue] as? String ?? ""
        self.content = record[RecordKey.content.rawValue] as? String ?? ""
        self.createdAt = record[RecordKey.createdAt.rawValue] as? Date ?? Date()
    }

    /// Convert to a CloudKit record for saving
    func toRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: LoveNote.recordType, recordID: recordID)
        record[RecordKey.coupleID.rawValue] = coupleID
        record[RecordKey.authorID.rawValue] = authorID
        record[RecordKey.content.rawValue] = content
        record[RecordKey.createdAt.rawValue] = createdAt
        return record
    }
}

// MARK: - Cache Support

extension LoveNote {
    static let cacheKey = "cached_love_notes"

    /// Save array to UserDefaults for offline access
    static func saveToCache(_ notes: [LoveNote]) {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: LoveNote.cacheKey)
        }
    }

    /// Load array from UserDefaults cache
    static func loadFromCache() -> [LoveNote] {
        guard let data = UserDefaults.standard.data(forKey: LoveNote.cacheKey),
              let notes = try? JSONDecoder().decode([LoveNote].self, from: data) else {
            return []
        }
        return notes
    }

    /// Clear cached notes
    static func clearCache() {
        UserDefaults.standard.removeObject(forKey: LoveNote.cacheKey)
    }
}

// MARK: - Helpers

extension LoveNote {
    /// Check if this note was authored by the current user
    func isFromCurrentUser(currentUserID: String) -> Bool {
        return authorID == currentUserID
    }

    /// Formatted date string for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}
