import SwiftUI

struct TopicGeneratorView: View {
    @StateObject private var viewModel = TopicGeneratorViewModel()
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            CozyHeader(title: "Deep Talk", tint: .pekisSky, onHome: onExit)

            Spacer()

            ZStack {
                VStack(spacing: 18) {
                    PekiMascot(mood: .happy, tint: .pekisSky, size: 86)
                    Text(viewModel.currentTopic.isEmpty ? "Loading…" : "\u{201C}\(viewModel.currentTopic)\u{201D}")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.pekisInk)
                        .padding(.horizontal)
                        .opacity(viewModel.isAnimating ? 0.3 : 1)
                        .scaleEffect(viewModel.isAnimating ? 0.95 : 1)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isAnimating)
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .frame(height: 340)
                .cozyCard(accent: .pekisSky, cornerRadius: 32)
            }

            Spacer()

            Button {
                HapticManager.selection()
                Task { await viewModel.generateTopic() }
            } label: {
                Label("New Topic", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SquishyButtonStyle(tint: .pekisSky))
            .disabled(viewModel.isAnimating)

            Text("Ask each other and listen closely ❤️")
                .font(PekisFont.caption())
                .foregroundStyle(.pekisInkSoft)
        }
    }
}

#Preview {
    ZStack {
        CozyBackground()
        TopicGeneratorView(onExit: {}).padding()
    }
}
