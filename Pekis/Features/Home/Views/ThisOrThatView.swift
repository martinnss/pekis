import SwiftUI

struct ThisOrThatView: View {
    @StateObject private var viewModel: ThisOrThatViewModel
    let onExit: () -> Void

    init(cloudKitService: CloudKitService, onExit: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ThisOrThatViewModel(cloudKitService: cloudKitService))
        self.onExit = onExit
    }

    var body: some View {
        VStack(spacing: 24) {
            header

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .tint(.white)
                Spacer()
            } else {
                Spacer()
                questionContent
                Spacer()
                bottomButtons
            }
        }
        .onAppear {
            Task {
                await viewModel.loadAnswers()
            }
        }
    }

    private var questionContent: some View {
        VStack(spacing: 16) {
            preferenceButton(index: 0)

            Text("OR")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))

            preferenceButton(index: 1)

            // Partner's answer reveal
            if viewModel.selectedOption != nil && viewModel.partnerAnswer != nil {
                partnerRevealSection
            } else if viewModel.selectedOption != nil && viewModel.partnerAnswer == nil {
                waitingForPartnerSection
            }
        }
    }

    private var partnerRevealSection: some View {
        VStack(spacing: 12) {
            if viewModel.showReveal {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isMatch ? "heart.fill" : "heart")
                        .foregroundStyle(viewModel.isMatch ? .green : .orange)
                    Text(viewModel.isMatch ? "You both chose the same!" : "Different choices!")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .padding()
                .background(viewModel.isMatch ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    withAnimation(.spring()) {
                        viewModel.revealPartnerAnswer()
                    }
                } label: {
                    Label("Reveal Partner's Choice", systemImage: "eye.fill")
                        .font(.headline)
                        .padding()
                        .background(Color.indigo.opacity(0.5))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .padding(.top, 16)
    }

    private var waitingForPartnerSection: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.white)
            Text("Waiting for partner...")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.top, 16)
    }

    private func preferenceButton(index: Int) -> some View {
        let isMyChoice = viewModel.selectedOption == index
        let isPartnerChoice = viewModel.showReveal && viewModel.partnerAnswer == index
        let title = viewModel.currentPair.indices.contains(index) ? viewModel.currentPair[index] : ""

        return Button {
            if viewModel.selectedOption == nil {
                viewModel.select(option: index)
                HapticManager.impact(style: .medium)
            }
        } label: {
            HStack {
                Text(title)
                    .font(.title3.weight(.bold))
                Spacer()

                HStack(spacing: 8) {
                    if isMyChoice {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    if isPartnerChoice {
                        Image(systemName: "heart.circle.fill")
                            .foregroundStyle(.pink)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isMyChoice ? Color.white : Color.white.opacity(0.1))
            .foregroundStyle(isMyChoice ? Color.purple : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        isPartnerChoice ? Color.pink : Color.white.opacity(0.3),
                        lineWidth: isPartnerChoice ? 3 : 1
                    )
            )
        }
        .disabled(viewModel.selectedOption != nil)
    }

    private var bottomButtons: some View {
        Button(action: viewModel.nextPair) {
            Label("Next Question", systemImage: "arrow.right")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(CapsuleButtonStyle(background: .indigo, foreground: .white))
    }

    private var header: some View {
        HStack {
            Button(action: onExit) {
                Image(systemName: "house.fill")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.white.opacity(0.2))
                    .clipShape(Circle())
            }
            Spacer()
            Text("This or That")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Spacer()
            // Progress indicator
            Text("\(viewModel.currentIndex + 1)/\(AppContent.thisOrThatPairs.count)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.white.opacity(0.2))
                .clipShape(Capsule())
        }
    }
}

#Preview {
    ThisOrThatView(cloudKitService: CloudKitService(), onExit: {})
}
