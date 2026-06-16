import SwiftUI

/// Chunky "candy" capsule button — a rounded pill with a darker bottom lip that
/// gives a tactile 3D press, squishing down on tap with a spring + haptic.
/// Signature kept (`background`/`foreground`/`borderColor`) so existing call
/// sites upgrade to the cozy look automatically.
struct CapsuleButtonStyle: ButtonStyle {
    var background: Color
    var foreground: Color
    var borderColor: Color = .clear

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .foregroundStyle(foreground)
            .padding(.horizontal, 24)
            .padding(.vertical, 15)
            .background(
                ZStack {
                    // Bottom lip (the "3D" base) — a darkened copy peeking below.
                    Capsule()
                        .fill(background.darker(0.18))
                        .offset(y: pressed ? 2 : 5)
                    Capsule()
                        .fill(background)
                }
            )
            .overlay(
                Capsule().stroke(borderColor.opacity(0.7), lineWidth: borderColor == .clear ? 0 : 2)
            )
            .clipShape(Capsule())
            .offset(y: pressed ? 3 : 0)
            .scaleEffect(pressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: pressed)
            .onChange(of: pressed) { isPressed in
                if isPressed { HapticManager.impact(style: .medium) }
            }
    }
}

/// A primary squishy button taking a single tint (white text on a colored pill).
struct SquishyButtonStyle: ButtonStyle {
    var tint: Color = .pekisCoral
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        CapsuleButtonStyle(background: tint, foreground: foreground)
            .makeBody(configuration: configuration)
    }
}

extension Color {
    /// Darken by blending toward black — used for button "lip" depth.
    func darker(_ amount: Double) -> Color {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let f = CGFloat(1 - amount)
        return Color(red: Double(r * f), green: Double(g * f), blue: Double(b * f), opacity: Double(a))
    }
}
