import Foundation
import Combine

enum MatchStatus {
    case idle
    case waitingForOpponent
    case readyToStart
    case inGame
}

protocol MatchmakingServiceProtocol {
    var status: CurrentValueSubject<MatchStatus, Never> { get }
    var opponentWon: PassthroughSubject<Void, Never> { get }
    func joinGame()
    func leaveGame()
    func reportVictory()
}

// MARK: - Simulation Service (For MVP Testing)
class SimulationMatchmakingService: MatchmakingServiceProtocol {
    var status = CurrentValueSubject<MatchStatus, Never>(.idle)
    var opponentWon = PassthroughSubject<Void, Never>()
    private var timer: Timer?

    func joinGame() {
        status.send(.waitingForOpponent)

        // Simulate opponent joining after 2 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.status.send(.readyToStart)
        }
    }

    func leaveGame() {
        timer?.invalidate()
        status.send(.idle)
    }

    func reportVictory() {
        // No-op for simulation
    }
}

// MARK: - Google Apps Script Service
class GoogleAppsScriptMatchmakingService: MatchmakingServiceProtocol {
    var status = CurrentValueSubject<MatchStatus, Never>(.idle)
    var opponentWon = PassthroughSubject<Void, Never>()

    // ⚠️ REPLACE THIS with your actual Google Apps Script Web App URL
    // It should look like: https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
    private let scriptURL: URL = {
        guard let url = URL(string: "https://script.google.com/macros/s/AKfycbxPaWTZZAblFcbGoZr_XIRofAS_2ZnKP6SzsqzqNl4TUlWN0yceJCdnQtR7pO3Vl0Xw/exec") else {
            preconditionFailure("Invalid matchmaking service URL")
        }
        return url
    }()

    private let sessionID = UUID().uuidString
    private var pollingTask: Task<Void, Never>?

    func joinGame() {
        status.send(.waitingForOpponent)
        startPolling()
    }

    func leaveGame() {
        stopPolling()
        status.send(.idle)
    }

    func reportVictory() {
        // Fire-and-forget: notify server that this session finished
        guard var components = URLComponents(url: scriptURL, resolvingAgainstBaseURL: true) else { return }
        components.queryItems = [
            URLQueryItem(name: "action", value: "finish"),
            URLQueryItem(name: "id", value: sessionID)
        ]
        guard let url = components.url else { return }
        Task { _ = try? await URLSession.shared.data(from: url) }
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            guard let self else { return }
            // Check immediately, then every 1.5 s
            while !Task.isCancelled {
                await self.checkServerStatus()
                try? await Task.sleep(nanoseconds: 1_500_000_000)
            }
        }
    }

    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func checkServerStatus() async {
        guard var components = URLComponents(url: scriptURL, resolvingAgainstBaseURL: true) else { return }
        components.queryItems = [
            URLQueryItem(name: "action", value: "heartbeat"),
            URLQueryItem(name: "id", value: sessionID)
        ]
        guard let url = components.url else { return }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let response = try? JSONDecoder().decode(ServerResponse.self, from: data)
        else { return }

        await MainActor.run {
            // 1. Check for a winner
            if let winnerID = response.winner_id, !winnerID.isEmpty, winnerID != sessionID {
                print("DEBUG: Opponent won!")
                opponentWon.send()
                stopPolling()
                return
            }

            // 2. Check for match start (2+ active players)
            if response.active_players >= 2, status.value != .readyToStart {
                print("DEBUG: Match found! Sending .readyToStart")
                status.send(.readyToStart)
            }
        }
    }
}

struct ServerResponse: Codable {
    let active_players: Int
    let winner_id: String?
}
