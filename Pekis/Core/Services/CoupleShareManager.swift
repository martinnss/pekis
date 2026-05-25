import CloudKit
import Combine
import SwiftUI
import UIKit

/// Manages CloudKit sharing flow for couple pairing
/// Wraps UICloudSharingController for SwiftUI integration
@MainActor
final class CoupleShareManager: ObservableObject {
    @Published var isShowingShareSheet = false
    @Published var shareURL: URL?
    @Published var errorMessage: String?

    private weak var cloudKitService: CloudKitService?

    init(cloudKitService: CloudKitService? = nil) {
        self.cloudKitService = cloudKitService
    }

    func setService(_ service: CloudKitService) {
        self.cloudKitService = service
    }

    /// Generate a share URL for the partner to accept
    func generateShareLink() async {
        guard let service = cloudKitService else {
            errorMessage = "Service not available"
            return
        }

        do {
            let share = try await service.getOrCreateShare()
            shareURL = share.url
            isShowingShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - SwiftUI Share Sheet Wrapper

struct CloudSharingSheet: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let onComplete: (Result<Void, Error>) -> Void

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowPrivate]
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let onComplete: (Result<Void, Error>) -> Void

        init(onComplete: @escaping (Result<Void, Error>) -> Void) {
            self.onComplete = onComplete
        }

        func cloudSharingController(
            _ csc: UICloudSharingController,
            failedToSaveShareWithError error: Error
        ) {
            onComplete(.failure(error))
        }

        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            onComplete(.success(()))
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            // User cancelled sharing
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            return "Join Pekis"
        }

        func itemThumbnailData(for csc: UICloudSharingController) -> Data? {
            // Could return app icon data here
            return nil
        }
    }
}

// MARK: - Share Link View

struct ShareLinkView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var showCopiedToast = false

    private var inviteMessage: String {
        // BUG 5 FIX: removed fake App Store placeholder URL
        """
        Hey! Let's stay connected on Pekis 💜

        Pekis is a private space for couples to share moments, memories, and feelings together.

        Tap this link on your iPhone to pair with me:
        \(url.absoluteString)

        I can't wait to experience this journey with you! 💕✨
        """
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pekisBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pekisLightPurple, .pekisPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Invite Your Partner")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text("Send this message to your partner. It includes the app download link and your unique connection link.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal)

                    VStack(spacing: 16) {
                        // Message Preview
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MESSAGE PREVIEW")
                                .font(.caption.bold())
                                .foregroundStyle(.white.opacity(0.5))

                            Text(inviteMessage)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)

                        // Share Button
                        ShareLink(item: inviteMessage) {
                            Label("Share Message", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.pekisPurple, Color.pekisLightPurple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)

                        // Copy Button
                        Button {
                            UIPasteboard.general.string = inviteMessage
                            HapticManager.notification(type: .success)
                            showCopiedToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showCopiedToast = false
                            }
                        } label: {
                            Label("Copy Message", systemImage: "doc.on.doc")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                    }

                    // Copied toast
                    if showCopiedToast {
                        Text("✓ Message copied!")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.pekisPurple)
                            .clipShape(Capsule())
                            .transition(.opacity.combined(with: .scale))
                    }

                    Spacer()
                }
                .padding(.top, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.pekisLightPurple)
                }
            }
            .toolbarBackground(Color.pekisBackground, for: .navigationBar)
        }
        .animation(.easeInOut, value: showCopiedToast)
    }
}

// MARK: - Preview

#Preview {
    ShareLinkView(url: URL(string: "https://example.com/share/abc123") ?? URL(fileURLWithPath: "/"))
}
