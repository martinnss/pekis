import SwiftUI

/// A single code-drawn "Peki" cat — a round, friendly kitty with pointed ears,
/// expressive eyes, a little heart nose, whiskers, blush cheeks, paws and a
/// swishing tail. Fully procedural so it can breathe, blink, bob, swish and
/// react to `mood` with no image assets or external animation libraries.
struct PekiMascot: View {
    var mood: MascotMood = .idle
    var tint: Color = .pekisCoral
    var size: CGFloat = 120
    /// When true the figure is drawn as a faint dotted "missing partner".
    var isSilhouette: Bool = false

    @State private var breathe = false
    @State private var bob = false
    @State private var wave = false
    @State private var swish = false
    @State private var isBlinking = false

    private var bodyColor: Color { isSilhouette ? Color.pekisInkSoft.opacity(0.25) : tint }

    var body: some View {
        ZStack {
            tail
            ears
            bodyShape
            face
            paws
        }
        .frame(width: size, height: size)
        .scaleEffect(x: breathe ? 1.015 : 0.99, y: breathe ? 0.99 : 1.02, anchor: .bottom)
        .offset(y: (mood.bobs && bob) ? -size * 0.04 : 0)
        .animation(.easeInOut(duration: 2.1).repeatForever(autoreverses: true), value: breathe)
        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: bob)
        .onAppear {
            breathe = true
            bob = true
            swish = true
            startBlinking()
            wave = true
        }
    }

    // MARK: - Body

    private var bodyShape: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [bodyColor.lighter(0.12), bodyColor],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size * 0.82, height: size * 0.78)
            .overlay(
                Ellipse().stroke(bodyColor.darker(0.12).opacity(isSilhouette ? 0 : 0.5), lineWidth: 2)
            )
            .offset(y: size * 0.07)
            .shadow(color: bodyColor.opacity(isSilhouette ? 0 : 0.3), radius: 10, y: 8)
    }

    // MARK: - Ears (pointed, cat-style)

    private var ears: some View {
        HStack(spacing: size * 0.30) {
            ear.rotationEffect(.degrees(-8), anchor: .bottom)
            ear.scaleEffect(x: -1).rotationEffect(.degrees(8), anchor: .bottom)
        }
        .offset(y: -size * 0.27)
    }

    private var ear: some View {
        CatEar()
            .fill(bodyColor)
            .overlay(
                CatEar()
                    .fill(Color.pekisBerry.opacity(isSilhouette ? 0 : 0.4))
                    .scaleEffect(0.5, anchor: .bottom)
                    .offset(y: -size * 0.02)
            )
            .overlay(CatEar().stroke(bodyColor.darker(0.12).opacity(isSilhouette ? 0 : 0.5), lineWidth: 2))
            .frame(width: size * 0.26, height: size * 0.28)
    }

    // MARK: - Face

    @ViewBuilder
    private var face: some View {
        if isSilhouette {
            EmptyView()
        } else {
            ZStack {
                whiskers

                HStack(spacing: size * 0.20) {
                    eye
                    eye
                }
                .offset(y: -size * 0.03)

                if mood.showsBlush {
                    HStack(spacing: size * 0.44) {
                        blush
                        blush
                    }
                    .offset(y: size * 0.10)
                }

                nose.offset(y: size * 0.10)
                mouth.offset(y: size * 0.18)
            }
            .offset(y: size * 0.02)
        }
    }

    private var eye: some View {
        Group {
            if mood.showsHeartEyes {
                Image(systemName: "heart.fill")
                    .font(.system(size: size * 0.16))
                    .foregroundStyle(Color.pekisBerry)
                    .scaleEffect(isBlinking ? 0.85 : 1)
            } else {
                ZStack {
                    Capsule()
                        .fill(Color(hex: 0x3A2E36))
                        .frame(width: size * 0.11, height: size * 0.14)
                    Circle()
                        .fill(.white)
                        .frame(width: size * 0.04, height: size * 0.04)
                        .offset(x: size * 0.02, y: -size * 0.03)
                }
                .scaleEffect(y: isBlinking || mood == .sleepy ? 0.12 : 1, anchor: .center)
            }
        }
    }

    private var blush: some View {
        Ellipse()
            .fill(Color.pekisBerry.opacity(0.35))
            .frame(width: size * 0.13, height: size * 0.085)
    }

    /// Little upside-down heart nose.
    private var nose: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: size * 0.07))
            .foregroundStyle(Color.pekisBerry)
            .rotationEffect(.degrees(180))
    }

    private var whiskers: some View {
        HStack(spacing: size * 0.30) {
            WhiskerSet()
                .stroke(Color(hex: 0x3A2E36).opacity(0.55),
                        style: StrokeStyle(lineWidth: size * 0.012, lineCap: .round))
                .frame(width: size * 0.24, height: size * 0.16)
            WhiskerSet()
                .stroke(Color(hex: 0x3A2E36).opacity(0.55),
                        style: StrokeStyle(lineWidth: size * 0.012, lineCap: .round))
                .scaleEffect(x: -1)
                .frame(width: size * 0.24, height: size * 0.16)
        }
        .offset(y: size * 0.12)
    }

    private var mouth: some View {
        MascotMouth(open: isOpenMouth)
            .stroke(Color(hex: 0x3A2E36), style: StrokeStyle(lineWidth: size * 0.022, lineCap: .round, lineJoin: .round))
            .background(isOpenMouth ? MascotMouth(open: true).fill(Color.pekisBerry.opacity(0.6)) : nil)
            .frame(width: size * 0.20, height: size * 0.11)
    }

    private var isOpenMouth: Bool {
        switch mood {
        case .happy, .waving, .celebrate, .engaged: return true
        default: return false
        }
    }

    // MARK: - Tail

    private var tail: some View {
        CatTail()
            .stroke(
                LinearGradient(colors: [bodyColor, bodyColor.lighter(0.1)], startPoint: .bottom, endPoint: .top),
                style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round)
            )
            .frame(width: size * 0.5, height: size * 0.5)
            .rotationEffect(.degrees(swish ? 8 : -6), anchor: .bottomLeading)
            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: swish)
            .offset(x: size * 0.34, y: size * 0.18)
    }

    // MARK: - Paws

    private var paws: some View {
        HStack {
            paw
                .rotationEffect(.degrees(mood == .waving && wave ? -38 : -6), anchor: .top)
                .animation(
                    mood == .waving
                    ? .easeInOut(duration: 0.45).repeatForever(autoreverses: true)
                    : .default,
                    value: wave
                )
            Spacer()
            paw.rotationEffect(.degrees(6), anchor: .top)
        }
        .frame(width: size * 0.78)
        .offset(y: size * 0.26)
    }

    private var paw: some View {
        Ellipse()
            .fill(bodyColor.darker(0.04))
            .frame(width: size * 0.18, height: size * 0.14)
            .overlay(Ellipse().stroke(bodyColor.darker(0.12).opacity(isSilhouette ? 0 : 0.5), lineWidth: 2))
    }

    // MARK: - Blink loop

    private func startBlinking() {
        guard !isSilhouette, mood != .sleepy else { return }
        Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 2.2...4.5) * 1_000_000_000))
                withAnimation(.easeInOut(duration: 0.08)) { isBlinking = true }
                try? await Task.sleep(nanoseconds: 120_000_000)
                withAnimation(.easeInOut(duration: 0.08)) { isBlinking = false }
            }
        }
    }
}

// MARK: - Shapes

/// A pointed cat ear — a triangle with a softly rounded tip.
private struct CatEar: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.midX + rect.width * 0.12, y: rect.minY),
            control: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.1)
        )
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.45)
        )
        p.closeSubpath()
        return p
    }
}

/// Three whisker lines fanning out from the muzzle (one side).
private struct WhiskerSet: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let originX = rect.maxX
        let midY = rect.midY
        // upper, middle, lower whisker
        p.move(to: CGPoint(x: originX, y: midY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.1))
        p.move(to: CGPoint(x: originX, y: midY))
        p.addLine(to: CGPoint(x: rect.minX, y: midY))
        p.move(to: CGPoint(x: originX, y: midY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.1))
        return p
    }
}

/// A curling cat tail.
private struct CatTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addCurve(
            to: CGPoint(x: rect.maxX * 0.85, y: rect.minY + rect.height * 0.18),
            control1: CGPoint(x: rect.maxX * 0.6, y: rect.maxY),
            control2: CGPoint(x: rect.maxX, y: rect.midY)
        )
        return p
    }
}

/// Mouth path — a smile arc, or a rounded open "happy" mouth.
private struct MascotMouth: Shape {
    var open: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        if open {
            p.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.2))
            p.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.2),
                control: CGPoint(x: rect.midX, y: rect.minY)
            )
            p.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.2),
                control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.2)
            )
        } else {
            // a gentle upward cat smile ‿
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY),
                control: CGPoint(x: rect.midX, y: rect.maxY)
            )
        }
        return p
    }
}

extension Color {
    /// Lighten by blending toward white.
    func lighter(_ amount: Double) -> Color {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let f = CGFloat(amount)
        return Color(
            red: Double(r + (1 - r) * f),
            green: Double(g + (1 - g) * f),
            blue: Double(b + (1 - b) * f),
            opacity: Double(a)
        )
    }
}

#Preview {
    ZStack {
        Color.pekisCream.ignoresSafeArea()
        VStack(spacing: 40) {
            HStack(spacing: 30) {
                PekiMascot(mood: .idle, tint: .pekisCoral)
                PekiMascot(mood: .waving, tint: .pekisSky)
            }
            HStack(spacing: 30) {
                PekiMascot(mood: .engaged, tint: .pekisBerry)
                PekiMascot(mood: .happy, tint: .pekisMint)
            }
        }
    }
}
