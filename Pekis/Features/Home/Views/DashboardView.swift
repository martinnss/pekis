import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject private var cloudKitService: CloudKitService
    let onWordSearch: () -> Void
    let onTopics: () -> Void
    let onDateRoulette: () -> Void
    let onThisOrThat: () -> Void
    let onLoveNote: () -> Void
    let onMomentShare: () -> Void

    @State private var selectedReunionDate = Date()
    @State private var didCopyInvite = false
    @State private var showSettings = false

    private var mascotMood: MascotMood {
        if !viewModel.isPaired { return .hopeful }
        if viewModel.hasReunionDate && viewModel.daysUntilVisit <= 7 { return .celebrate }
        return .happy
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                mascotHero
                if !viewModel.isPaired {
                    waitingForPartnerView
                }
                countdownCard
                Text("What to Do?")
                    .font(PekisFont.title())
                    .foregroundStyle(.pekisInk)
                    .padding(.top, 4)
                activityGrid
            }
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $viewModel.isEditingReunionDate) {
            reunionDatePicker
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(cloudKitService)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pekis")
                    .font(PekisFont.bigTitle())
                    .foregroundStyle(.pekisPurple)
                Text("with \(viewModel.partnerName)")
                    .font(PekisFont.caption())
                    .foregroundStyle(.pekisInkSoft)
            }
            Spacer()
            Button {
                HapticManager.impact(style: .light)
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.pekisInkSoft)
                    .padding(12)
                    .background(Color.pekisSurface, in: Circle())
                    .overlay(Circle().stroke(Color.pekisHairline, lineWidth: 1))
            }
            .accessibilityLabel("Settings")
        }
    }

    // MARK: - Mascot hero

    private var mascotLine: String {
        if !viewModel.isPaired { return "Invite your partner to start! 💜" }
        guard viewModel.hasReunionDate else { return "Set a date to start our countdown!" }
        switch viewModel.daysUntilVisit {
        case 0: return "Today's the day! 🎉"
        case 1: return "Just 1 sleep to go! 💜"
        default: return "\(viewModel.daysUntilVisit) days till we're together! 💜"
        }
    }

    private var mascotHero: some View {
        VStack(spacing: 10) {
            PekiSpeechBubble(text: mascotLine)
            PekiDuo(mood: mascotMood, size: 78)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    // MARK: - Waiting for partner

    private var waitingForPartnerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                CozyIconBadge(systemName: "hourglass", tint: .pekisSun, size: 40)
                Text("Waiting for Partner")
                    .font(PekisFont.headline())
                    .foregroundStyle(.pekisInk)
                Spacer()
            }

            Text("Your partner hasn't joined yet. Share the invite link so you can start using Pekis together!")
                .font(PekisFont.body())
                .foregroundStyle(.pekisInkSoft)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                if viewModel.canCopyInvite {
                    copyInvite()
                } else {
                    Task { await viewModel.fetchShareURL() }
                }
            } label: {
                HStack {
                    if viewModel.isLoadingShare {
                        ProgressView().tint(.white)
                        Text("Preparing link…")
                    } else if didCopyInvite {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Copied!")
                    } else if viewModel.canCopyInvite {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copy Invite Link")
                    } else {
                        Image(systemName: "arrow.clockwise")
                        Text("Get Invite Link")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(SquishyButtonStyle(tint: .pekisCoral))
            .disabled(viewModel.isLoadingShare)
            .animation(.easeInOut(duration: 0.2), value: didCopyInvite)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isLoadingShare)
            .animation(.easeInOut(duration: 0.2), value: viewModel.canCopyInvite)
        }
        .padding(20)
        .cozyCard(accent: .pekisCoral)
        .onAppear {
            Task { await viewModel.fetchShareURL() }
        }
    }

    private func copyInvite() {
        let message = viewModel.inviteMessage
        guard !message.isEmpty else { return }
        UIPasteboard.general.string = message
        HapticManager.notification(type: .success)
        withAnimation { didCopyInvite = true }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation { didCopyInvite = false }
        }
    }

    // MARK: - Countdown

    private var countdownCard: some View {
        Button {
            HapticManager.impact(style: .light)
            selectedReunionDate = viewModel.couple?.reunionDate ?? Date()
            viewModel.isEditingReunionDate = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NEXT VISIT")
                        .font(PekisFont.caption())
                        .foregroundStyle(.white.opacity(0.85))
                    Text(viewModel.visitDateText)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    if !viewModel.hasReunionDate {
                        Text("Tap to set")
                            .font(PekisFont.caption())
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                Spacer()
                if viewModel.hasReunionDate {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(viewModel.daysUntilVisit)")
                            .font(.system(size: 50, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        Text("days")
                            .font(PekisFont.headline())
                            .foregroundStyle(.white.opacity(0.95))
                    }
                } else {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(24)
            .frame(height: 130)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [.pekisPurple, .pekisBerry],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
            .shadow(color: Color.pekisPurple.opacity(0.4), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var reunionDatePicker: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Text("When's your next visit?")
                            .font(PekisFont.title())
                            .foregroundStyle(.pekisInk)
                            .multilineTextAlignment(.center)
                            .padding(.top)

                        DatePicker(
                            "Reunion Date",
                            selection: $selectedReunionDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .tint(.pekisCoral)
                        .environment(\.colorScheme, .light)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 16)
                }

                Button {
                    Task { await viewModel.updateReunionDate(selectedReunionDate) }
                } label: {
                    Text("Save Date").frame(maxWidth: .infinity)
                }
                .buttonStyle(SquishyButtonStyle(tint: .pekisCoral))
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color.pekisCream.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { viewModel.isEditingReunionDate = false }
                        .foregroundStyle(.pekisInk)
                }
            }
        }
        .environment(\.colorScheme, .light)
        .presentationDetents([.large])
        .alert(
            "Couldn't Save",
            isPresented: Binding(
                get: { viewModel.saveErrorMessage != nil },
                set: { if !$0 { viewModel.saveErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.saveErrorMessage = nil }
        } message: {
            Text(viewModel.saveErrorMessage ?? "")
        }
    }

    // MARK: - Activity grid

    private var activityGrid: some View {
        VStack(spacing: 14) {
            activityCard(title: "Couples Word Search", icon: "puzzlepiece.fill", activity: .wordSearch, action: onWordSearch)
            activityCard(title: "Deep Talk Topics", icon: "text.bubble.fill", activity: .topics, action: onTopics)
            activityCard(title: "Date Roulette", icon: "die.face.5.fill", activity: .dateRoulette, action: onDateRoulette)
            activityCard(title: "This or That", icon: "arrow.left.arrow.right", activity: .thisOrThat, action: onThisOrThat)
            activityCard(title: "Love Notes", icon: "heart.text.square.fill", activity: .loveNote, action: onLoveNote)
            activityCard(title: "Moment Share", icon: "camera.fill", activity: .momentShare, badge: "New", action: onMomentShare)
        }
    }

    private func activityCard(
        title: String,
        icon: String,
        activity: PekisActivity,
        badge: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        let accent = activity.accent
        return Button(action: {
            HapticManager.selection()
            action()
        }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(accent)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 52, height: 52)
                .shadow(color: accent.opacity(0.4), radius: 6, y: 3)

                HStack(spacing: 8) {
                    Text(title)
                        .font(PekisFont.headline())
                        .foregroundStyle(.pekisInk)
                    if let badge {
                        Text(badge).cozyChip(accent)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(accent, in: Circle())
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    // 3D bottom "lip" — makes each card feel like a physical tile.
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(accent.darker(0.10))
                        .offset(y: 5)
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.pekisSurface)
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(accent.opacity(0.10))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(accent.opacity(0.28), lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
