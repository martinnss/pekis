import SwiftUI

struct DateRouletteView: View {
    @StateObject private var viewModel = DateRouletteViewModel()
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            header
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .frame(width: 320, height: 320)
                    .shadow(color: Color.pekisPurple.opacity(0.4), radius: 30, y: 16)
                Text(viewModel.currentIdea)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(width: 280)
                    .blur(radius: viewModel.isSpinning ? 3 : 0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isSpinning)
            }
            Spacer()
            Button(action: {
                HapticManager.selection()
                viewModel.spin()
            }) {
                Label(viewModel.isSpinning ? "Spinning..." : "Spin the Wheel", systemImage: "die.face.5")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CapsuleButtonStyle(background: Color.pekisPurple, foreground: .white))
            .disabled(viewModel.isSpinning)
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
            Text("Date Roulette")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
    }
}

#Preview {
    DateRouletteView(onExit: {})
}
