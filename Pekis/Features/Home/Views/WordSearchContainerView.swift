import SwiftUI

struct WordSearchContainerView: View {
    @ObservedObject var viewModel: WordSearchViewModel
    let onFinish: (Int) -> Void
    let onExit: () -> Void

    @StateObject private var matchmaking: MatchmakingViewModel
    @State private var countdown = 3
    @State private var showCountdown = false
    @State private var isAnimating = false

    @State private var showOpponentWonAlert = false
    @State private var countdownTask: Task<Void, Never>?

    init(
        viewModel: WordSearchViewModel,
        cloudKitService: any CloudKitServiceProtocol,
        onFinish: @escaping (Int) -> Void,
        onExit: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onFinish = onFinish
        self.onExit = onExit
        _matchmaking = StateObject(wrappedValue: MatchmakingViewModel(cloudKitService: cloudKitService))
    }

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
                        matchmaking.reportResult(score: score)
                        onFinish(score)
                    },
                    onExit: {
                        countdownTask?.cancel()
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
        .onDisappear {
            countdownTask?.cancel()
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
                countdownTask?.cancel()
                matchmaking.leave()
                // Finish with current score (or 0 if you prefer)
                onFinish(viewModel.foundWords.count)
            }
        } message: {
            Text("Your partner finished the puzzle first!")
        }
    }

    private var waitingScreen: some View {
        VStack(spacing: 22) {
            Spacer()

            PekiDuo(mood: .hopeful, size: 92)

            VStack(spacing: 8) {
                Text(waitingTitle)
                    .font(PekisFont.title())
                    .foregroundStyle(.pekisInk)

                Text(waitingSubtitle)
                    .font(PekisFont.body())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.pekisInkSoft)
                    .padding(.horizontal, 24)
            }

            if let startSummary {
                Label(startSummary, systemImage: "icloud.fill")
                    .cozyChip(.pekisMint)
            }

            readinessSection
                .padding(.horizontal, 20)

            Spacer()

            Button(action: {
                countdownTask?.cancel()
                matchmaking.startSinglePlayer()
                viewModel.startGame()
            }) {
                Label("Play alone", systemImage: "person.fill")
            }
            .buttonStyle(SquishyButtonStyle(tint: .pekisMint))

            Button(action: {
                countdownTask?.cancel()
                matchmaking.leave()
                onExit()
            }) {
                Text("Cancel")
            }
            .buttonStyle(CapsuleButtonStyle(background: .pekisSurfaceSoft, foreground: .pekisInk))
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var countdownView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Synced Start")
                    .font(PekisFont.headline())
                    .foregroundStyle(.pekisInk)

                Text("Both devices locked the same CloudKit session.")
                    .font(PekisFont.body())
                    .foregroundStyle(.pekisInkSoft)
            }

            if let startSummary {
                Label(startSummary, systemImage: "clock.badge.checkmark.fill")
                    .cozyChip(.pekisMint)
            }

            Text("\(countdown)")
                .font(.system(size: 120, weight: .black, design: .rounded))
                .foregroundStyle(.pekisCoral)
                .shadow(color: Color.pekisCoral.opacity(0.4), radius: 18)
                .transition(.scale.combined(with: .opacity))
                .id(countdown) // Triggers transition

            readinessSection
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var readinessSection: some View {
        HStack(spacing: 12) {
            readinessCard(
                title: "You",
                isReady: matchmaking.isLocalPlayerReady,
                detail: matchmaking.isLocalPlayerReady ? "Ready in shared round" : "Joining session"
            )

            readinessCard(
                title: matchmaking.partnerDisplayName,
                isReady: matchmaking.isPartnerReady,
                detail: matchmaking.isPartnerReady ? "Ready in shared round" : "Still joining"
            )
        }
    }

    private var waitingTitle: String {
        if matchmaking.isPartnerReady {
            return "Both players are ready"
        }

        if matchmaking.isLocalPlayerReady {
            return "You are ready"
        }

        return "Preparing shared round"
    }

    private var waitingSubtitle: String {
        if let scheduledStartAt = matchmaking.scheduledStartAt {
            return "CloudKit synced the round. Countdown begins at \(scheduledStartAt.formatted(date: .omitted, time: .standard))."
        }

        if matchmaking.isLocalPlayerReady {
            return "Waiting for \(matchmaking.partnerDisplayName) to join this round from the shared CloudKit session."
        }

        return "Creating a shared Word Search session in iCloud and reserving the next puzzle for both players."
    }

    private var startSummary: String? {
        guard let scheduledStartAt = matchmaking.scheduledStartAt else {
            return nil
        }

        return "Scheduled start \(scheduledStartAt.formatted(date: .omitted, time: .standard))"
    }

    private func readinessCard(title: String, isReady: Bool, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: isReady ? "checkmark.circle.fill" : "clock.fill")
                .font(.title3)
                .foregroundStyle(isReady ? .pekisMint : .pekisInkSoft)

            Text(title)
                .font(PekisFont.headline())
                .foregroundStyle(.pekisInk)

            Text(detail)
                .font(PekisFont.caption())
                .foregroundStyle(.pekisInkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cozyCard(accent: isReady ? .pekisMint : .pekisInkSoft, cornerRadius: 20)
    }

    private func startCountdown() {
        guard !showCountdown else { return }
        showCountdown = true
        countdownTask?.cancel()
        countdown = max(1, Int(ceil((matchmaking.scheduledStartAt ?? Date().addingTimeInterval(3)).timeIntervalSinceNow)))

        countdownTask = Task { @MainActor in
            let targetDate = matchmaking.scheduledStartAt ?? Date().addingTimeInterval(3)
            var lastDisplayedTick: Int?

            while !Task.isCancelled {
                let remainingSeconds = max(0, Int(ceil(targetDate.timeIntervalSinceNow)))

                if remainingSeconds > 0, remainingSeconds != lastDisplayedTick {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        countdown = remainingSeconds
                    }
                    HapticManager.selection()
                    lastDisplayedTick = remainingSeconds
                }

                if remainingSeconds == 0 {
                    break
                }

                try? await Task.sleep(nanoseconds: 100_000_000)
            }

            guard !Task.isCancelled else { return }

            withAnimation {
                matchmaking.startGame()
                viewModel.startGame(seed: matchmaking.sessionSeed)
                showCountdown = false
            }
        }
    }
}
