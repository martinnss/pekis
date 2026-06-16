import SwiftUI

struct DateRouletteView: View {
    @StateObject private var viewModel = DateRouletteViewModel()
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            CozyHeader(title: "Date Roulette", tint: .pekisSun, onHome: onExit)

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.pekisSurface)
                    .overlay(
                        Circle().stroke(
                            AngularGradient(
                                colors: [.pekisCoral, .pekisSun, .pekisMint, .pekisSky, .pekisBerry, .pekisCoral],
                                center: .center
                            ),
                            lineWidth: 8
                        )
                    )
                    .frame(width: 300, height: 300)
                    .shadow(color: Color.pekisSun.opacity(0.35), radius: 24, y: 14)
                    .rotationEffect(.degrees(viewModel.isSpinning ? 360 : 0))
                    .animation(
                        viewModel.isSpinning ? .easeInOut(duration: 0.8) : .default,
                        value: viewModel.isSpinning
                    )

                Text(viewModel.currentIdea)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.pekisInk)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(width: 240)
                    .blur(radius: viewModel.isSpinning ? 3 : 0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isSpinning)
            }

            Spacer()

            Button {
                HapticManager.selection()
                viewModel.spin()
            } label: {
                Label(viewModel.isSpinning ? "Spinning…" : "Spin the Wheel", systemImage: "die.face.5.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SquishyButtonStyle(tint: .pekisSun, foreground: .pekisInk))
            .disabled(viewModel.isSpinning)
        }
    }
}

#Preview {
    ZStack {
        CozyBackground()
        DateRouletteView(onExit: {}).padding()
    }
}
