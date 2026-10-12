import CloudKit
import Foundation

/// Exponential-backoff settings for transient CloudKit failures.
struct RetryPolicy: Equatable {
    var maxAttempts: Int
    var baseDelay: TimeInterval
    var maxDelay: TimeInterval

    static let standard = RetryPolicy(maxAttempts: 3, baseDelay: 1, maxDelay: 8)
    static let none = RetryPolicy(maxAttempts: 1, baseDelay: 0, maxDelay: 0)
}

/// Retries CloudKit operations that fail for transient reasons (network loss, throttling, busy zone).
///
/// Only errors CloudKit documents as safe to retry are retried; conflicts, permission and
/// validation errors surface immediately so callers can handle them.
enum CloudKitRetry {
    /// Whether a failed operation is worth attempting again.
    static func isRetryable(_ error: Error) -> Bool {
        guard let ckError = error as? CKError else { return false }
        switch ckError.code {
        case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy:
            return true
        default:
            return false
        }
    }

    /// Seconds to wait before retry number `attempt` (1-based).
    /// Honors the server's `retryAfterSeconds` hint, otherwise doubles each time up to `maxDelay`.
    static func delay(after error: Error, attempt: Int, policy: RetryPolicy) -> TimeInterval {
        if let serverHint = (error as? CKError)?.retryAfterSeconds {
            return min(serverHint, policy.maxDelay)
        }
        let exponential = policy.baseDelay * pow(2, Double(max(attempt - 1, 0)))
        return min(exponential, policy.maxDelay)
    }

    /// Runs `operation`, retrying retryable failures according to `policy`.
    /// `sleep` is injectable so tests don't actually wait.
    @MainActor
    static func perform<Result>(
        policy: RetryPolicy = .standard,
        sleep: (TimeInterval) async throws -> Void = { try await Task.sleep(nanoseconds: UInt64($0 * 1_000_000_000)) },
        operation: () async throws -> Result
    ) async throws -> Result {
        var attempt = 1
        while true {
            do {
                return try await operation()
            } catch {
                guard attempt < policy.maxAttempts, isRetryable(error) else { throw error }
                try await sleep(delay(after: error, attempt: attempt, policy: policy))
                attempt += 1
            }
        }
    }
}
