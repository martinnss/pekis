import Foundation
import Combine
import OSLog

enum MatchStatus {
    case idle
    case waitingForOpponent
    case readyToStart
    case inGame
}

protocol MatchmakingServiceProtocol {
    var status: CurrentValueSubject<MatchStatus, Never> { get }
    var opponentWon: PassthroughSubject<Void, Never> { get }
    var session: CurrentValueSubject<WordSearchSession?, Never> { get }
    func joinGame()
    func leaveGame()
    func reportResult(score: Int)
}

// MARK: - Simulation Service (For MVP Testing)
class SimulationMatchmakingService: MatchmakingServiceProtocol {
    var status = CurrentValueSubject<MatchStatus, Never>(.idle)
    var opponentWon = PassthroughSubject<Void, Never>()
    var session = CurrentValueSubject<WordSearchSession?, Never>(nil)
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
        session.send(nil)
        status.send(.idle)
    }

    func reportResult(score: Int) {
        // No-op for simulation
    }
}

// MARK: - CloudKit Service

final class CloudKitCoupleMatchmakingService: MatchmakingServiceProtocol {
    var status = CurrentValueSubject<MatchStatus, Never>(.idle)
    var opponentWon = PassthroughSubject<Void, Never>()
    var session = CurrentValueSubject<WordSearchSession?, Never>(nil)

    private let cloudKitService: any CloudKitServiceProtocol
    private let countdownLeadTime: TimeInterval = 3
    private let sessionLifetime: TimeInterval = 15 * 60
    private let pollingIntervalNanoseconds: UInt64 = 1_000_000_000
    private var pollingTask: Task<Void, Never>?
    private var notificationCancellable: AnyCancellable?
    private var hasEmittedOpponentWin = false

    init(cloudKitService: any CloudKitServiceProtocol) {
        self.cloudKitService = cloudKitService
        notificationCancellable = NotificationCenter.default.publisher(for: .pekisCloudKitDataChanged)
            .sink { [weak self] _ in
                self?.refreshFromNotification()
            }
    }

    deinit {
        pollingTask?.cancel()
        notificationCancellable?.cancel()
    }

    func joinGame() {
        status.send(.waitingForOpponent)
        hasEmittedOpponentWin = false
        startPolling()
    }

    func leaveGame() {
        stopPolling()
        let activeSession = session.value
        session.send(nil)
        status.send(.idle)
        hasEmittedOpponentWin = false

        Task { [weak self] in
            await self?.release(activeSession)
        }
    }

    func reportResult(score: Int) {
        guard var currentSession = session.value,
              let currentUserID = cloudKitService.currentUserID
        else {
            return
        }

        stopPolling()

        Task { [weak self] in
            let now = Date()
            currentSession.setScore(score, for: currentUserID)
            if currentSession.winnerID == nil {
                currentSession.winnerID = currentUserID
            }
            currentSession.status = .finished
            currentSession.refreshExpiration(from: now, lifetime: self?.sessionLifetime ?? 15 * 60)

            guard let self else { return }

            do {
                let savedSession = try await cloudKitService.saveWordSearchSession(currentSession)
                session.send(savedSession)
            } catch {
                PekisLogger.gameplay.error("Failed to save Word Search result: \(error.localizedDescription)")
            }
        }
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            guard let self else { return }
            await joinOrCreateSession()

            while !Task.isCancelled {
                await refreshCurrentSession()
                try? await Task.sleep(nanoseconds: pollingIntervalNanoseconds)
            }
        }
    }

    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func joinOrCreateSession() async {
        guard let couple = cloudKitService.couple,
              let currentUserID = cloudKitService.currentUserID,
              let partnerBIdentifier = couple.partnerBIdentifier
        else {
            PekisLogger.gameplay.notice("Word Search CloudKit session unavailable. Waiting for paired couple context.")
            status.send(.idle)
            return
        }

        do {
            let now = Date()
            let existingSession = try await cloudKitService.fetchWordSearchSession()
            let baseSession: WordSearchSession

            if let existingSession,
               existingSession.status != .finished,
               existingSession.status != .cancelled,
               !existingSession.isExpired(at: now) {
                baseSession = existingSession
            } else {
                baseSession = WordSearchSession(
                    couple: couple,
                    partnerBIdentifier: partnerBIdentifier,
                    seed: Self.makeSeed(),
                    now: now,
                    lifetime: sessionLifetime
                )
            }

            let reconciledSession = try await reconcile(baseSession, currentUserID: currentUserID, now: now)
            apply(reconciledSession, currentUserID: currentUserID)
        } catch {
            PekisLogger.gameplay.error("Failed to create Word Search session: \(error.localizedDescription)")
            status.send(.idle)
        }
    }

    private func refreshCurrentSession() async {
        guard let currentUserID = cloudKitService.currentUserID else {
            status.send(.idle)
            session.send(nil)
            return
        }

        do {
            guard let fetchedSession = try await cloudKitService.fetchWordSearchSession() else {
                session.send(nil)
                status.send(.idle)
                return
            }

            let now = Date()
            if fetchedSession.status == .cancelled || fetchedSession.isExpired(at: now) {
                session.send(nil)
                status.send(.idle)
                return
            }

            if fetchedSession.status == .finished {
                apply(fetchedSession, currentUserID: currentUserID)
                return
            }

            let reconciledSession = try await reconcile(fetchedSession, currentUserID: currentUserID, now: now)
            apply(reconciledSession, currentUserID: currentUserID)
        } catch {
            PekisLogger.gameplay.error("Failed to refresh Word Search session: \(error.localizedDescription)")
        }
    }

    private func reconcile(
        _ session: WordSearchSession,
        currentUserID: String,
        now: Date
    ) async throws -> WordSearchSession {
        var session = session
        var didMutate = false

        guard session.containsParticipant(currentUserID) else {
            return session
        }

        if session.readyAt(for: currentUserID) == nil {
            session.markReady(for: currentUserID, at: now)
            session.refreshExpiration(from: now, lifetime: sessionLifetime)
            didMutate = true
        }

        if session.bothPlayersReady && session.scheduledStartAt == nil {
            session.scheduleCountdown(from: now, countdown: countdownLeadTime, lifetime: sessionLifetime)
            didMutate = true
        }

        if !session.bothPlayersReady && session.status != .waiting {
            session.status = .waiting
            session.scheduledStartAt = nil
            session.refreshExpiration(from: now, lifetime: sessionLifetime)
            didMutate = true
        }

        guard didMutate else {
            return session
        }

        return try await cloudKitService.saveWordSearchSession(session)
    }

    private func apply(_ session: WordSearchSession, currentUserID: String) {
        self.session.send(session)

        if let winnerID = session.winnerID,
           winnerID != currentUserID,
           !hasEmittedOpponentWin {
            hasEmittedOpponentWin = true
            PekisLogger.gameplay.notice("Opponent victory received from CloudKit Word Search session.")
            opponentWon.send()
        }

        guard session.winnerID == nil else {
            return
        }

        if session.bothPlayersReady && session.scheduledStartAt != nil {
            status.send(.readyToStart)
        } else {
            status.send(.waitingForOpponent)
        }
    }

    private func release(_ activeSession: WordSearchSession?) async {
        guard var activeSession,
              let currentUserID = cloudKitService.currentUserID,
              activeSession.containsParticipant(currentUserID),
              activeSession.winnerID == nil
        else {
            return
        }

        let now = Date()
        if let scheduledStartAt = activeSession.scheduledStartAt,
           scheduledStartAt <= now {
            return
        }

        activeSession.clearReady(for: currentUserID)
        activeSession.scheduledStartAt = nil
        activeSession.status = .waiting
        activeSession.refreshExpiration(from: now, lifetime: sessionLifetime)

        do {
            if activeSession.hasAnyReadyPlayer {
                _ = try await cloudKitService.saveWordSearchSession(activeSession)
            } else {
                try await cloudKitService.deleteWordSearchSession()
            }
        } catch {
            PekisLogger.gameplay.error("Failed to release Word Search session: \(error.localizedDescription)")
        }
    }

    private func refreshFromNotification() {
        guard pollingTask != nil else { return }

        Task { [weak self] in
            await self?.refreshCurrentSession()
        }
    }

    private static func makeSeed() -> UInt64 {
        UInt64.random(in: 1...UInt64(Int64.max))
    }
}
