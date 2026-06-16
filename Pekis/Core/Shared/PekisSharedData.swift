import Foundation

/// Lightweight, dependency-free snapshot of the couple's countdown state.
///
/// This is the single value the main app and the widget extension exchange
/// through their shared App Group container. It deliberately knows nothing
/// about CloudKit — the app projects its `Couple` into this struct and the
/// widget reads it back. Keeping it Foundation-only means it compiles into
/// both targets without dragging CloudKit into the extension.
struct CountdownSnapshot: Codable, Equatable {
    /// The date the partners next see each other, if one has been set.
    var reunionDate: Date?
    /// The other partner's display name (resolved for the local user).
    var partnerName: String?
    /// Whether a partner has actually joined the couple.
    var isPaired: Bool
    /// When the couple was created — used to draw an elapsed-progress ring.
    var startDate: Date?

    init(
        reunionDate: Date? = nil,
        partnerName: String? = nil,
        isPaired: Bool = false,
        startDate: Date? = nil
    ) {
        self.reunionDate = reunionDate
        self.partnerName = partnerName
        self.isPaired = isPaired
        self.startDate = startDate
    }
}

// MARK: - Configuration

enum PekisSharedConfig {
    /// Reads the App Group identifier injected into each target's Info.plist
    /// (`group.<bundle-id>`). Falling back keeps previews and tests alive when
    /// the key is absent.
    static var appGroupID: String {
        let raw = Bundle.main.object(forInfoDictionaryKey: "PEKIS_APP_GROUP_ID") as? String
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            return trimmed
        }
        return "group.com.pekis.shared"
    }
}

// MARK: - Shared store

/// A tiny wrapper over the App Group `UserDefaults` the app writes and the
/// widget reads. Both sides go through these two functions so the storage key
/// and encoding can never drift apart.
enum PekisSharedStore {
    private static let snapshotKey = "pekis.countdown.snapshot"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: PekisSharedConfig.appGroupID)
    }

    static func save(_ snapshot: CountdownSnapshot) {
        guard let defaults, let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    static func load() -> CountdownSnapshot? {
        guard let defaults,
              let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(CountdownSnapshot.self, from: data)
        else {
            return nil
        }
        return snapshot
    }
}
