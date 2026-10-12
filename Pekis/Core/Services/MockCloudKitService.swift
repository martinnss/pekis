import Foundation
import CloudKit
import Combine
import OSLog

#if DEBUG
@MainActor
final class MockCloudKitService: ObservableObject, CloudKitServiceProtocol {
    @Published var currentUserID: String? = "mock-user-123"
    @Published var couple: Couple? = Couple(
        partnerAIdentifier: "mock-user-123",
        partnerBIdentifier: "partner-456",
        partnerAName: "You",
        partnerBName: "Partner",
        reunionDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())
    )
    @Published var isLoading = false
    @Published var hasLoadedInitialState = true
    @Published var errorMessage: String?
    @Published var pendingShareMetadata: CKShare.Metadata?
    @Published var needsPartnerName: Bool = false

    private var wordSearchSession: WordSearchSession?

    var isPaired: Bool { couple?.partnerBIdentifier != nil }

    func setup() async {}
    func checkExistingCouple() async {}
    func createCouple(name: String) async throws -> Couple {
        let newCouple = Couple(partnerAIdentifier: currentUserID ?? "", partnerAName: name)
        couple = newCouple
        return newCouple
    }
    func acceptShare(_ metadata: CKShare.Metadata) async throws {}
    func updateReunionDate(_ date: Date) async throws {
        couple?.reunionDate = date
    }
    func updateMyName(_ name: String) async throws {}
    func disconnectCouple() async throws { couple = nil }
    func sendLoveNote(content: String) async throws {}
    func fetchLoveNotes() async throws -> [LoveNote] { [] }
    func saveThisOrThatAnswer(questionIndex: Int, selectedOption: Int) async throws {}
    func fetchThisOrThatAnswers() async throws -> [ThisOrThatAnswer] { [] }
    func saveMoment(imageData: Data, prompt: String) async throws {}
    func fetchTodaysMoments() async throws -> [MomentShareRecord] { [] }
    func fetchWordSearchSession() async throws -> WordSearchSession? {
        wordSearchSession
    }
    func saveWordSearchSession(_ session: WordSearchSession) async throws -> WordSearchSession {
        wordSearchSession = session
        return session
    }
    func deleteWordSearchSession() async throws {
        wordSearchSession = nil
    }
    func getOrCreateShare() async throws -> CKShare {
        // Return a stub CKShare to avoid fatalError crashing previews
        throw CloudKitError.shareNotFound
    }
    func subscribeToChanges() async throws {}
    func handleNotification(userInfo: [AnyHashable: Any]) async {}
}
#endif
