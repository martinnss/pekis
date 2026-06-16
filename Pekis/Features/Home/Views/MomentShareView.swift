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
        VStack(spacing: 18) {
            CozyHeader(title: "Daily Moment", tint: .pekisCoral, onHome: onExit)
            promptBanner

            Spacer(minLength: 12)

            if viewModel.isLoadingMoments && !viewModel.isPosted {
                ProgressView()
                    .tint(.pekisCoral)
                    .scaleEffect(1.4)
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

    private var promptBanner: some View {
        Label(viewModel.prompt, systemImage: "sparkles")
            .font(PekisFont.caption())
            .foregroundStyle(.pekisCoral)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.pekisCoral.opacity(0.14), in: Capsule())
    }

    // MARK: - Capture State

    private var captureState: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(Color.pekisSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [9]))
                            .foregroundStyle(Color.pekisCoral.opacity(0.5))
                    )
                    .frame(height: 360)
                    .shadow(color: Color.pekisCoral.opacity(0.15), radius: 16, y: 10)

                if let image = viewModel.myImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 360)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                } else {
                    VStack(spacing: 12) {
                        CozyIconBadge(systemName: "photo.on.rectangle", tint: .pekisCoral, size: 70)
                        Text("No photo selected")
                            .font(PekisFont.body())
                            .foregroundStyle(.pekisInkSoft)
                    }
                }
            }

            if viewModel.myImage == nil {
                PhotosPicker(
                    selection: $pickerItem,
                    matching: .images,
                    preferredItemEncoding: .automatic
                ) {
                    Label("Take or Choose Photo", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SquishyButtonStyle(tint: .pekisCoral))
            } else {
                HStack(spacing: 12) {
                    Button("Retake") {
                        pickerItem = nil
                        viewModel.resetPhoto()
                    }
                    .buttonStyle(CapsuleButtonStyle(background: .pekisSurfaceSoft, foreground: .pekisInk))

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
                    .buttonStyle(SquishyButtonStyle(tint: .pekisCoral))
                    .disabled(viewModel.isUploading)
                }
            }
        }
    }

    // MARK: - Posted State

    private var postedState: some View {
        VStack(spacing: 16) {
            PekiMascot(mood: viewModel.partnerPosted ? .love : .hopeful,
                       tint: .pekisCoral, size: 76)

            Text(viewModel.partnerPosted
                 ? "Both of you shared a moment today! 💕"
                 : "You shared! Waiting for partner's moment…")
                .font(PekisFont.body())
                .multilineTextAlignment(.center)
                .foregroundStyle(.pekisInk)
                .padding(.horizontal)

            HStack(spacing: 16) {
                if let image = viewModel.myImage {
                    momentCard(image: image, label: "You • Today")
                }
                if viewModel.partnerPosted, let partnerImage = viewModel.partnerImage {
                    momentCard(image: partnerImage, label: "Partner • Today")
                } else {
                    partnerPlaceholder
                }
            }
            .padding(.horizontal, 4)

            Button("Back to Dashboard", action: onExit)
                .buttonStyle(CapsuleButtonStyle(background: .pekisSurfaceSoft, foreground: .pekisInk))
        }
    }

    private func momentCard(image: UIImage, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            Text(label)
                .font(PekisFont.caption())
                .foregroundStyle(.pekisInkSoft)
        }
    }

    private var partnerPlaceholder: some View {
        VStack(spacing: 12) {
            if viewModel.isLoadingMoments {
                ProgressView().tint(.pekisCoral)
            } else {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.largeTitle)
                    .foregroundStyle(.pekisInkSoft)
                Text("Partner hasn't posted yet")
                    .font(PekisFont.caption())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.pekisInkSoft)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color.pekisSurfaceSoft, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

#Preview {
    ZStack {
        CozyBackground()
        MomentShareView(cloudKitService: CloudKitService(), onExit: {}).padding()
    }
}
