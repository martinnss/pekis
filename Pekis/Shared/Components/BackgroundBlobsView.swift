import SwiftUI

/// The cozy *world* behind every screen — a soft lavender→cream sky with a sun,
/// drifting clouds, twinkling sparkles and rolling hills along the bottom. This
/// is what gives Pekis its "Animal-Crossing-but-purple" game feel rather than a
/// flat app background. Drop it inside a ZStack before content.
struct CozyBackground: View {
    @State private var drift = false
    @State private var clouds = false

    var body: some View {
        ZStack {
            // Purple-forward sky fading to warm cream at the horizon.
            sky
            sun
            clouds(in: UIScreen.main.bounds.size)
            FloatingSparkles()
            hills
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) { drift.toggle() }
            withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) { clouds.toggle() }
        }
    }

    private var sky: some View {
        LinearGradient(
            colors: [Color(hex: 0xE7DBFB), Color(hex: 0xF3E7F6), Color(hex: 0xFFF3E9), Color(hex: 0xFDEFE0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var sun: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.pekisSun.opacity(0.9), Color.pekisSun.opacity(0.0)],
                    center: .center, startRadius: 8, endRadius: 130
                )
            )
            .frame(width: 220, height: 220)
            .offset(x: 120, y: -260)
    }

    @ViewBuilder
    private func clouds(in size: CGSize) -> some View {
        ZStack {
            cloud.frame(width: 120).offset(x: clouds ? size.width * 0.6 : -size.width * 0.5, y: -size.height * 0.30)
            cloud.frame(width: 90).offset(x: clouds ? size.width * 0.2 : size.width * 0.9, y: -size.height * 0.18)
            cloud.frame(width: 70).offset(x: clouds ? -size.width * 0.3 : size.width * 0.4, y: -size.height * 0.36)
        }
    }

    private var cloud: some View {
        HStack(spacing: -22) {
            Circle().frame(width: 44, height: 44)
            Circle().frame(width: 60, height: 60)
            Circle().frame(width: 40, height: 40)
        }
        .foregroundStyle(.white.opacity(0.75))
        .blur(radius: 2)
    }

    private var hills: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                hill(color: Color(hex: 0xCDBDF0).opacity(0.55), width: w * 1.7, height: 260)
                    .offset(x: drift ? -40 : -90, y: h - 120)
                hill(color: Color(hex: 0xBDE9D2).opacity(0.7), width: w * 1.6, height: 230)
                    .offset(x: drift ? 60 : 110, y: h - 80)
                hill(color: Color(hex: 0xFCE0CC).opacity(0.9), width: w * 1.8, height: 220)
                    .offset(x: drift ? -30 : -70, y: h - 40)
            }
            .frame(width: w, height: h)
        }
    }

    private func hill(color: Color, width: CGFloat, height: CGFloat) -> some View {
        Ellipse()
            .fill(color)
            .frame(width: width, height: height)
            .blur(radius: 0.5)
    }
}

private struct Sparkle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let scale: CGFloat
    let delay: Double
}

/// A handful of tiny twinkling sparkles — pure decoration.
private struct FloatingSparkles: View {
    private let seeds: [Sparkle] = [
        Sparkle(x: 0.15, y: 0.20, scale: 0.7, delay: 0.0),
        Sparkle(x: 0.82, y: 0.16, scale: 0.9, delay: 0.8),
        Sparkle(x: 0.68, y: 0.40, scale: 0.6, delay: 1.6),
        Sparkle(x: 0.24, y: 0.52, scale: 0.8, delay: 0.4),
        Sparkle(x: 0.88, y: 0.55, scale: 0.7, delay: 1.2)
    ]
    @State private var twinkle = false

    var body: some View {
        GeometryReader { proxy in
            ForEach(seeds) { s in
                Image(systemName: "sparkle")
                    .font(.system(size: 16 * s.scale))
                    .foregroundStyle(Color.pekisSun.opacity(0.8))
                    .position(x: proxy.size.width * s.x, y: proxy.size.height * s.y)
                    .scaleEffect(twinkle ? 1.0 : 0.5)
                    .opacity(twinkle ? 0.9 : 0.3)
                    .animation(
                        .easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(s.delay),
                        value: twinkle
                    )
            }
        }
        .onAppear { twinkle = true }
    }
}

/// Backwards-compatible alias.
struct BackgroundBlobsView: View {
    var body: some View { CozyBackground() }
}

#Preview {
    CozyBackground()
}
