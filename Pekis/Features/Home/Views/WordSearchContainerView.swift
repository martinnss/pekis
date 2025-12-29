import SwiftUI
import Combine

struct WordSearchContainerView: View {
    @ObservedObject var viewModel: WordSearchViewModel
    let onFinish: (Int) -> Void
    let onExit: () -> Void

    @StateObject private var matchmaking = MatchmakingViewModel()
    @State private var countdown = 3
    @State private var showCountdown = false
    @State private var isAnimating = false

    @State private var showOpponentWonAlert = false

    var body: some View {
        ZStack {
            switch matchmaking.status {
            case .idle, .waitingForOpponent:
                waitingScreen
            case .readyToStart:
                if showCountdown {
                    countdownView
                } else {
                    // Should not happen usually, but fallback
                    Color.clear.onAppear { startCountdown() }
                }
            case .inGame:
                WordSearchGameView(
                    viewModel: viewModel,
                    onFinish: { score in
                        matchmaking.reportVictory()
                        onFinish(score)
                    },
                    onExit: {
                        matchmaking.leave()
                        onExit()
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            matchmaking.join()
        }
        .onChange(of: matchmaking.status) { newStatus in
            print("DEBUG: Matchmaking status changed to: \(newStatus)")
            if newStatus == .readyToStart {
                startCountdown()
            }
        }
        .onReceive(matchmaking.opponentWonSubject) { _ in
            showOpponentWonAlert = true
        }
        .alert("Game Over", isPresented: $showOpponentWonAlert) {
            Button("See Results") {
                // Finish with current score (or 0 if you prefer)
                onFinish(viewModel.foundWords.count)
            }
        } message: {
            Text("Your partner finished the puzzle first!")
        }
    }

    private var waitingScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(Color.pekisPurple, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }
            .onAppear {
                isAnimating = true
            }

            VStack(spacing: 8) {
                Text("Waiting for Player 2...")
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Text("Tell your partner to join!")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Button(action: {
                matchmaking.startSinglePlayer()
                viewModel.startGame()
            }) {
                Text("Play alone 😶‍🌫️")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.pekisPurple)
                    .clipShape(Capsule())
            }

            Button(action: {
                matchmaking.leave()
                onExit()
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.pekisBackground, Color.pekisBackground.opacity(0.0)],
                startPoint: .bottom,
                endPoint: .top
            )
        )
    }

    private var countdownView: some View {
        VStack {
            Text("\(countdown)")
                .font(.system(size: 120, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .pekisPurple, radius: 20)
                .transition(.scale.combined(with: .opacity))
                .id(countdown) // Triggers transition
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pekisBackground)
    }

    private func startCountdown() {
        print("DEBUG: startCountdown called")
        guard !showCountdown else {
            print("DEBUG: Countdown already showing, ignoring")
            return
        }

        showCountdown = true
        countdown = 3

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 1 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    countdown -= 1
                }
                HapticManager.selection() // Light tap for countdown
            } else {
                print("DEBUG: Countdown finished, starting game")
                timer.invalidate()
                withAnimation {
                    matchmaking.startGame()
                    viewModel.startGame()
                }
            }
        }
    }
}

class MatchmakingViewModel: ObservableObject {
    @Published var status: MatchStatus = .idle
    // Switch to GoogleAppsScriptMatchmakingService
    private let service: MatchmakingServiceProtocol = GoogleAppsScriptMatchmakingService()
    private var cancellables = Set<AnyCancellable>()
    private var statusCancellable: AnyCancellable?

    init() {
        statusCancellable = service.status
            .receive(on: RunLoop.main)
            .assign(to: \.status, on: self)

        service.opponentWon
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleOpponentVictory()
            }
            .store(in: &cancellables)
    }

    // ... existing code ...

    private func handleOpponentVictory() {
        // Notify the view that opponent won
        opponentWonSubject.send()
    }

    let opponentWonSubject = PassthroughSubject<Void, Never>()

    func join() {
        service.joinGame()
    }

    func leave() {
        service.leaveGame()
    }

    func startGame() {
        // Stop listening to status updates (so we stay in .inGame)
        statusCancellable?.cancel()
        statusCancellable = nil

        // We keep polling (service implementation detail) but we ignore its status output
        // We keep listening to opponentWon (in cancellables)

        status = .inGame
    }

    func reportVictory() {
        service.reportVictory()
    }

    func startSinglePlayer() {
        // Stop listening to everything
        statusCancellable?.cancel()
        statusCancellable = nil
        cancellables.removeAll()

        service.leaveGame()
        status = .inGame
    }
}
