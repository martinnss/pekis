import SwiftUI

struct ThisOrThatView: View {
    @StateObject private var viewModel: ThisOrThatViewModel
    let onExit: () -> Void

    init(cloudKitService: any CloudKitServiceProtocol, onExit: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ThisOrThatViewModel(cloudKitService: cloudKitService))
        self.onExit = onExit
    }

    var body: some View {
        VStack(spacing: 24) {
            header

            if viewModel.isLoading {
                Spacer()
                ProgressView().tint(.pekisPurple)
                Spacer()
            } else {
                Spacer()
                questionContent
                Spacer()
                bottomButtons
            }
        }
        .onAppear {
            Task { await viewModel.loadAnswers() }
        }
    }

    private var questionContent: some View {
        VStack(spacing: 16) {
            preferenceButton(index: 0)

            Text("OR")
                .font(PekisFont.headline())
                .foregroundStyle(.pekisInkSoft)
                .padding(.vertical, 2)

            preferenceButton(index: 1)

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
                VStack(spacing: 12) {
                    PekiMascot(mood: viewModel.isMatch ? .love : .happy, tint: viewModel.isMatch ? .pekisBerry : .pekisSun, size: 72)
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.isMatch ? "heart.fill" : "sparkles")
                            .foregroundStyle(viewModel.isMatch ? .pekisBerry : .pekisSun)
                        Text(viewModel.isMatch ? "You both chose the same!" : "Different choices!")
                            .font(PekisFont.headline())
                            .foregroundStyle(.pekisInk)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        (viewModel.isMatch ? Color.pekisBerry : Color.pekisSun).opacity(0.16),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    withAnimation(.spring()) { viewModel.revealPartnerAnswer() }
                } label: {
                    Label("Reveal Partner's Choice", systemImage: "eye.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SquishyButtonStyle(tint: .pekisPurple))
            }
        }
        .padding(.top, 12)
    }

    private var waitingForPartnerSection: some View {
        HStack(spacing: 8) {
            ProgressView().tint(.pekisPurple)
            Text("Waiting for partner…")
                .font(PekisFont.body())
                .foregroundStyle(.pekisInkSoft)
        }
        .padding()
        .background(Color.pekisSurfaceSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.top, 12)
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
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                Spacer()
                HStack(spacing: 8) {
                    if isMyChoice {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.pekisMint)
                    }
                    if isPartnerChoice {
                        Image(systemName: "heart.circle.fill").foregroundStyle(.pekisBerry)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundStyle(isMyChoice ? .white : .pekisInk)
            .background(
                (isMyChoice ? Color.pekisPurple : Color.pekisSurface),
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        isPartnerChoice ? Color.pekisBerry : Color.pekisHairline,
                        lineWidth: isPartnerChoice ? 3 : 1
                    )
            )
            .shadow(color: (isMyChoice ? Color.pekisPurple : Color.pekisInk).opacity(0.12), radius: 10, y: 6)
        }
        .disabled(viewModel.selectedOption != nil)
    }

    private var bottomButtons: some View {
        Button(action: viewModel.nextPair) {
            Label("Next Question", systemImage: "arrow.right")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(SquishyButtonStyle(tint: .pekisPurple))
    }

    private var header: some View {
        CozyHeader(title: "This or That", tint: .pekisPurple, onHome: onExit) {
            Text("\(viewModel.currentIndex + 1)/\(AppContent.thisOrThatPairs.count)")
                .cozyChip(.pekisPurple)
        }
    }
}

#if DEBUG
#Preview {
    ZStack {
        CozyBackground()
        ThisOrThatView(cloudKitService: MockCloudKitService(), onExit: {}).padding()
    }
}
#endif
