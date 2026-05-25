import SwiftUI

/// Onboarding flow for couple pairing
/// Must be completed before accessing the main app
struct CoupleOnboardingView: View {
    @EnvironmentObject var cloudKitService: CloudKitService
    @StateObject private var viewModel = CoupleOnboardingViewModel()

    var body: some View {
        ZStack {
            Color.pekisBackground.ignoresSafeArea()

            // Ambient background blobs
            BackgroundBlobsView()

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
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pekisLightPurple, .pekisPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .pekisPurple.opacity(0.5), radius: 20)

            VStack(spacing: 12) {
                Text("Welcome to Pekis")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Connect with your partner and make every moment count, even from miles away.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 16) {
                Button {
                    withAnimation {
                        viewModel.step = .enterName
                    }
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.pekisPurple, Color.pekisLightPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Text("Your data stays private in your iCloud account")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
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
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.pekisLightPurple)

                Text("What's your name?")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text("This is how your partner will see you in the app.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }

            TextField("Your name", text: $viewModel.userName)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.white.opacity(0.1))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.pekisLightPurple.opacity(0.5), lineWidth: 1)
                )
                .padding(.horizontal, 48)
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
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    Group {
                        if viewModel.userName.isEmpty {
                            Color.white.opacity(0.2)
                        } else {
                            LinearGradient(
                                colors: [Color.pekisPurple, Color.pekisLightPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(viewModel.userName.isEmpty || viewModel.isLoading)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            isNameFocused = true
        }
    }
}

// MARK: - Create or Join Step

private struct CreateOrJoinStepView: View {
    @ObservedObject var viewModel: CoupleOnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.pekisLightPurple)

                Text("Connect with Partner")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text("Create a new couple or join your partner's existing one.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 16) {
                // Create New Couple
                Button {
                    Task {
                        await viewModel.createCouple()
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Create New Couple")
                                .font(.headline)
                            Text("Start fresh and invite your partner")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.pekisPurple, Color.pekisLightPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(viewModel.isLoading)

                // Join Partner
                Button {
                    viewModel.showJoinInstructions = true
                } label: {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Join Partner's Couple")
                                .font(.headline)
                            Text("I have an invite link from my partner")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.1))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            if viewModel.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding()
            }

            Button {
                withAnimation {
                    viewModel.step = .enterName
                }
            } label: {
                Text("Back")
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.bottom, 32)
        }
        .alert("Join Your Partner", isPresented: $viewModel.showJoinInstructions) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text("Ask your partner to share their invite link with you. Tap the link to connect.")
        }
    }
}

// MARK: - Waiting for Partner View

private struct WaitingForPartnerView: View {
    @ObservedObject var viewModel: CoupleOnboardingViewModel
    @State private var animationAmount = 1.0
    @State private var showCopiedToast = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(lineWidth: 4)
                    .foregroundStyle(Color.pekisLightPurple.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animationAmount)
                    .opacity(2 - animationAmount)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                        value: animationAmount
                    )

                Image(systemName: "heart.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.pekisLightPurple)
            }
            .onAppear {
                animationAmount = 2
            }

            VStack(spacing: 12) {
                Text("Waiting for Partner")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text("Share the invite link with your partner. Once they accept, you'll be connected!")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                // Share button
                Button {
                    viewModel.showShareSheet = true
                } label: {
                    Label("Share Invite Link", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.pekisPurple, Color.pekisLightPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(viewModel.shareURL == nil)
                .opacity(viewModel.shareURL == nil ? 0.5 : 1)

                // Retry getting link if not available
                if viewModel.shareURL == nil {
                    Button {
                        Task {
                            await viewModel.fetchShareURL()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            }
                            Label("Get Link", systemImage: "arrow.clockwise")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                Task {
                    await viewModel.checkPartnerJoined()
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Color.pekisLightPurple)
                            .scaleEffect(0.8)
                    }
                    Text("Check Connection")
                }
                .foregroundStyle(Color.pekisLightPurple)
            }
            .disabled(viewModel.isLoading)
            .padding(.bottom, 32)

            Button {
                withAnimation {
                    viewModel.step = .createOrJoin
                }
            } label: {
                Text("Back")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.bottom, 8)
        }
        .animation(.easeInOut, value: showCopiedToast)
    }
}

// MARK: - Complete View

private struct OnboardingCompleteView: View {
    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(Color.pekisLightPurple)
                .scaleEffect(showConfetti ? 1.0 : 0.5)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)

            VStack(spacing: 12) {
                Text("You're Connected! 💕")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)

                Text("Your Pekis journey together begins now.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
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
