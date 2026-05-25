import Combine
import Foundation

@MainActor
final class MatchmakingViewModel: ObservableObject {
    @Published var status: MatchStatus = .idle

    let opponentWonSubject = PassthroughSubject<Void, Never>()

    private let service: MatchmakingServiceProtocol = GoogleAppsScriptMatchmakingService()
    private var cancellables = Set<AnyCancellable>()
    private var statusCancellable: AnyCancellable?

    init() {
        statusCancellable = service.status
            .receive(on: RunLoop.main)
            .assign(to: \.status, on: self)

        service.opponentWon
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.handleOpponentVictory() }
            .store(in: &cancellables)
    }

    func join() { service.joinGame() }

    func leave() { service.leaveGame() }

    func reportVictory() { service.reportVictory() }

    func startGame() {
        statusCancellable?.cancel()
        statusCancellable = nil
        status = .inGame
    }

    func startSinglePlayer() {
        statusCancellable?.cancel()
        statusCancellable = nil
        cancellables.removeAll()
        service.leaveGame()
        status = .inGame
    }

    private func handleOpponentVictory() {
        opponentWonSubject.send()
    }
}
