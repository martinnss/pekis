import SwiftUI

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
        .onChange(of: matchmaking.status) { _, newStatus in
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
        guard !showCountdown else { return }
        showCountdown = true
        countdown = 3

        Task { @MainActor in
            for tick in stride(from: 3, through: 1, by: -1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    countdown = tick
                }
                HapticManager.selection()
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            withAnimation {
                matchmaking.startGame()
                viewModel.startGame()
            }
        }
    }
}
