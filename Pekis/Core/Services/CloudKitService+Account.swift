import Foundation
import CloudKit
import OSLog

// Reacts to the user signing out of, or switching, their iCloud account while the app is running.
@MainActor
extension CloudKitService {
    /// Starts listening for `.CKAccountChanged`. Safe to call more than once.
    func startMonitoringAccount() {
        guard accountObserver == nil else { return }
        accountObserver = NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in await self?.handleAccountChange() }
        }
    }

    func handleAccountChange() async {
        let status = (try? await container.accountStatus()) ?? .couldNotDetermine
        accountStatus = status

        var newUserID: String?
        if status == .available {
            newUserID = try? await withRetry { try await container.userRecordID() }.recordName
        }

        let transition = AccountTransition.determine(
            previousUserID: currentUserID,
            status: status,
            currentUserID: newUserID
        )
        PekisLogger.cloudKit.notice("iCloud account changed: \(String(describing: transition), privacy: .public)")

        switch transition {
        case .unchanged:
            break
        case .signedOut:
            // Keep cached data visible; just explain why syncing has stopped.
            errorMessage = CloudKitError.notAuthenticated.errorDescription
        case .signedIn:
            errorMessage = nil
            await setup()
        case .switchedAccount:
            // Never show one iCloud user's couple data to another.
            resetLocalState()
            await setup()
        }
    }
}
