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

    private let cloudKitService: CloudKitServiceProtocol

    init(cloudKitService: CloudKitServiceProtocol) {
        self.cloudKitService = cloudKitService
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
            // Silently fail - will show cached notes
            errorMessage = error.localizedDescription
        }
    }
}
