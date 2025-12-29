import SwiftUI

struct CapsuleButtonStyle: ButtonStyle {
    var background: Color
    var foreground: Color
    var borderColor: Color = .clear

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                background
                    .opacity(configuration.isPressed ? 0.9 : 1.0)
                    .shadow(color: background.opacity(0.5), radius: configuration.isPressed ? 4 : 10, x: 0, y: configuration.isPressed ? 2 : 5)
            )
            .overlay(
                Capsule()
                    .stroke(borderColor.opacity(0.6), lineWidth: borderColor == .clear ? 0 : 2)
            )
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    HapticManager.impact(style: .heavy)
                }
            }
    }
}
