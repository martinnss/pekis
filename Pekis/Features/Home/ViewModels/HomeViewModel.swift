import CloudKit
import Combine
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    enum Screen: Equatable {
        case dashboard
        case wordSearch
        case result
        case topics
        case dateRoulette
        case thisOrThat
        case loveNote
        case momentShare
    }

    @Published var screen: Screen = .dashboard
    @Published var lastScore: Int = 0
    @Published var isEditingReunionDate: Bool = false
    @Published var shareURL: URL?
    @Published var isLoadingShare = false

    private let calendar = Calendar.current
    private let cloudKitService: any CloudKitServiceProtocol

    init(cloudKitService: any CloudKitServiceProtocol) {
        self.cloudKitService = cloudKitService
    }

    var couple: Couple? {
        cloudKitService.couple
    }

    var isPaired: Bool {
        cloudKitService.isPaired
    }

    var inviteMessage: String {
        guard let url = shareURL else { return "" }
        // BUG 5 FIX: removed fake App Store placeholder URL
        return """
        Hey! Let's connect on Pekis ❤️

        Tap this link on your iPhone to pair with me:
        \(url.absoluteString)

        Can't wait to see you there! 🚀
        """
    }

    var quoteForToday: String {
        guard !AppContent.quotes.isEmpty else { return "" }
        let index = max(0, calendar.component(.day, from: Date()) - 1) % AppContent.quotes.count
        return AppContent.quotes[index]
    }

    var visitDateText: String {
        guard let reunionDate = couple?.reunionDate else { return "Set a date" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: reunionDate)
    }

    var daysUntilVisit: Int {
        guard let reunionDate = couple?.reunionDate else { return 0 }
        let components = calendar.dateComponents([.day], from: Date(), to: reunionDate)
        return max(0, components.day ?? 0)
    }

    var hasReunionDate: Bool {
        couple?.reunionDate != nil
    }

    var partnerName: String {
        guard let couple = couple, let userID = cloudKitService.currentUserID else { return "Partner" }

        if couple.partnerAIdentifier == userID {
            return couple.partnerBName ?? "Partner"
        } else {
            return couple.partnerAName
        }
    }

    func show(_ screen: Screen) {
        self.screen = screen
    }

    func handleWordSearchFinished(score: Int) {
        lastScore = score
        screen = .result
    }

    func updateReunionDate(_ date: Date) async {
        do {
            try await cloudKitService.updateReunionDate(date)
            isEditingReunionDate = false
            HapticManager.notification(type: .success)
        } catch {
            // Handle error
        }
    }

    func fetchShareURL() async {
        isLoadingShare = true
        defer { isLoadingShare = false }

        do {
            let share = try await cloudKitService.getOrCreateShare()
            if let url = share.url {
                shareURL = url
            } else {
                // Retry once
                try await Task.sleep(nanoseconds: 1_000_000_000)
                let retryShare = try await cloudKitService.getOrCreateShare()
                shareURL = retryShare.url
            }
        } catch {
            print("Error fetching share URL: \(error)")
        }
    }
}
