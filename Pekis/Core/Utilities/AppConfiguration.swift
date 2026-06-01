import Foundation

enum AppConfiguration {
    private static let cloudKitContainerKey = "PEKIS_CLOUDKIT_CONTAINER_ID"

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Pekis"
    }

    static var cloudKitContainerIdentifier: String {
        infoValue(for: cloudKitContainerKey) ?? "iCloud.\(bundleIdentifier)"
    }

    private static func infoValue(for key: String) -> String? {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
