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

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.pink)

                Text("Invite Your Partner")
                    .font(.title.bold())

                Text("Share this link with your partner to connect your Pekis apps together.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                VStack(spacing: 16) {
                    // URL Display
                    Text(url.absoluteString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                    // Share Button
                    ShareLink(item: url) {
                        Label("Share Invite Link", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.pink)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // Copy Button
                    Button {
                        UIPasteboard.general.url = url
                        HapticManager.notification(type: .success)
                    } label: {
                        Label("Copy Link", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }

                Spacer()

                Text("Your partner will need to tap the link on their iPhone to join.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ShareLinkView(url: URL(string: "https://example.com/share/abc123")!)
}
