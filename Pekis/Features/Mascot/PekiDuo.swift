import SwiftUI

/// A single Peki cat that represents the app's companion. It reacts to the
/// relationship state:
/// - `.idle` / `.happy`: sitting, breathing, blinking & swishing its tail
/// - `.hopeful`: waving (used after an invite is sent, before the partner joins)
/// - `.engaged` / `.love`: heart eyes with floating hearts — the "we're
///   connected" payoff
/// - `.celebrate`: an excited bounce
///
/// Kept under the original `PekiDuo` name so every call site stays unchanged;
/// the `leftTint`/`rightTint` parameters are retained for source compatibility,
/// with `leftTint` acting as the cat's colour.
struct PekiDuo: View {
    var mood: MascotMood = .idle
    var size: CGFloat = 120
    var leftTint: Color = .pekisCoral
    var rightTint: Color = .pekisSky

    var body: some View {
        ZStack {
            if mood == .engaged || mood == .love {
                FloatingHearts(active: true)
                    .frame(width: size * 1.8, height: size * 1.5)
            }

            PekiMascot(mood: catMood, tint: leftTint, size: size)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: mood)

            if mood == .engaged {
                Image(systemName: "sparkles")
                    .font(.system(size: size * 0.3, weight: .bold))
                    .foregroundStyle(Color.pekisSun)
                    .offset(y: -size * 0.55)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: size * 1.4)
    }

    private var catMood: MascotMood {
        switch mood {
        case .hopeful: return .waving
        default: return mood
        }
    }
}

#Preview {
    ZStack {
        Color.pekisCream.ignoresSafeArea()
        VStack(spacing: 50) {
            PekiDuo(mood: .idle)
            PekiDuo(mood: .hopeful)
            PekiDuo(mood: .engaged)
        }
    }
}
