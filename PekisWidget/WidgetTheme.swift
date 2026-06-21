import SwiftUI

/// Static color palette for the Pekis widget — matches the app's cozy light theme.
enum WidgetPalette {
    static let cream       = Color(red: 1.0,   green: 0.969, blue: 0.937) // #FFF7EF
    static let creamDeep   = Color(red: 0.988, green: 0.922, blue: 0.851) // #FCEBDA
    static let ink         = Color(red: 0.29,  green: 0.233, blue: 0.271) // #4A3B45
    static let inkSoft     = Color(red: 0.604, green: 0.541, blue: 0.573) // #9A8A92
    static let coral       = Color(red: 1.0,   green: 0.541, blue: 0.42)  // #FF8A6B
    static let coralLight  = Color(red: 1.0,   green: 0.667, blue: 0.588)
    static let coralDark   = Color(red: 0.878, green: 0.431, blue: 0.314)
    static let purple      = Color(red: 0.608, green: 0.42,  blue: 0.91)  // #9B6BE8
    static let berry       = Color(red: 1.0,   green: 0.49,  blue: 0.659) // #FF7DA8
    static let hairline    = Color(red: 0.29,  green: 0.233, blue: 0.271).opacity(0.08)

    /// The widget's container background: a warm cream gradient.
    static var background: some View {
        LinearGradient(
            colors: [cream, creamDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
