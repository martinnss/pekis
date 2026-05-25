import PhotosUI
import SwiftUI

struct MomentShareView: View {
    @StateObject private var viewModel: MomentShareViewModel
    @State private var pickerItem: PhotosPickerItem?
    let onExit: () -> Void

    init(cloudKitService: CloudKitService, onExit: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: MomentShareViewModel(cloudKitService: cloudKitService))
        self.onExit = onExit
    }

    var body: some View {
        VStack(spacing: 20) {
            header
            promptBanner

            Spacer(minLength: 16)

            if viewModel.isLoadingMoments && !viewModel.isPosted {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isPosted {
                postedState
            } else {
                captureState
            }

            Spacer()
        }
        .onAppear {
            Task { await viewModel.fetchMoments() }
        }
        .onChange(of: pickerItem) { _, newValue in
            viewModel.updatePickerItem(newValue)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }

    // MARK: - Header

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

    // MARK: - Prompt Banner

    private var promptBanner: some View {
        Text("✨ \(viewModel.prompt)")
            .font(.callout.weight(.bold))
            .foregroundStyle(.yellow.opacity(0.9))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color.yellow.opacity(0.2))
            .clipShape(Capsule())
    }

    // MARK: - Capture State (not yet posted)

    private var captureState: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                    .foregroundStyle(.white.opacity(0.3))
                    .frame(height: 360)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

                if let image = viewModel.myImage {
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

            if viewModel.myImage == nil {
                PhotosPicker(
                    selection: $pickerItem,
                    matching: .images,
                    preferredItemEncoding: .automatic
                ) {
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
                    .buttonStyle(
                        CapsuleButtonStyle(background: .white, foreground: .pink, borderColor: .pink)
                    )

                    Button {
                        Task { await viewModel.postMoment() }
                    } label: {
                        if viewModel.isUploading {
                            HStack(spacing: 8) {
                                ProgressView().tint(.white).scaleEffect(0.8)
                                Text("Uploading…")
                            }
                        } else {
                            Text("Post Moment")
                        }
                    }
                    .buttonStyle(CapsuleButtonStyle(background: .pink, foreground: .white))
                    .disabled(viewModel.isUploading)
                }
            }
        }
    }

    // MARK: - Posted State (shows real partner photo)

    private var postedState: some View {
        VStack(spacing: 16) {
            Text(viewModel.partnerPosted
                 ? "Both of you shared a moment today! 💕"
                 : "You shared! Waiting for partner's moment…")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal)

            HStack(spacing: 16) {
                // My photo
                if let image = viewModel.myImage {
                    momentCard(image: image, label: "You • Today")
                }

                // Partner's photo or placeholder
                if viewModel.partnerPosted, let partnerImage = viewModel.partnerImage {
                    momentCard(image: partnerImage, label: "Partner • Today")
                } else {
                    partnerPlaceholder
                }
            }
            .padding(.horizontal, 4)

            Button("Back to Dashboard", action: onExit)
                .buttonStyle(
                    CapsuleButtonStyle(
                        background: .white.opacity(0.01),
                        foreground: .white,
                        borderColor: .white
                    )
                )
        }
    }

    private func momentCard(image: UIImage, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var partnerPlaceholder: some View {
        VStack(alignment: .center, spacing: 12) {
            if viewModel.isLoadingMoments {
                ProgressView().tint(.white)
            } else {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.largeTitle)
                    .foregroundStyle(.white.opacity(0.6))
                Text("Partner hasn't posted yet")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MomentShareView(cloudKitService: CloudKitService(), onExit: {})
    }
}
