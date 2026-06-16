import SwiftUI

// MARK: - Pekis Theme
//
// Typography, card styling, and accent helpers for the cozy redesign.
// Everything uses `design: .rounded` — the single biggest "friendly game"
// signal — and warm ink colors instead of white-on-dark.

enum PekisFont {
    static func bigTitle() -> Font { .system(size: 34, weight: .heavy, design: .rounded) }
    static func title() -> Font { .system(size: 26, weight: .bold, design: .rounded) }
    static func headline() -> Font { .system(size: 18, weight: .bold, design: .rounded) }
    static func body() -> Font { .system(size: 16, weight: .medium, design: .rounded) }
    static func caption() -> Font { .system(size: 13, weight: .semibold, design: .rounded) }
}

// MARK: - Activity accents

/// Each dashboard activity gets its own happy hue so the grid feels playful
/// rather than monochrome.
enum PekisActivity {
    case wordSearch, topics, dateRoulette, thisOrThat, loveNote, momentShare

    var accent: Color {
        switch self {
        case .wordSearch: return .pekisMint
        case .topics: return .pekisSky
        case .dateRoulette: return .pekisSun
        case .thisOrThat: return .pekisPurple
        case .loveNote: return .pekisBerry
        case .momentShare: return .pekisCoral
        }
    }
}

// MARK: - Cozy Card

/// White rounded surface with a soft *colored* drop shadow and hairline border.
/// Replaces the repeated `.fill(.white.opacity(0.05))` + stroke pattern.
struct CozyCard: ViewModifier {
    var accent: Color = .pekisCoral
    var cornerRadius: CGFloat = 28
    var fill: Color = .pekisSurface

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fill)
                    .shadow(color: accent.cozyShadow(0.18), radius: 18, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.pekisHairline, lineWidth: 1)
            )
    }
}

extension View {
    func cozyCard(accent: Color = .pekisCoral, cornerRadius: CGFloat = 28, fill: Color = .pekisSurface) -> some View {
        modifier(CozyCard(accent: accent, cornerRadius: cornerRadius, fill: fill))
    }

    /// A soft pill chip used for badges / counters.
    func cozyChip(_ tint: Color = .pekisCoral) -> some View {
        self
            .font(PekisFont.caption())
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(tint.opacity(0.16), in: Capsule())
    }
}

// MARK: - Speech bubble

/// A rounded speech bubble with a little downward tail — lets the mascot "talk"
/// to the player, a hallmark of friendly game UIs.
struct PekiSpeechBubble: View {
    let text: String
    var tint: Color = .pekisPurple

    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(.pekisInk)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(
                BubbleShape()
                    .fill(Color.pekisSurface)
                    .shadow(color: tint.opacity(0.25), radius: 10, y: 6)
            )
            .overlay(BubbleShape().stroke(tint.opacity(0.25), lineWidth: 1.5))
    }
}

private struct BubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailW: CGFloat = 18
        let tailH: CGFloat = 10
        let body = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - tailH)
        var p = Path(roundedRect: body, cornerRadius: radius, style: .continuous)
        let midX = rect.midX
        p.move(to: CGPoint(x: midX - tailW / 2, y: body.maxY - 1))
        p.addLine(to: CGPoint(x: midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: midX + tailW / 2, y: body.maxY - 1))
        p.closeSubpath()
        return p
    }
}

// MARK: - Cozy screen header

/// Reusable top bar for activity screens: a round "home" button, a centered
/// title, and optional trailing content (e.g. a progress chip).
struct CozyHeader<Trailing: View>: View {
    let title: String
    var tint: Color = .pekisCoral
    let onHome: () -> Void
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack {
            Button {
                HapticManager.selection()
                onHome()
            } label: {
                Image(systemName: "house.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(tint)
                    .padding(11)
                    .background(Color.pekisSurface, in: Circle())
                    .overlay(Circle().stroke(Color.pekisHairline, lineWidth: 1))
            }
            .accessibilityLabel("Back to dashboard")

            Spacer()
            Text(title)
                .font(PekisFont.title())
                .foregroundStyle(.pekisInk)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer()

            trailing()
                .frame(minWidth: 44, alignment: .trailing)
        }
    }
}

extension CozyHeader where Trailing == Color {
    init(title: String, tint: Color = .pekisCoral, onHome: @escaping () -> Void) {
        self.init(title: title, tint: tint, onHome: onHome) { Color.clear }
    }
}

// MARK: - Circle icon badge

/// A chunky rounded icon "tile" used in cards and headers.
struct CozyIconBadge: View {
    let systemName: String
    var tint: Color = .pekisCoral
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(tint.opacity(0.18))
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
    }
}
