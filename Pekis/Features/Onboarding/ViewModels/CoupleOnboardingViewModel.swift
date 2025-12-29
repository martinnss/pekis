import CloudKit
import Combine
import Foundation

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

    private var cloudKitService: CloudKitService?

    // MARK: - Onboarding Steps

    enum OnboardingStep {
        case welcome
        case enterName
        case createOrJoin
        case waitingForPartner
        case complete
    }

    // MARK: - Public Methods

    func setCloudKitService(_ service: CloudKitService) {
        self.cloudKitService = service

        // If already paired, skip to complete
        if service.isPaired {
            step = .complete
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

            // Get share URL
            let share = try await service.getOrCreateShare()
            shareURL = share.url
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
