import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: HomeViewModel
    let onWordSearch: () -> Void
    let onTopics: () -> Void
    let onDateRoulette: () -> Void
    let onThisOrThat: () -> Void
    let onLoveNote: () -> Void

    @State private var selectedReunionDate = Date()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                header
                countdownCard
                Text("What to Do?")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 8)
                activityGrid
            }
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $viewModel.isEditingReunionDate) {
            reunionDatePicker
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 12) {
                Image("DashboardCouple")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pekis")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    if let partnerName = viewModel.couple?.partnerBName ?? viewModel.couple?.partnerAName {
                        Text("with \(partnerName)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            Spacer()
            Text("❤️")
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
                .background(Color.pekisPurple.opacity(0.3))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.pekisLightPurple.opacity(0.5), lineWidth: 1)
                )
        }
    }

    private var countdownCard: some View {
        Button {
            selectedReunionDate = viewModel.couple?.reunionDate ?? Date()
            viewModel.isEditingReunionDate = true
        } label: {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.pekisPurple, Color.pekisLightPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Next Visit")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.8))
                                .textCase(.uppercase)
                            Text(viewModel.visitDateText)
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                            if !viewModel.hasReunionDate {
                                Text("Tap to set")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        Spacer()
                        if viewModel.hasReunionDate {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(viewModel.daysUntilVisit)")
                                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                Text("days")
                                    .font(.headline)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        } else {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 40))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .padding(24)
                )
                .frame(height: 140)
                .shadow(color: Color.pekisPurple.opacity(0.4), radius: 20, x: 0, y: 10)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var reunionDatePicker: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("When's your next visit?")
                    .font(.title2.bold())
                    .padding(.top)

                DatePicker(
                    "Reunion Date",
                    selection: $selectedReunionDate,
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()

                Button {
                    Task {
                        await viewModel.updateReunionDate(selectedReunionDate)
                    }
                } label: {
                    Text("Save Date")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        viewModel.isEditingReunionDate = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var activityGrid: some View {
        VStack(spacing: 16) {
            activityCard(
                title: "Couples Word Search",
                icon: "arrow.triangle.2.circlepath",
                accent: .white,
                action: onWordSearch
            )

            activityCard(
                title: "Deep Talk Topics",
                icon: "text.bubble.fill",
                accent: .white,
                action: onTopics
            )

            activityCard(
                title: "Date Roulette",
                icon: "die.face.5",
                accent: .white,
                action: onDateRoulette
            )

            activityCard(
                title: "This or That",
                icon: "arrow.left.arrow.right",
                accent: .white,
                action: onThisOrThat
            )

            activityCard(
                title: "Love Notes",
                icon: "heart.text.square.fill",
                accent: .white,
                badge: "New",
                action: onLoveNote
            )
        }
    }

    private func activityCard(
        title: String,
        icon: String,
        accent: Color,
        badge: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            HapticManager.selection()
            action()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(Color.pekisLightPurple)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.white)
                        if let badge {
                            Text(badge)
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.pekisPurple)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
