import SwiftUI

// MARK: - Pekis Palette (warm cozy "Animal Crossing" light theme)
//
// The app moved away from a dark purple theme to a bright, friendly, game-like
// look. Purple is kept as the *signature brand accent* (logo + primary CTAs)
// but no longer dominates — most surfaces are cream/white with warm pastel
// accents. Raw values live in `PekisPalette` once, then are surfaced both as
// `Color.pekisX` (for fills/backgrounds) and as `.pekisX` shorthand (for
// `.foregroundStyle` / `.tint`, via the `ShapeStyle` extension below).

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }

    /// A soft tinted shadow for cozy cards, derived from an accent color.
    func cozyShadow(_ opacity: Double = 0.22) -> Color {
        self.opacity(opacity)
    }
}

enum PekisPalette {
    // Surfaces & ink
    static let cream = Color(hex: 0xFFF7EF)
    static let creamDeep = Color(hex: 0xFCEBDA)
    static let surface = Color.white
    static let surfaceSoft = Color(hex: 0xFFF1E4)
    static let ink = Color(hex: 0x4A3B45)
    static let inkSoft = Color(hex: 0x9A8A92)
    static let hairline = Color(hex: 0x4A3B45).opacity(0.08)

    // Warm cozy accents
    static let coral = Color(hex: 0xFF8A6B)
    static let mint = Color(hex: 0x6FCBA8)
    static let sky = Color(hex: 0x7FB8E8)
    static let sun = Color(hex: 0xFFCB5C)
    static let berry = Color(hex: 0xFF7DA8)

    // Signature brand purple (softened from the old #8126EA)
    static let purple = Color(hex: 0x9B6BE8)
    static let lightPurple = Color(hex: 0xC3A4F2)
    static let darkPurple = Color(hex: 0x6E45B0)
}

extension Color {
    static let pekisCream = PekisPalette.cream
    static let pekisCreamDeep = PekisPalette.creamDeep
    static let pekisSurface = PekisPalette.surface
    static let pekisSurfaceSoft = PekisPalette.surfaceSoft
    static let pekisInk = PekisPalette.ink
    static let pekisInkSoft = PekisPalette.inkSoft
    static let pekisHairline = PekisPalette.hairline

    static let pekisCoral = PekisPalette.coral
    static let pekisMint = PekisPalette.mint
    static let pekisSky = PekisPalette.sky
    static let pekisSun = PekisPalette.sun
    static let pekisBerry = PekisPalette.berry

    static let pekisPurple = PekisPalette.purple
    static let pekisLightPurple = PekisPalette.lightPurple
    static let pekisDarkPurple = PekisPalette.darkPurple

    // Historic name kept so existing call sites pick up the new light look.
    static let pekisBackground = PekisPalette.cream

    static let pekisGradient = LinearGradient(
        colors: [PekisPalette.coral, PekisPalette.berry],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Shorthand so `.foregroundStyle(.pekisInk)`, `.tint(.pekisCoral)`, etc. work.
extension ShapeStyle where Self == Color {
    static var pekisCream: Color { PekisPalette.cream }
    static var pekisCreamDeep: Color { PekisPalette.creamDeep }
    static var pekisSurface: Color { PekisPalette.surface }
    static var pekisSurfaceSoft: Color { PekisPalette.surfaceSoft }
    static var pekisInk: Color { PekisPalette.ink }
    static var pekisInkSoft: Color { PekisPalette.inkSoft }
    static var pekisHairline: Color { PekisPalette.hairline }

    static var pekisCoral: Color { PekisPalette.coral }
    static var pekisMint: Color { PekisPalette.mint }
    static var pekisSky: Color { PekisPalette.sky }
    static var pekisSun: Color { PekisPalette.sun }
    static var pekisBerry: Color { PekisPalette.berry }

    static var pekisPurple: Color { PekisPalette.purple }
    static var pekisLightPurple: Color { PekisPalette.lightPurple }
    static var pekisDarkPurple: Color { PekisPalette.darkPurple }
}
