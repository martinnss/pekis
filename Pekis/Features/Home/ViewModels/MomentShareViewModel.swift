import Combine
import PhotosUI
import SwiftUI
import UIKit

/// BUG 1 FIX: complete rewrite. Previously this was a stub that never touched CloudKit.
/// Now it uploads photos as CKAsset and fetches both partners' today moments.
@MainActor
final class MomentShareViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var prompt: String
    /// The current user's photo selection (before or after posting)
    @Published private(set) var myImage: UIImage?
    /// Whether the current user has posted today
    @Published private(set) var isPosted: Bool = false
    /// The partner's photo for today (nil until they post)
    @Published private(set) var partnerImage: UIImage?
    /// Whether the partner has posted today
    @Published private(set) var partnerPosted: Bool = false

    @Published var isUploading: Bool = false
    @Published var isLoadingMoments: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Private

    private let cloudKitService: any CloudKitServiceProtocol
    private var notificationObserver: Any?

    // MARK: - Init

    init(cloudKitService: any CloudKitServiceProtocol, date: Date = Date()) {
        self.cloudKitService = cloudKitService

        if AppContent.momentPrompts.isEmpty {
            prompt = "Share a little moment!"
        } else {
            let hourIndex = Calendar.current.component(.hour, from: date) % AppContent.momentPrompts.count
            prompt = AppContent.momentPrompts[hourIndex]
        }

        // BUG 4 extension: also refresh moments on CloudKit push
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .pekisCloudKitDataChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.fetchMoments() }
        }
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Public Actions

    /// Called from view when PhotosPicker selection changes
    func updatePickerItem(_ item: PhotosPickerItem?) {
        guard let item else {
            myImage = nil
            return
        }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else { return }
            myImage = uiImage
        }
    }

    func resetPhoto() {
        myImage = nil
    }

    /// Fetch today's moments for both partners from CloudKit
    func fetchMoments() async {
        isLoadingMoments = true
        defer { isLoadingMoments = false }

        do {
            let moments = try await cloudKitService.fetchTodaysMoments()
            let userID = cloudKitService.currentUserID

            if let mine = moments.first(where: { $0.authorID == userID }) {
                isPosted = true
                if let data = mine.imageData {
                    myImage = UIImage(data: data)
                }
            }

            if let partners = moments.first(where: { $0.authorID != userID }) {
                partnerPosted = true
                if let data = partners.imageData {
                    partnerImage = UIImage(data: data)
                }
            }
        } catch {
            // Silently fail — show empty state rather than an error on load
        }
    }

    /// Compress and upload the selected photo to CloudKit, then refresh
    func postMoment() async {
        guard let image = myImage else { return }
        guard let imageData = image.jpegData(compressionQuality: 0.75) else { return }

        isUploading = true
        defer { isUploading = false }

        do {
            try await cloudKitService.saveMoment(imageData: imageData, prompt: prompt)
            isPosted = true
            HapticManager.notification(type: .success)
            // Refresh so the newly uploaded record is confirmed from CloudKit
            await fetchMoments()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
