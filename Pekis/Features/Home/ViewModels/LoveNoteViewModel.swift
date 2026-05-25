import Combine
import SwiftUI
import UIKit

@MainActor
final class LoveNoteViewModel: ObservableObject {
    @Published var note: String = ""
    @Published var hasCopied: Bool = false
    @Published var isSending: Bool = false
    @Published var receivedNotes: [LoveNote] = []
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    private let cloudKitService: any CloudKitServiceProtocol
    private var notificationObserver: Any?

    init(cloudKitService: any CloudKitServiceProtocol) {
        self.cloudKitService = cloudKitService

        // BUG 4 FIX: listen for CloudKit push notifications and refresh notes.
        // handleNotification() in CloudKitService posts this after receiving a silent push.
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .pekisCloudKitDataChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { await self?.fetchNotes() }
        }
    }

    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    var hasNotes: Bool {
        !receivedNotes.isEmpty
    }

    var currentUserID: String? {
        cloudKitService.currentUserID
    }

    func copyNote() {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        UIPasteboard.general.string = trimmed
        hasCopied = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            hasCopied = false
        }
    }

    func sendNote() async {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        defer { isSending = false }

        do {
            try await cloudKitService.sendLoveNote(content: trimmed)
            note = ""
            HapticManager.notification(type: .success)
            await fetchNotes()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func fetchNotes() async {
        do {
            receivedNotes = try await cloudKitService.fetchLoveNotes()
        } catch {
            // BUG 6 FIX: was setting errorMessage but never showing the alert.
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
