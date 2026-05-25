import Foundation
import CloudKit
import UIKit

/// Represents a daily shared photo moment between partners.
/// Stored in the couple's shared CloudKit zone — both partners can read and write.
struct MomentShareRecord: Identifiable {
    let id: String
    let coupleID: String
    let authorID: String
    let prompt: String
    let createdAt: Date
    var imageData: Data?

    init(
        id: String = UUID().uuidString,
        coupleID: String,
        authorID: String,
        prompt: String,
        createdAt: Date = Date(),
        imageData: Data? = nil
    ) {
        self.id = id
        self.coupleID = coupleID
        self.authorID = authorID
        self.prompt = prompt
        self.createdAt = createdAt
        self.imageData = imageData
    }

    var isFromToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }

    var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
}

// MARK: - CloudKit Record Conversion

extension MomentShareRecord {
    static let recordType = "MomentShare"

    enum RecordKey: String {
        case coupleID
        case authorID
        case prompt
        case createdAt
        case photo
    }

    /// Initialize from a CloudKit record, reading CKAsset data from disk.
    init?(record: CKRecord) {
        guard record.recordType == MomentShareRecord.recordType else { return nil }

        self.id = record.recordID.recordName
        self.coupleID = record[RecordKey.coupleID.rawValue] as? String ?? ""
        self.authorID = record[RecordKey.authorID.rawValue] as? String ?? ""
        self.prompt = record[RecordKey.prompt.rawValue] as? String ?? ""
        self.createdAt = record[RecordKey.createdAt.rawValue] as? Date ?? Date()

        // CKAsset is downloaded to a local temp file — read it immediately.
        if let asset = record[RecordKey.photo.rawValue] as? CKAsset,
           let fileURL = asset.fileURL,
           let data = try? Data(contentsOf: fileURL) {
            self.imageData = data
        }
    }

    /// Build a CKRecord for this moment. The caller is responsible for
    /// attaching the CKAsset (photo field) after this returns.
    func toRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: MomentShareRecord.recordType, recordID: recordID)
        record[RecordKey.coupleID.rawValue] = coupleID
        record[RecordKey.authorID.rawValue] = authorID
        record[RecordKey.prompt.rawValue] = prompt
        record[RecordKey.createdAt.rawValue] = createdAt
        return record
    }
}
