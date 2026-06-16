import Foundation
import CloudKit

/// Protocol defining CloudKit operations for couple data synchronization
/// Enables dependency injection and testability
@MainActor
protocol CloudKitServiceProtocol: ObservableObject {
    // MARK: - State

    /// Current user's CloudKit identifier
    var currentUserID: String? { get }

    /// Currently paired couple (nil if not yet paired)
    var couple: Couple? { get }

    /// Whether the user has completed pairing with a partner
    var isPaired: Bool { get }

    /// Whether Partner B needs to enter their name after accepting a share invitation
    var needsPartnerName: Bool { get set }

    /// Loading state for UI feedback
    var isLoading: Bool { get }

    /// True once the initial cold-launch couple check has completed
    var hasLoadedInitialState: Bool { get }

    /// Error message for UI display
    var errorMessage: String? { get }

    // MARK: - Setup

    /// Initialize CloudKit and fetch current user identifier
    func setup() async

    /// Check if a couple relationship already exists
    func checkExistingCouple() async

    // MARK: - Couple Management

    /// Create a new couple record (Partner A initiates)
    /// - Parameter name: The name of the user creating the couple
    /// - Returns: The created Couple
    func createCouple(name: String) async throws -> Couple

    /// Accept a share invitation (Partner B joins)
    /// - Parameter metadata: The share metadata from the invitation URL
    func acceptShare(_ metadata: CKShare.Metadata) async throws

    /// Update the reunion date for the couple
    /// - Parameter date: The new reunion date
    func updateReunionDate(_ date: Date) async throws

    /// Update partner name
    /// - Parameter name: The new name
    func updateMyName(_ name: String) async throws

    /// Break the couple connection and wipe all shared data for a clean slate.
    /// The owner deletes the couple zone (erasing the record, the share, and all
    /// shared content for both partners); a participant leaves the share. Local
    /// caches are always cleared so the app returns to onboarding.
    func disconnectCouple() async throws

    // MARK: - Love Notes

    /// Send a love note to partner
    /// - Parameter content: The note content
    func sendLoveNote(content: String) async throws

    /// Fetch all love notes for the couple
    /// - Returns: Array of love notes sorted by date
    func fetchLoveNotes() async throws -> [LoveNote]

    // MARK: - This or That

    /// Save a This or That answer
    /// - Parameters:
    ///   - questionIndex: The index of the question
    ///   - selectedOption: The selected option (0 or 1)
    func saveThisOrThatAnswer(questionIndex: Int, selectedOption: Int) async throws

    /// Fetch all This or That answers for the couple
    /// - Returns: Array of answers from both partners
    func fetchThisOrThatAnswers() async throws -> [ThisOrThatAnswer]

    // MARK: - Moments

    /// Save a daily photo moment to the shared zone
    /// - Parameters:
    ///   - imageData: JPEG-compressed image data
    ///   - prompt: The daily prompt shown to both partners
    func saveMoment(imageData: Data, prompt: String) async throws

    /// Fetch today's moments for both partners
    /// - Returns: Array of today's MomentShareRecord (0–2 items: one per partner)
    func fetchTodaysMoments() async throws -> [MomentShareRecord]

    // MARK: - Word Search Sessions

    /// Fetch the active Word Search session for the paired couple, if one exists
    func fetchWordSearchSession() async throws -> WordSearchSession?

    /// Save the active Word Search session for the paired couple
    func saveWordSearchSession(_ session: WordSearchSession) async throws -> WordSearchSession

    /// Delete the active Word Search session for the paired couple
    func deleteWordSearchSession() async throws

    // MARK: - Sharing

    /// Get the CKShare for the couple zone (for UICloudSharingController)
    func getOrCreateShare() async throws -> CKShare

    /// Check if there's a pending share to accept
    var pendingShareMetadata: CKShare.Metadata? { get set }

    // MARK: - Subscriptions

    /// Subscribe to changes in both private and shared databases for real-time updates
    func subscribeToChanges() async throws

    /// Process incoming push notification for data changes
    func handleNotification(userInfo: [AnyHashable: Any]) async
}

// MARK: - CloudKit Error Types

enum CloudKitError: LocalizedError {
    case notAuthenticated
    case coupleNotFound
    case shareNotFound
    case recordNotFound
    case saveFailed(Error)
    case fetchFailed(Error)
    case shareFailed(Error)
    case zoneCreationFailed(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to iCloud in Settings to use this feature."
        case .coupleNotFound:
            return "No couple relationship found. Please create or join one."
        case .shareNotFound:
            return "Share not found. Please try creating a new invitation."
        case .recordNotFound:
            return "Record not found in CloudKit."
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .shareFailed(let error):
            return "Failed to share: \(error.localizedDescription)"
        case .zoneCreationFailed(let error):
            return "Failed to create private zone: \(error.localizedDescription)"
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}
