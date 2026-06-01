import XCTest
import CloudKit
@testable import Pekis

final class WordSearchSessionTests: XCTestCase {
    func testReadyStateTracksBothPartners() {
        let couple = Couple(
            id: "couple-123",
            partnerAIdentifier: "partner-a",
            partnerBIdentifier: "partner-b",
            partnerAName: "A",
            partnerBName: "B"
        )
        var session = WordSearchSession(couple: couple, partnerBIdentifier: "partner-b", seed: 99, now: Date())

        XCTAssertFalse(session.bothPlayersReady)

        session.markReady(for: "partner-a", at: Date())
        XCTAssertFalse(session.bothPlayersReady)

        session.markReady(for: "partner-b", at: Date())
        XCTAssertTrue(session.bothPlayersReady)
    }

    func testRecordRoundTripPreservesSeedAndSchedule() {
        let now = Date(timeIntervalSince1970: 1_717_171_717)
        let couple = Couple(
            id: "couple-123",
            partnerAIdentifier: "partner-a",
            partnerBIdentifier: "partner-b",
            partnerAName: "A",
            partnerBName: "B"
        )
        var session = WordSearchSession(
            couple: couple,
            partnerBIdentifier: "partner-b",
            seed: 4242,
            now: now
        )

        session.markReady(for: "partner-a", at: now)
        session.markReady(for: "partner-b", at: now)
        session.scheduleCountdown(from: now, countdown: 3)
        session.setScore(6, for: "partner-a")
        session.winnerID = "partner-a"
        session.status = .finished

        let zoneID = CKRecordZone.ID(zoneName: "CoupleZone", ownerName: CKCurrentUserDefaultName)
        let record = session.toRecord(in: zoneID)
        let decodedSession = WordSearchSession(record: record)

        XCTAssertNotNil(decodedSession)
        XCTAssertEqual(decodedSession?.seed, session.seed)
        XCTAssertEqual(decodedSession?.scheduledStartAt, session.scheduledStartAt)
        XCTAssertEqual(decodedSession?.winnerID, session.winnerID)
        XCTAssertEqual(decodedSession?.status, session.status)
    }
}