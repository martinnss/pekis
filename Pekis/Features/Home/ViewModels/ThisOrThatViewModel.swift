import Combine
import Foundation
import UIKit

@MainActor
final class ThisOrThatViewModel: ObservableObject {
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var selectedOption: Int?
    @Published private(set) var partnerAnswer: Int?
    @Published private(set) var allAnswers: [ThisOrThatAnswer] = []
    @Published private(set) var comparisons: [ThisOrThatComparison] = []
    @Published var isLoading: Bool = false
    @Published var showReveal: Bool = false

    private let cloudKitService: CloudKitServiceProtocol

    init(cloudKitService: CloudKitServiceProtocol) {
        self.cloudKitService = cloudKitService
    }

    var currentPair: [String] {
        guard !AppContent.thisOrThatPairs.isEmpty else { return [] }
        return AppContent.thisOrThatPairs[currentIndex]
    }

    var currentUserID: String? {
        cloudKitService.currentUserID
    }

    var bothAnswered: Bool {
        selectedOption != nil && partnerAnswer != nil
    }

    var isMatch: Bool {
        guard let my = selectedOption, let partner = partnerAnswer else { return false }
        return my == partner
    }

    func loadAnswers() async {
        isLoading = true
        defer { isLoading = false }

        do {
            allAnswers = try await cloudKitService.fetchThisOrThatAnswers()
            updateCurrentQuestionState()
            updateComparisons()
        } catch {
            // Silently fail - will show cached
        }
    }

    func select(option: Int) {
        guard currentPair.indices.contains(option) else { return }
        selectedOption = option

        // Save to CloudKit
        Task {
            do {
                try await cloudKitService.saveThisOrThatAnswer(
                    questionIndex: currentIndex,
                    selectedOption: option
                )
                // Refresh to get partner's answer
                await loadAnswers()
            } catch {
                // Revert on error
                selectedOption = nil
            }
        }
    }

    func nextPair() {
        guard !AppContent.thisOrThatPairs.isEmpty else { return }

        // Move to next question
        currentIndex = (currentIndex + 1) % AppContent.thisOrThatPairs.count
        selectedOption = nil
        partnerAnswer = nil
        showReveal = false

        // Update state for new question
        updateCurrentQuestionState()
    }

    func revealPartnerAnswer() {
        showReveal = true
        HapticManager.impact(style: .medium)
    }

    private func updateCurrentQuestionState() {
        guard let userID = currentUserID else { return }

        let answersForCurrentQuestion = allAnswers.filter { $0.questionIndex == currentIndex }

        // Find my answer
        if let myAnswer = answersForCurrentQuestion.first(where: { $0.authorID == userID }) {
            selectedOption = myAnswer.selectedOption
        } else {
            selectedOption = nil
        }

        // Find partner's answer
        if let partnerAnswerRecord = answersForCurrentQuestion.first(where: { $0.authorID != userID }) {
            partnerAnswer = partnerAnswerRecord.selectedOption
        } else {
            partnerAnswer = nil
        }
    }

    private func updateComparisons() {
        guard let userID = currentUserID else { return }
        comparisons = allAnswers.createComparisons(
            currentUserID: userID,
            questionCount: AppContent.thisOrThatPairs.count
        )
    }
}
