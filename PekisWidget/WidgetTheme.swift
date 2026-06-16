import SwiftUI

/// A hand-tuned colour palette for the countdown widget. Each theme is built
/// from a small set of stops so the background, glow and accent always feel
/// like they belong to one another rather than a random gradient.
struct WidgetTheme {
    let gradient: [Color]
    let glow: Color
    let accent: Color
    let ringTrack: Color

    var primaryText: Color { .white }
    var secondaryText: Color { .white.opacity(0.72) }

    /// Background built in layers: a diagonal base gradient, a soft radial
    /// highlight in the top-trailing corner (echoing the app's blob motif),
    /// and a gentle bottom vignette for depth.
    var background: some View {
        ZStack {
            LinearGradient(
                colors: gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [glow.opacity(0.55), .clear],
                center: UnitPoint(x: 0.85, y: 0.12),
                startRadius: 0,
                endRadius: 190
            )
            .blendMode(.screen)

            LinearGradient(
                colors: [.clear, .black.opacity(0.28)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
    }
}

extension WidgetTheme {
    static func palette(for style: CountdownTheme) -> WidgetTheme {
        switch style {
        case .aurora:
            return WidgetTheme(
                gradient: [
                    Color(red: 0.27, green: 0.13, blue: 0.55),
                    Color(red: 0.51, green: 0.15, blue: 0.92),
                    Color(red: 0.78, green: 0.27, blue: 0.85)
                ],
                glow: Color(red: 0.45, green: 0.95, blue: 0.82),
                accent: Color(red: 0.62, green: 1.0, blue: 0.90),
                ringTrack: .white.opacity(0.18)
            )
        case .sunset:
            return WidgetTheme(
                gradient: [
                    Color(red: 0.36, green: 0.11, blue: 0.35),
                    Color(red: 0.85, green: 0.28, blue: 0.42),
                    Color(red: 0.98, green: 0.58, blue: 0.34)
                ],
                glow: Color(red: 1.0, green: 0.82, blue: 0.52),
                accent: Color(red: 1.0, green: 0.86, blue: 0.62),
                ringTrack: .white.opacity(0.20)
            )
        case .rose:
            return WidgetTheme(
                gradient: [
                    Color(red: 0.45, green: 0.10, blue: 0.27),
                    Color(red: 0.82, green: 0.24, blue: 0.45),
                    Color(red: 0.98, green: 0.55, blue: 0.66)
                ],
                glow: Color(red: 1.0, green: 0.78, blue: 0.86),
                accent: Color(red: 1.0, green: 0.83, blue: 0.89),
                ringTrack: .white.opacity(0.20)
            )
        case .midnight:
            return WidgetTheme(
                gradient: [
                    Color(red: 0.05, green: 0.03, blue: 0.13),
                    Color(red: 0.13, green: 0.07, blue: 0.30),
                    Color(red: 0.32, green: 0.15, blue: 0.58)
                ],
                glow: Color(red: 0.51, green: 0.15, blue: 0.92),
                accent: Color(red: 0.74, green: 0.55, blue: 1.0),
                ringTrack: .white.opacity(0.16)
            )
        case .ocean:
            return WidgetTheme(
                gradient: [
                    Color(red: 0.04, green: 0.20, blue: 0.36),
                    Color(red: 0.08, green: 0.42, blue: 0.58),
                    Color(red: 0.27, green: 0.70, blue: 0.74)
                ],
                glow: Color(red: 0.52, green: 0.93, blue: 0.88),
                accent: Color(red: 0.66, green: 0.96, blue: 0.92),
                ringTrack: .white.opacity(0.18)
            )
        }
    }
}
