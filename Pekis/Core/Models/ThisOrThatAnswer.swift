import Foundation
import CloudKit

/// Represents a user's answer to a This or That question
/// Both partners' answers are stored and compared after both answer
struct ThisOrThatAnswer: Codable, Identifiable, Equatable {
    let id: String
    let coupleID: String
    let authorID: String
    let questionIndex: Int
    let selectedOption: Int // 0 or 1
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        coupleID: String,
        authorID: String,
        questionIndex: Int,
        selectedOption: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.coupleID = coupleID
        self.authorID = authorID
        self.questionIndex = questionIndex
        self.selectedOption = selectedOption
        self.createdAt = createdAt
    }
}

// MARK: - CloudKit Record Conversion

extension ThisOrThatAnswer {
    static let recordType = "ThisOrThatAnswer"

    enum RecordKey: String {
        case coupleID
        case authorID
        case questionIndex
        case selectedOption
        case createdAt
    }

    /// Initialize from a CloudKit record
    init?(record: CKRecord) {
        guard record.recordType == ThisOrThatAnswer.recordType else { return nil }

        self.id = record.recordID.recordName
        self.coupleID = record[RecordKey.coupleID.rawValue] as? String ?? ""
        self.authorID = record[RecordKey.authorID.rawValue] as? String ?? ""
        self.questionIndex = record[RecordKey.questionIndex.rawValue] as? Int ?? 0
        self.selectedOption = record[RecordKey.selectedOption.rawValue] as? Int ?? 0
        self.createdAt = record[RecordKey.createdAt.rawValue] as? Date ?? Date()
    }

    /// Convert to a CloudKit record for saving
    func toRecord(in zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let record = CKRecord(recordType: ThisOrThatAnswer.recordType, recordID: recordID)
        record[RecordKey.coupleID.rawValue] = coupleID
        record[RecordKey.authorID.rawValue] = authorID
        record[RecordKey.questionIndex.rawValue] = questionIndex
        record[RecordKey.selectedOption.rawValue] = selectedOption
        record[RecordKey.createdAt.rawValue] = createdAt
        return record
    }
}

// MARK: - Cache Support

extension ThisOrThatAnswer {
    static let cacheKey = "cached_this_or_that_answers"

    /// Save array to UserDefaults for offline access
    static func saveToCache(_ answers: [ThisOrThatAnswer]) {
        if let data = try? JSONEncoder().encode(answers) {
            UserDefaults.standard.set(data, forKey: ThisOrThatAnswer.cacheKey)
        }
    }

    /// Load array from UserDefaults cache
    static func loadFromCache() -> [ThisOrThatAnswer] {
        guard let data = UserDefaults.standard.data(forKey: ThisOrThatAnswer.cacheKey),
              let answers = try? JSONDecoder().decode([ThisOrThatAnswer].self, from: data) else {
            return []
        }
        return answers
    }

    /// Clear cached answers
    static func clearCache() {
        UserDefaults.standard.removeObject(forKey: ThisOrThatAnswer.cacheKey)
    }
}

// MARK: - Helpers

extension ThisOrThatAnswer {
    /// Check if this answer was authored by the current user
    func isFromCurrentUser(currentUserID: String) -> Bool {
        return authorID == currentUserID
    }
}

// MARK: - Answer Comparison

/// Represents paired answers from both partners for a question
struct ThisOrThatComparison: Identifiable {
    let id: Int // questionIndex
    let questionIndex: Int
    let myAnswer: Int?
    let partnerAnswer: Int?

    var bothAnswered: Bool {
        return myAnswer != nil && partnerAnswer != nil
    }

    var isMatch: Bool {
        guard let my = myAnswer, let partner = partnerAnswer else { return false }
        return my == partner
    }
}

extension Array where Element == ThisOrThatAnswer {
    /// Group answers by question and create comparisons
    func createComparisons(currentUserID: String, questionCount: Int) -> [ThisOrThatComparison] {
        var comparisons: [ThisOrThatComparison] = []

        for index in 0..<questionCount {
            let answersForQuestion = self.filter { $0.questionIndex == index }
            let myAnswer = answersForQuestion.first { $0.authorID == currentUserID }?.selectedOption
            let partnerAnswer = answersForQuestion.first { $0.authorID != currentUserID }?.selectedOption

            comparisons.append(ThisOrThatComparison(
                id: index,
                questionIndex: index,
                myAnswer: myAnswer,
                partnerAnswer: partnerAnswer
            ))
        }

        return comparisons
    }
}
