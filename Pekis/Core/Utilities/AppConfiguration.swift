import Foundation
import OSLog

enum AppConfiguration {
    private static let cloudKitContainerKey = "PEKIS_CLOUDKIT_CONTAINER_ID"

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Pekis"
    }

    static var cloudKitContainerIdentifier: String {
        let fallback = "iCloud.\(bundleIdentifier)"

        guard let configured = infoValue(for: cloudKitContainerKey) else {
            return fallback
        }

        if isUnresolvedBuildVariable(configured) {
            Logger(
                subsystem: Bundle.main.bundleIdentifier ?? "Pekis",
                category: "AppConfiguration"
            ).warning(
                "Unresolved CloudKit container ID '\(configured, privacy: .public)'; using fallback '\(fallback, privacy: .public)'"
            )
            return fallback
        }

        return configured
    }

    private static func infoValue(for key: String) -> String? {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    /// Xcode build settings that fail to resolve are copied into Info.plist literally.
    private static func isUnresolvedBuildVariable(_ value: String) -> Bool {
        value.hasPrefix("$(") || value.contains("$(")
    }
}
