import PhotosUI
import SwiftUI

struct MomentShareView: View {
    @StateObject private var viewModel = MomentShareViewModel()
    @State private var pickerItem: PhotosPickerItem?
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            header
            promptBanner
            Spacer(minLength: 16)
            if viewModel.isPosted {
                postedState
            } else {
                captureState
            }
            Spacer()
        }
        .onChange(of: pickerItem) { newValue in
            viewModel.updatePickerItem(newValue)
        }
    }

    private var header: some View {
        HStack {
            Button(action: onExit) {
                Image(systemName: "house.fill")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.white.opacity(0.2))
                    .clipShape(Circle())
            }
            Spacer()
            Text("Daily Moment")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var promptBanner: some View {
        Text("⚠️ Time to share: \(viewModel.prompt)")
            .font(.callout.weight(.bold))
            .foregroundStyle(.yellow.opacity(0.9))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color.yellow.opacity(0.2))
            .clipShape(Capsule())
    }

    private var captureState: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(height: 360)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                if let image = viewModel.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 360)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("No photo selected")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            if viewModel.image == nil {
                PhotosPicker(selection: $pickerItem, matching: .images, preferredItemEncoding: .automatic) {
                    Label("Take or Choose Photo", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CapsuleButtonStyle(background: .white, foreground: .pink))
            } else {
                HStack(spacing: 12) {
                    Button("Retake") {
                        pickerItem = nil
                        viewModel.resetPhoto()
                    }
                    .buttonStyle(CapsuleButtonStyle(background: .white, foreground: .pink, borderColor: .pink))

                    Button("Post Moment") {
                        viewModel.postMoment()
                    }
                    .buttonStyle(CapsuleButtonStyle(background: .pink, foreground: .white))
                }
            }
        }
    }

    private var postedState: some View {
        VStack(spacing: 16) {
            Text("You're all caught up! Waiting for partner's moment...")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal)
            HStack(spacing: 16) {
                if let image = viewModel.image {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        Text("You • Just now")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Partner hasn't posted yet")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            Button("Back to Dashboard", action: onExit)
                .buttonStyle(CapsuleButtonStyle(background: .white.opacity(0.01), foreground: .white, borderColor: .white))
        }
    }
}

#Preview {
    MomentShareView(onExit: {})
}
