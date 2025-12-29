import SwiftUI

struct TopicGeneratorView: View {
    @StateObject private var viewModel = TopicGeneratorViewModel()
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            header
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
                    .shadow(color: Color.pekisPurple.opacity(0.3), radius: 24, y: 12)
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.pekisLightPurple)
                    Text(viewModel.currentTopic.isEmpty ? "Loading..." : "\"\(viewModel.currentTopic)\"")
                        .font(.title2.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                        .padding(.horizontal)
                        .opacity(viewModel.isAnimating ? 0.3 : 1)
                        .scaleEffect(viewModel.isAnimating ? 0.95 : 1)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isAnimating)
                }
            }
            Spacer()
            Button {
                HapticManager.selection()
                Task { await viewModel.generateTopic() }
            } label: {
                Label("New Topic", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CapsuleButtonStyle(background: Color.pekisPurple, foreground: .white))
            .disabled(viewModel.isAnimating)
            Text("Ask each other and listen closely ❤️")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var header: some View {
        HStack {
            Button(action: {
                HapticManager.selection()
                onExit()
            }) {
                Image(systemName: "house.fill")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.white.opacity(0.1))
                    .clipShape(Circle())
            }
            Spacer()
            Text("Deep Talk")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
    }
}

#Preview {
    TopicGeneratorView(onExit: {})
}
