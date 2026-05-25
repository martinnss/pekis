import CloudKit
import Combine
import Foundation
import SwiftUI

/// ViewModel for the couple onboarding flow
@MainActor
final class CoupleOnboardingViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var step: OnboardingStep = .welcome
    @Published var userName: String = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showShareSheet = false
    @Published var showJoinInstructions = false
    @Published var shareURL: URL?

    // MARK: - Private Properties

    private var cloudKitService: (any CloudKitServiceProtocol)?

    // MARK: - Onboarding Steps

    enum OnboardingStep {
        case welcome
        case enterName
        case createOrJoin
        case waitingForPartner
        case complete
    }

    // MARK: - Public Methods

    func setCloudKitService(_ service: any CloudKitServiceProtocol) {
        self.cloudKitService = service

        if service.needsPartnerName {
            // Partner B just accepted a share — prompt for their name
            step = .enterName
        } else if service.isPaired {
            step = .complete
        } else if service.couple != nil {
            // Couple exists but partner hasn't joined — show waiting screen
            Task { await fetchShareURL() }
            step = .waitingForPartner
        }
    }

    /// Called from EnterNameStepView's Continue button.
    /// For Partner B (needsPartnerName), saves the name and completes.
    /// For Partner A, advances to the create-or-join step.
    func continueFromNameEntry() async {
        guard let service = cloudKitService else {
            withAnimation { step = .createOrJoin }
            return
        }

        if service.needsPartnerName {
            isLoading = true
            defer { isLoading = false }
            do {
                try await service.updateMyName(userName)
                service.needsPartnerName = false
                withAnimation { step = .complete }
            } catch {
                showErrorMessage(error.localizedDescription)
            }
        } else {
            withAnimation { step = .createOrJoin }
        }
    }

    /// Fetch the share URL for an existing couple
    func fetchShareURL() async {
        guard let service = cloudKitService else { return }

        do {
            let share = try await service.getOrCreateShare()

            if let url = share.url {
                shareURL = url
            } else {
                // Retry after a brief delay
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                let retryShare = try await service.getOrCreateShare()

                if let url = retryShare.url {
                    shareURL = url
                } else {
                    showErrorMessage("Share link is not available yet. Please try again in a moment.")
                }
            }
        } catch {
            showErrorMessage("Could not get invite link: \(error.localizedDescription)")
        }
    }

    func createCouple() async {
        guard let service = cloudKitService else {
            showErrorMessage("Service not available")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await service.createCouple(name: userName)

            // Wait for the couple record to be fully persisted in CloudKit
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            // Get share URL
            let share = try await service.getOrCreateShare()

            guard let shareURL = share.url else {
                showErrorMessage("Share link was created but URL is not available. Please try again.")
                return
            }

            self.shareURL = shareURL
            showShareSheet = true

            // Move to waiting state
            step = .waitingForPartner
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }

    func checkPartnerJoined() async {
        guard let service = cloudKitService else { return }

        isLoading = true
        defer { isLoading = false }

        await service.checkExistingCouple()

        if service.isPaired {
            step = .complete
        }
    }

    // MARK: - Private Methods

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}
