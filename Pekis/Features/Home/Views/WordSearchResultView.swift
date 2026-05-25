import SwiftUI
import UIKit

struct WordSearchResultView: View {
    let score: Int
    let onRestart: () -> Void
    let onExit: () -> Void

    @State private var animateContent = false

    var body: some View {
        VStack(spacing: 32) {
                Spacer()

                // Score Circle
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 200, height: 200)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )

                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 6.0)
                        .stroke(
                            LinearGradient(
                                colors: [.pekisLightPurple, .pekisPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: .pekisPurple.opacity(0.5), radius: 10)

                    VStack(spacing: 4) {
                        Text("\(score)")
                            .font(.system(size: 80, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("of 6 words")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .scaleEffect(animateContent ? 1 : 0.8)
                .opacity(animateContent ? 1 : 0)

                // Text Content
                VStack(spacing: 12) {
                    Text(titleForScore(score))
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text(messageForScore(score))
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 32)
                }
                .offset(y: animateContent ? 0 : 20)
                .opacity(animateContent ? 1 : 0)

                Spacer()

                // Actions
                VStack(spacing: 16) {
                    Button(action: {
                        HapticManager.selection()
                        onRestart()
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Play Again🤍")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.pekisPurple)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .pekisPurple.opacity(0.4), radius: 10, y: 5)
                    }

                    Button(action: {
                        HapticManager.selection()
                        onExit()
                    }) {
                        Text("Back")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .offset(y: animateContent ? 0 : 20)
                .opacity(animateContent ? 1 : 0)
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
        default: return "Nice Try Loser!"
        }
    }

    private func messageForScore(_ score: Int) -> String {
        switch score {
        case 6: return "You found all the words! Marry me NOW"
        case 4...5: return "You found almost all of them. So close Pekis!"
        case 1...3: return "You found some words. Love you anyway!"
        default: return "Looser! But I still love you!"
        }
    }
}

#Preview {
    WordSearchResultView(score: 5, onRestart: {}, onExit: {})
}
