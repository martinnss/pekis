import Combine
import Foundation
import OSLog

@MainActor
final class MatchmakingViewModel: ObservableObject {
    @Published var status: MatchStatus = .idle
    @Published private(set) var scheduledStartAt: Date?
    @Published private(set) var sessionSeed: UInt64?
    @Published private(set) var isLocalPlayerReady = false
    @Published private(set) var isPartnerReady = false
    @Published private(set) var partnerDisplayName = "Partner"

    let opponentWonSubject = PassthroughSubject<Void, Never>()

    private let cloudKitService: (any CloudKitServiceProtocol)?
    private let service: any MatchmakingServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var statusCancellable: AnyCancellable?
    private var sessionCancellable: AnyCancellable?

    init(
        cloudKitService: (any CloudKitServiceProtocol)? = nil,
        service: (any MatchmakingServiceProtocol)? = nil
    ) {
        self.cloudKitService = cloudKitService
        let resolvedService = service ?? Self.makeDefaultService(cloudKitService: cloudKitService)
        self.service = resolvedService
        refreshParticipantLabels()

        statusCancellable = resolvedService.status
            .receive(on: RunLoop.main)
            .assign(to: \.status, on: self)

        sessionCancellable = resolvedService.session
            .receive(on: RunLoop.main)
            .sink { [weak self] session in
                self?.updateSessionState(session)
            }

        resolvedService.opponentWon
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.handleOpponentVictory() }
            .store(in: &cancellables)
    }

    func join() { service.joinGame() }

    func leave() {
        scheduledStartAt = nil
        sessionSeed = nil
        isLocalPlayerReady = false
        isPartnerReady = false
        service.leaveGame()
    }

    func reportResult(score: Int) { service.reportResult(score: score) }

    func startGame() {
        statusCancellable?.cancel()
        statusCancellable = nil
        status = .inGame
    }

    func startSinglePlayer() {
        statusCancellable?.cancel()
        statusCancellable = nil
        sessionCancellable?.cancel()
        sessionCancellable = nil
        cancellables.removeAll()
        scheduledStartAt = nil
        sessionSeed = nil
        isLocalPlayerReady = false
        isPartnerReady = false
        service.leaveGame()
        status = .inGame
    }

    private func handleOpponentVictory() {
        opponentWonSubject.send()
    }

    private func updateSessionState(_ session: WordSearchSession?) {
        scheduledStartAt = session?.scheduledStartAt
        sessionSeed = session?.seed
        refreshParticipantLabels()

        guard let session,
              let currentUserID = cloudKitService?.currentUserID,
              session.containsParticipant(currentUserID)
        else {
            isLocalPlayerReady = false
            isPartnerReady = false
            return
        }

        isLocalPlayerReady = session.readyAt(for: currentUserID) != nil

        if let partnerID = session.otherPlayerID(for: currentUserID) {
            isPartnerReady = session.readyAt(for: partnerID) != nil
        } else {
            isPartnerReady = false
        }
    }

    private func refreshParticipantLabels() {
        guard let cloudKitService,
              let couple = cloudKitService.couple,
              let currentUserID = cloudKitService.currentUserID
        else {
            partnerDisplayName = "Partner"
            return
        }

        if currentUserID == couple.partnerAIdentifier {
            partnerDisplayName = Self.displayName(from: couple.partnerBName)
        } else {
            partnerDisplayName = Self.displayName(from: couple.partnerAName)
        }
    }

    private static func displayName(from rawValue: String?) -> String {
        guard let rawValue else { return "Partner" }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? "Partner" : trimmedValue
    }

    private static func makeDefaultService(
        cloudKitService: (any CloudKitServiceProtocol)?
    ) -> any MatchmakingServiceProtocol {
        guard let cloudKitService, cloudKitService.isPaired else {
            PekisLogger.gameplay.notice("Couple pairing unavailable. Falling back to simulation service.")
            return SimulationMatchmakingService()
        }

        return CloudKitCoupleMatchmakingService(cloudKitService: cloudKitService)
    }
}
