import CloudKit
import Foundation
import Testing
@testable import Pekis

// MARK: - Retry classification and backoff

struct CloudKitRetryPolicyTests {
    private let policy = RetryPolicy.standard

    @Test(arguments: [
        CKError.Code.networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy
    ])
    func transientErrorsAreRetryable(code: CKError.Code) {
        #expect(CloudKitRetry.isRetryable(CKError(code)))
    }

    @Test(arguments: [
        CKError.Code.notAuthenticated, .serverRecordChanged, .permissionFailure, .quotaExceeded, .unknownItem, .invalidArguments
    ])
    func permanentErrorsAreNotRetryable(code: CKError.Code) {
        #expect(!CloudKitRetry.isRetryable(CKError(code)))
    }

    @Test func nonCloudKitErrorsAreNotRetryable() {
        #expect(!CloudKitRetry.isRetryable(CloudKitError.coupleNotFound))
        #expect(!CloudKitRetry.isRetryable(URLError(.notConnectedToInternet)))
    }

    @Test func delayDoublesEachAttemptAndIsCapped() {
        let error = CKError(.networkFailure)
        #expect(CloudKitRetry.delay(after: error, attempt: 1, policy: policy) == 1)
        #expect(CloudKitRetry.delay(after: error, attempt: 2, policy: policy) == 2)
        #expect(CloudKitRetry.delay(after: error, attempt: 3, policy: policy) == 4)
        #expect(CloudKitRetry.delay(after: error, attempt: 4, policy: policy) == 8)
        #expect(CloudKitRetry.delay(after: error, attempt: 10, policy: policy) == 8)
    }

    @Test func serverRetryAfterHintWinsButStaysCapped() {
        let shortHint = CKError(.requestRateLimited, userInfo: [CKErrorRetryAfterKey: 3.0])
        let longHint = CKError(.requestRateLimited, userInfo: [CKErrorRetryAfterKey: 600.0])
        #expect(CloudKitRetry.delay(after: shortHint, attempt: 1, policy: policy) == 3)
        #expect(CloudKitRetry.delay(after: longHint, attempt: 1, policy: policy) == policy.maxDelay)
    }
}

// MARK: - perform(): retry loop behavior

@MainActor
struct CloudKitRetryPerformTests {
    private final class Counter {
        var calls = 0
        var sleeps: [TimeInterval] = []
    }

    private func run(
        _ counter: Counter,
        policy: RetryPolicy = .standard,
        failures: [Error],
        result: Int = 42
    ) async throws -> Int {
        try await CloudKitRetry.perform(
            policy: policy,
            sleep: { counter.sleeps.append($0) },
            operation: {
                defer { counter.calls += 1 }
                if counter.calls < failures.count { throw failures[counter.calls] }
                return result
            }
        )
    }

    @Test func succeedsImmediatelyWithoutSleeping() async throws {
        let counter = Counter()
        let value = try await run(counter, failures: [])
        #expect(value == 42)
        #expect(counter.calls == 1)
        #expect(counter.sleeps.isEmpty)
    }

    @Test func recoversAfterTransientFailures() async throws {
        let counter = Counter()
        let value = try await run(counter, failures: [CKError(.networkFailure), CKError(.serviceUnavailable)])
        #expect(value == 42)
        #expect(counter.calls == 3)
        #expect(counter.sleeps == [1, 2])
    }

    @Test func permanentErrorIsThrownWithoutRetry() async {
        let counter = Counter()
        await #expect(throws: CKError.self) {
            _ = try await run(counter, failures: [CKError(.permissionFailure)])
        }
        #expect(counter.calls == 1)
        #expect(counter.sleeps.isEmpty)
    }

    @Test func givesUpAfterMaxAttemptsAndRethrowsTheLastError() async {
        let counter = Counter()
        let failures = Array(repeating: CKError(.networkUnavailable) as Error, count: 10)
        await #expect(throws: CKError.self) {
            _ = try await run(counter, failures: failures)
        }
        #expect(counter.calls == RetryPolicy.standard.maxAttempts)
        #expect(counter.sleeps.count == RetryPolicy.standard.maxAttempts - 1)
    }

    @Test func nonePolicyNeverRetries() async {
        let counter = Counter()
        await #expect(throws: CKError.self) {
            _ = try await run(counter, policy: .none, failures: [CKError(.networkFailure)])
        }
        #expect(counter.calls == 1)
    }

    @Test func cancellationDuringBackoffPropagates() async {
        let counter = Counter()
        await #expect(throws: CancellationError.self) {
            _ = try await CloudKitRetry.perform(
                sleep: { _ in throw CancellationError() },
                operation: {
                    counter.calls += 1
                    throw CKError(.networkFailure)
                }
            )
        }
        #expect(counter.calls == 1)
    }
}

// MARK: - Zone routing

struct CoupleDatabaseScopeTests {
    @Test func ownerOfTheZoneUsesThePrivateDatabase() {
        let zone = CKRecordZone.ID(zoneName: "CoupleZone", ownerName: CKCurrentUserDefaultName)
        #expect(CoupleDatabaseScope.scope(for: zone) == .privateDatabase)
    }

    @Test func partnerReachesTheZoneThroughTheSharedDatabase() {
        let zone = CKRecordZone.ID(zoneName: "CoupleZone", ownerName: "_abc123partnerA")
        #expect(CoupleDatabaseScope.scope(for: zone) == .sharedDatabase)
    }
}

// MARK: - iCloud account transitions

struct AccountTransitionTests {
    @Test(arguments: [
        CKAccountStatus.noAccount, .restricted, .couldNotDetermine, .temporarilyUnavailable
    ])
    func anyUnavailableStatusIsTreatedAsSignedOut(status: CKAccountStatus) {
        #expect(AccountTransition.determine(previousUserID: "me", status: status, currentUserID: nil) == .signedOut)
        #expect(AccountTransition.determine(previousUserID: nil, status: status, currentUserID: nil) == .signedOut)
    }

    @Test func firstSignInRunsSetup() {
        #expect(AccountTransition.determine(previousUserID: nil, status: .available, currentUserID: "me") == .signedIn)
    }

    @Test func sameAccountIsUnchanged() {
        #expect(AccountTransition.determine(previousUserID: "me", status: .available, currentUserID: "me") == .unchanged)
    }

    @Test func differentAccountIsASwitch() {
        #expect(AccountTransition.determine(previousUserID: "me", status: .available, currentUserID: "someone-else") == .switchedAccount)
    }

    @Test func unknownIdentityIsUnchangedRatherThanASwitch() {
        #expect(AccountTransition.determine(previousUserID: "me", status: .available, currentUserID: nil) == .unchanged)
    }
}

// MARK: - Pairing state

struct CouplePairingTests {
    @Test func acceptingPartnerRegistersPartnerB() {
        let couple = Couple(partnerAIdentifier: "alice", partnerAName: "Alice")
        let joined = couple.acceptingPartner(userID: "bob")
        #expect(joined.partnerBIdentifier == "bob")
        #expect(joined.partnerAIdentifier == "alice")
        #expect(joined.id == couple.id)
    }

    @Test func acceptingPartnerNeverOverwritesAnExistingPartnerB() {
        let couple = Couple(partnerAIdentifier: "alice", partnerBIdentifier: "bob", partnerAName: "Alice")
        #expect(couple.acceptingPartner(userID: "mallory").partnerBIdentifier == "bob")
    }

    @Test func partnerBNameIsMissingUntilEntered() {
        #expect(Couple(partnerAIdentifier: "a", partnerAName: "A", partnerBName: nil).isMissingPartnerBName)
        #expect(Couple(partnerAIdentifier: "a", partnerAName: "A", partnerBName: "").isMissingPartnerBName)
        #expect(!Couple(partnerAIdentifier: "a", partnerAName: "A", partnerBName: "Bob").isMissingPartnerBName)
    }
}

// MARK: - Service error handling (no CloudKit access needed)

@MainActor
struct CloudKitServiceErrorHandlingTests {
    private func message(for error: Error) -> String? {
        let service = CloudKitService(containerIdentifier: "iCloud.test.pekis")
        service.handleError(error)
        return service.errorMessage
    }

    @Test func notAuthenticatedAsksUserToSignIn() {
        #expect(message(for: CKError(.notAuthenticated)) == CloudKitError.notAuthenticated.errorDescription)
    }

    @Test func networkErrorsExplainDataWillSyncLater() {
        #expect(message(for: CKError(.networkUnavailable))?.contains("Network unavailable") == true)
        #expect(message(for: CKError(.networkFailure))?.contains("Network unavailable") == true)
    }

    @Test func quotaExceededMentionsStorage() {
        #expect(message(for: CKError(.quotaExceeded))?.contains("storage") == true)
    }

    @Test func queryabilityErrorsAreSuppressed() {
        #expect(message(for: CKError(.invalidArguments)) == nil)
    }

    @Test func appErrorsPassTheirOwnDescriptionThrough() {
        #expect(message(for: CloudKitError.coupleNotFound) == CloudKitError.coupleNotFound.errorDescription)
    }

    @Test func unexpectedErrorsGetAGenericMessage() {
        #expect(message(for: URLError(.badServerResponse))?.contains("unexpected error") == true)
    }

    @Test func nonCloudKitPushPayloadsAreIgnored() async {
        let service = CloudKitService(containerIdentifier: "iCloud.test.pekis")
        var posted = 0
        let token = NotificationCenter.default.addObserver(forName: .pekisCloudKitDataChanged, object: nil, queue: nil) { _ in
            posted += 1
        }
        defer { NotificationCenter.default.removeObserver(token) }

        await service.handleNotification(userInfo: ["aps": ["content-available": 1]])
        await service.handleNotification(userInfo: [:])
        #expect(posted == 0)
    }

    @Test func skippingInitialLoadUnblocksTheUI() {
        let service = CloudKitService(containerIdentifier: "iCloud.test.pekis")
        #expect(!service.hasLoadedInitialState)
        service.skipInitialLoad()
        #expect(service.hasLoadedInitialState)
    }

    @Test func freshServiceIsNotPaired() {
        #expect(!CloudKitService(containerIdentifier: "iCloud.test.pekis").isPaired)
    }
}
