import SwiftUI

/// Onboarding flow for couple pairing
/// Must be completed before accessing the main app
struct CoupleOnboardingView: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @StateObject private var viewModel = CoupleOnboardingViewModel()

    var body: some View {
        ZStack {
            CozyBackground()

            Group {
                switch viewModel.step {
                case .welcome:
                    WelcomeStepView(viewModel: viewModel)
                case .enterName:
                    EnterNameStepView(viewModel: viewModel)
                case .createOrJoin:
                    CreateOrJoinStepView(viewModel: viewModel)
                case .waitingForPartner:
                    WaitingForPartnerView(viewModel: viewModel)
                case .complete:
                    OnboardingCompleteView()
                }
            }
            .padding(.horizontal, 16)
            .animation(.easeInOut, value: viewModel.step)
        }
        .onAppear {
            viewModel.setCloudKitService(cloudKitService)
        }
        .onChange(of: cloudKitService.needsPartnerName) {
            viewModel.setCloudKitService(cloudKitService)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let url = viewModel.shareURL {
                ShareLinkView(url: url)
            }
        }
    }
}

// MARK: - Welcome Step

private struct WelcomeStepView: View {
    @ObservedObject var viewModel: CoupleOnboardingViewModel

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            PekiDuo(mood: .waving, size: 110)

            VStack(spacing: 12) {
                Text("Welcome to Pekis")
                    .font(PekisFont.bigTitle())
                    .foregroundStyle(.pekisInk)

                Text("Connect with your partner and make every moment count, even from miles away.")
                    .font(PekisFont.body())
                    .foregroundStyle(.pekisInkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 16) {
                Button {
                    withAnimation { viewModel.step = .enterName }
                } label: {
                    Text("Get Started")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SquishyButtonStyle(tint: .pekisPurple))

                Label("Your data stays private in your iCloud", systemImage: "lock.fill")
                    .font(PekisFont.caption())
                    .foregroundStyle(.pekisInkSoft)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Enter Name Step

private struct EnterNameStepView: View {
    @ObservedObject var viewModel: CoupleOnboardingViewModel
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            PekiMascot(mood: .happy, tint: .pekisCoral, size: 110)

            VStack(spacing: 10) {
                Text("What's your name?")
                    .font(PekisFont.title())
                    .foregroundStyle(.pekisInk)

                Text("This is how your partner will see you in the app.")
                    .font(PekisFont.body())
                    .foregroundStyle(.pekisInkSoft)
                    .multilineTextAlignment(.center)
            }

            TextField("Your name", text: $viewModel.userName)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.pekisInk)
                .padding()
                .background(Color.pekisSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.pekisCoral.opacity(0.4), lineWidth: 2)
                )
                .padding(.horizontal, 40)
                .focused($isNameFocused)

            Spacer()

            Button {
                Task { await viewModel.continueFromNameEntry() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView().tint(.white).scaleEffect(0.8)
                    }
                    Text("Continue")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(SquishyButtonStyle(tint: viewModel.userName.isEmpty ? .pekisInkSoft : .pekisPurple))
            .disabled(viewModel.userName.isEmpty || viewModel.isLoading)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear { isNameFocused = true }
    }
}

// MARK: - Create or Join Step

private struct CreateOrJoinStepView: View {
    @ObservedObject var viewModel: CoupleOnboardingViewModel

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            PekiMascot(mood: .idle, tint: .pekisSky, size: 100)

            VStack(spacing: 10) {
                Text("Connect with Partner")
                    .font(PekisFont.title())
                    .foregroundStyle(.pekisInk)

                Text("Create a new couple or join your partner's existing one.")
                    .font(PekisFont.body())
                    .foregroundStyle(.pekisInkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 16) {
                optionCard(
                    icon: "plus.circle.fill",
                    tint: .pekisCoral,
                    title: "Create New Couple",
                    subtitle: "Start fresh and invite your partner"
                ) {
                    Task { await viewModel.createCouple() }
                }
                .disabled(viewModel.isLoading)

                optionCard(
                    icon: "person.2.fill",
                    tint: .pekisMint,
                    title: "Join Partner's Couple",
                    subtitle: "I have an invite link from my partner"
                ) {
                    viewModel.showJoinInstructions = true
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            if viewModel.isLoading {
                ProgressView().tint(.pekisPurple).padding()
            }

            Button {
                withAnimation { viewModel.step = .enterName }
            } label: {
                Text("Back").font(PekisFont.headline())
            }
            .tint(.pekisInkSoft)
            .padding(.bottom, 32)
        }
        .alert("Join Your Partner", isPresented: $viewModel.showJoinInstructions) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("Ask your partner to share their invite link with you. Tap the link to connect.")
        }
    }

    private func optionCard(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                CozyIconBadge(systemName: icon, tint: tint, size: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(PekisFont.headline())
                        .foregroundStyle(.pekisInk)
                    Text(subtitle)
                        .font(PekisFont.caption())
                        .foregroundStyle(.pekisInkSoft)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tint)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .cozyCard(accent: tint)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Waiting for Partner View

private struct WaitingForPartnerView: View {
    @ObservedObject var viewModel: CoupleOnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Invite sent → one Peki waves, hoping the partner appears.
            PekiDuo(mood: .hopeful, size: 100)

            VStack(spacing: 10) {
                Text("Waiting for Partner")
                    .font(PekisFont.title())
                    .foregroundStyle(.pekisInk)

                Text("Share the invite link with your partner. Once they accept, you'll be connected!")
                    .font(PekisFont.body())
                    .foregroundStyle(.pekisInkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Button {
                    viewModel.showShareSheet = true
                } label: {
                    Label("Share Invite Link", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SquishyButtonStyle(tint: .pekisCoral))
                .disabled(viewModel.shareURL == nil)
                .opacity(viewModel.shareURL == nil ? 0.5 : 1)

                if viewModel.shareURL == nil {
                    Button {
                        Task { await viewModel.fetchShareURL() }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                ProgressView().tint(.pekisPurple).scaleEffect(0.8)
                            }
                            Label("Get Link", systemImage: "arrow.clockwise")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CapsuleButtonStyle(background: .pekisSurfaceSoft, foreground: .pekisInk))
                    .disabled(viewModel.isLoading)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                Task { await viewModel.checkPartnerJoined() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView().tint(.pekisPurple).scaleEffect(0.8)
                    }
                    Text("Check Connection")
                }
                .font(PekisFont.headline())
            }
            .tint(.pekisPurple)
            .disabled(viewModel.isLoading)
            .padding(.bottom, 16)

            Button {
                withAnimation { viewModel.step = .createOrJoin }
            } label: {
                Text("Back").font(PekisFont.body())
            }
            .tint(.pekisInkSoft)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Complete View

private struct OnboardingCompleteView: View {
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            ConfettiView(trigger: showConfetti)

            VStack(spacing: 28) {
                Spacer()

                // The payoff: the two Pekis are now engaged 💍
                PekiDuo(mood: .engaged, size: 120)
                    .scaleEffect(showConfetti ? 1.0 : 0.6)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showConfetti)

                VStack(spacing: 12) {
                    Text("You're Connected! 💕")
                        .font(PekisFont.bigTitle())
                        .foregroundStyle(.pekisInk)

                    Text("Your Pekis journey together begins now.")
                        .font(PekisFont.body())
                        .foregroundStyle(.pekisInkSoft)
                }

                Spacer()
            }
        }
        .onAppear {
            HapticManager.notification(type: .success)
            showConfetti = true
        }
    }
}

// MARK: - Preview

#Preview {
    CoupleOnboardingView()
        .environmentObject(CloudKitService())
}
