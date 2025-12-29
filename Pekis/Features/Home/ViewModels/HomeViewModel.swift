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
//        case momentShare
    }

    @Published var screen: Screen = .dashboard
    @Published var lastScore: Int = 0
    @Published var isEditingReunionDate: Bool = false

    private let calendar = Calendar.current
    private let cloudKitService: CloudKitServiceProtocol

    init(cloudKitService: CloudKitServiceProtocol) {
        self.cloudKitService = cloudKitService
    }

    var couple: Couple? {
        cloudKitService.couple
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
}
