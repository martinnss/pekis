import SwiftUI

/// Animated ambient blob background used across multiple screens (HomeView, CoupleOnboardingView).
/// Drop it inside a ZStack before your content and add `.ignoresSafeArea()`.
struct BackgroundBlobsView: View {
    @State private var animateBlob1 = false
    @State private var animateBlob2 = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Circle()
                    .fill(Color.pekisPurple.opacity(0.4))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: animateBlob1 ? -50 : -150, y: animateBlob1 ? -100 : -200)

                Circle()
                    .fill(Color.pekisLightPurple.opacity(0.3))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: animateBlob2 ? 50 : 180, y: animateBlob2 ? 150 : 50)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                animateBlob1.toggle()
            }
            withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                animateBlob2.toggle()
            }
        }
    }
}

#Preview {
    ZStack {
        Color.pekisBackground.ignoresSafeArea()
        BackgroundBlobsView()
    }
}
