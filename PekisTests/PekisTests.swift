import CloudKit
import Foundation
import Testing
@testable import Pekis

// MARK: - Couple Model

@MainActor
struct CoupleModelTests {
    @Test func cloudKitRecordRoundTrip() throws {
        let createdAt = Date(timeIntervalSince1970: 1_600_000_000)
        let reunionDate = Date(timeIntervalSince1970: 1_700_000_000)
        let original = Couple(
            id: "couple-abc",
            partnerAIdentifier: "user-a",
            partnerBIdentifier: "user-b",
            partnerAName: "Alice",
            partnerBName: "Bob",
            reunionDate: reunionDate,
            createdAt: createdAt
        )

        let zoneID = CKRecordZone.ID(zoneName: "TestZone", ownerName: "__defaultOwner__")
        let record = original.toRecord(in: zoneID)

        #expect(record.recordType == "Couple")
        #expect(record.recordID.recordName == "couple-abc")

        let restored = try #require(Couple(record: record))
        #expect(restored.id == original.id)
        #expect(restored.partnerAIdentifier == original.partnerAIdentifier)
        #expect(restored.partnerBIdentifier == original.partnerBIdentifier)
        #expect(restored.partnerAName == original.partnerAName)
        #expect(restored.partnerBName == original.partnerBName)
        #expect(restored.reunionDate == original.reunionDate)
    }

    @Test func cacheRoundTrip() {
        let couple = Couple(
            partnerAIdentifier: "user-x",
            partnerAName: "Charlie"
        )
        couple.saveToCache()
        let loaded = Couple.loadFromCache()
        Couple.clearCache()

        #expect(loaded != nil)
        #expect(loaded?.partnerAName == "Charlie")
        #expect(loaded?.partnerAIdentifier == "user-x")
    }

    @Test func partnerBIdentifierIsNilByDefault() {
        let couple = Couple(partnerAIdentifier: "user-x", partnerAName: "Dana")
        #expect(couple.partnerBIdentifier == nil)
        #expect(couple.partnerBName == nil)
    }
}

// MARK: - LoveNote Model

struct LoveNoteModelTests {
    @Test func cloudKitRecordRoundTrip() throws {
        let createdAt = Date(timeIntervalSince1970: 1_600_000_000)
        let original = LoveNote(
            id: "note-123",
            coupleID: "couple-abc",
            authorID: "user-a",
            content: "Hello there!",
            createdAt: createdAt
        )

        let zoneID = CKRecordZone.ID(zoneName: "TestZone", ownerName: "__defaultOwner__")
        let record = original.toRecord(in: zoneID)

        #expect(record.recordType == "LoveNote")

        let restored = try #require(LoveNote(record: record))
        #expect(restored.id == original.id)
        #expect(restored.coupleID == original.coupleID)
        #expect(restored.authorID == original.authorID)
        #expect(restored.content == original.content)
    }

    @Test func isFromCurrentUser() {
        let note = LoveNote(coupleID: "c1", authorID: "user-a", content: "Hi")
        #expect(note.isFromCurrentUser(currentUserID: "user-a") == true)
        #expect(note.isFromCurrentUser(currentUserID: "user-b") == false)
    }

    @Test func cacheRoundTrip() {
        let notes = [
            LoveNote(coupleID: "c1", authorID: "a", content: "Note 1"),
            LoveNote(coupleID: "c1", authorID: "b", content: "Note 2")
        ]
        LoveNote.saveToCache(notes)
        let loaded = LoveNote.loadFromCache()
        LoveNote.clearCache()

        #expect(loaded.count == 2)
        #expect(loaded.map(\.content).contains("Note 1"))
        #expect(loaded.map(\.content).contains("Note 2"))
    }
}

// MARK: - ThisOrThat Comparison Logic

struct ThisOrThatAnswerTests {
    @Test func matchDetected() {
        let answers: [ThisOrThatAnswer] = [
            .init(coupleID: "c1", authorID: "user-a", questionIndex: 0, selectedOption: 1),
            .init(coupleID: "c1", authorID: "user-b", questionIndex: 0, selectedOption: 1)
        ]
        let comparisons = answers.createComparisons(currentUserID: "user-a", questionCount: 1)
        #expect(comparisons[0].isMatch == true)
        #expect(comparisons[0].bothAnswered == true)
    }

    @Test func mismatchDetected() {
        let answers: [ThisOrThatAnswer] = [
            .init(coupleID: "c1", authorID: "user-a", questionIndex: 0, selectedOption: 0),
            .init(coupleID: "c1", authorID: "user-b", questionIndex: 0, selectedOption: 1)
        ]
        let comparisons = answers.createComparisons(currentUserID: "user-a", questionCount: 1)
        #expect(comparisons[0].isMatch == false)
    }

    @Test func partialAnswerNotAMatch() {
        let answers: [ThisOrThatAnswer] = [
            .init(coupleID: "c1", authorID: "user-a", questionIndex: 0, selectedOption: 1)
        ]
        let comparisons = answers.createComparisons(currentUserID: "user-a", questionCount: 1)
        #expect(comparisons[0].bothAnswered == false)
        #expect(comparisons[0].isMatch == false)
    }

    @Test func cloudKitRecordRoundTrip() throws {
        let original = ThisOrThatAnswer(
            id: "ans-1",
            coupleID: "c1",
            authorID: "user-a",
            questionIndex: 3,
            selectedOption: 1
        )
        let zoneID = CKRecordZone.ID(zoneName: "TestZone", ownerName: "__defaultOwner__")
        let record = original.toRecord(in: zoneID)
        let restored = try #require(ThisOrThatAnswer(record: record))

        #expect(restored.questionIndex == 3)
        #expect(restored.selectedOption == 1)
        #expect(restored.authorID == "user-a")
    }
}

// MARK: - HomeViewModel Computed Properties

@MainActor
struct HomeViewModelTests {
    private func makeViewModel(reunionDate: Date? = nil, paired: Bool = true) -> HomeViewModel {
        let mock = MockCloudKitService()
        mock.couple = Couple(
            partnerAIdentifier: "mock-user-123",
            partnerBIdentifier: paired ? "partner-456" : nil,
            partnerAName: "Me",
            partnerBName: "Alex",
            reunionDate: reunionDate
        )
        return HomeViewModel(cloudKitService: mock)
    }

    @Test func hasReunionDateTrue() {
        let vm = makeViewModel(reunionDate: Date().addingTimeInterval(86_400 * 10))
        #expect(vm.hasReunionDate == true)
    }

    @Test func hasReunionDateFalse() {
        let vm = makeViewModel(reunionDate: nil)
        #expect(vm.hasReunionDate == false)
    }

    @Test func daysUntilVisit() throws {
        let future = try #require(Calendar.current.date(byAdding: .day, value: 15, to: Date()))
        let vm = makeViewModel(reunionDate: future)
        #expect(vm.daysUntilVisit >= 14 && vm.daysUntilVisit <= 15)
    }

    @Test func partnerNameReturnsPartnerBName() {
        let vm = makeViewModel()
        #expect(vm.partnerName == "Alex")
    }
}
