import SwiftUI
import UIKit

struct WordSearchResultView: View {
    let score: Int
    let onRestart: () -> Void
    let onExit: () -> Void

    @State private var animateContent = false

    private var isWin: Bool { score >= 4 }
    private var accent: Color { isWin ? .pekisMint : .pekisSun }

    var body: some View {
        ZStack {
            ConfettiView(trigger: animateContent && score == 6)

            VStack(spacing: 28) {
                Spacer()

                PekiMascot(mood: isWin ? .celebrate : .happy, tint: accent, size: 96)

                ZStack {
                    Circle()
                        .fill(Color.pekisSurface)
                        .frame(width: 190, height: 190)
                        .shadow(color: accent.opacity(0.25), radius: 18, y: 10)

                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 6.0)
                        .stroke(accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 190, height: 190)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(score)")
                            .font(.system(size: 72, weight: .black, design: .rounded))
                            .foregroundStyle(.pekisInk)
                        Text("of 6 words")
                            .font(PekisFont.body())
                            .foregroundStyle(.pekisInkSoft)
                    }
                }
                .scaleEffect(animateContent ? 1 : 0.8)
                .opacity(animateContent ? 1 : 0)

                VStack(spacing: 10) {
                    Text(titleForScore(score))
                        .font(PekisFont.title())
                        .foregroundStyle(.pekisInk)
                    Text(messageForScore(score))
                        .font(PekisFont.body())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.pekisInkSoft)
                        .padding(.horizontal, 32)
                }
                .offset(y: animateContent ? 0 : 20)
                .opacity(animateContent ? 1 : 0)

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        HapticManager.selection()
                        onRestart()
                    } label: {
                        Label("Play Again", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SquishyButtonStyle(tint: .pekisMint))

                    Button {
                        HapticManager.selection()
                        onExit()
                    } label: {
                        Text("Back").font(PekisFont.headline())
                    }
                    .tint(.pekisInkSoft)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .offset(y: animateContent ? 0 : 20)
                .opacity(animateContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animateContent = true
            }
        }
    }

    private func titleForScore(_ score: Int) -> String {
        switch score {
        case 6: return "Perfect Pekis!"
        case 4...5: return "Great Job Pekis!"
        case 1...3: return "Good Effort Pekis!"
        default: return "Nice Try!"
        }
    }

    private func messageForScore(_ score: Int) -> String {
        switch score {
        case 6: return "You found all the words! Marry me NOW 💍"
        case 4...5: return "You found almost all of them. So close Pekis!"
        case 1...3: return "You found some words. Love you anyway!"
        default: return "Better luck next time — I still love you!"
        }
    }
}

#Preview {
    ZStack {
        CozyBackground()
        WordSearchResultView(score: 6, onRestart: {}, onExit: {})
    }
}
