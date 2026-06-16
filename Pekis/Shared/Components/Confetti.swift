import SwiftUI

/// Lightweight confetti burst. Spawns a capped number of colored pieces that
/// fall + spin once when `trigger` flips. Cheap enough for celebration moments
/// (onboarding "engaged", word-search win).
struct ConfettiView: View {
    var trigger: Bool
    var count: Int = 28

    private let colors: [Color] = [.pekisCoral, .pekisMint, .pekisSky, .pekisSun, .pekisBerry, .pekisPurple]

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                guard trigger else { return }
                let t = timeline.date.timeIntervalSinceReferenceDate
                let height = Double(size.height)
                let width = Double(size.width)
                for i in 0..<count {
                    var rng = SeededRandom(seed: UInt64(i) &* 2654435761)
                    let startX = width * rng.next()
                    let drift = (rng.next() - 0.5) * 120
                    let speed = 90 + rng.next() * 140
                    let phase = rng.next() * 6.28
                    let cycle = (t * 0.001 * speed).truncatingRemainder(dividingBy: height + 200)
                    let y = cycle - 40
                    let x = startX + drift * sin(t * 0.002 + phase)
                    var transform = context
                    transform.translateBy(x: x, y: y)
                    transform.rotate(by: .radians(t * 0.004 + phase))
                    transform.fill(
                        Path(roundedRect: CGRect(x: -4, y: -6, width: 8, height: 12), cornerRadius: 2),
                        with: .color(colors[i % colors.count])
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Tiny deterministic PRNG so confetti looks the same per piece without storing state.
private struct SeededRandom {
    var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B9 : seed }
    mutating func next() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state % 10_000) / 10_000.0
    }
}

private struct HeartSeed: Identifiable {
    let id = UUID()
    let x: CGFloat
    let delay: Double
    let scale: CGFloat
}

/// Floating hearts that rise and fade — used by the mascot duo for love/engaged.
struct FloatingHearts: View {
    var active: Bool
    @State private var animate = false

    private let seeds: [HeartSeed] = [
        HeartSeed(x: 0.30, delay: 0.0, scale: 0.9),
        HeartSeed(x: 0.50, delay: 0.5, scale: 1.1),
        HeartSeed(x: 0.70, delay: 1.0, scale: 0.8),
        HeartSeed(x: 0.40, delay: 1.4, scale: 1.0),
        HeartSeed(x: 0.60, delay: 1.9, scale: 0.7)
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(seeds) { s in
                Image(systemName: "heart.fill")
                    .font(.system(size: 18 * s.scale))
                    .foregroundStyle(Color.pekisBerry)
                    .position(x: proxy.size.width * s.x, y: proxy.size.height * (animate ? 0.05 : 0.85))
                    .opacity(active ? (animate ? 0 : 0.9) : 0)
                    .animation(
                        active
                        ? .easeOut(duration: 2.2).repeatForever(autoreverses: false).delay(s.delay)
                        : .default,
                        value: animate
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear { if active { animate = true } }
        .onChange(of: active) { newValue in animate = newValue }
    }
}
