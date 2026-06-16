import Foundation
import WidgetKit

/// Bridges the app's CloudKit-backed `Couple` into the App Group snapshot the
/// widget reads, then asks WidgetKit to refresh. Lives only in the app target.
enum WidgetBridge {
    /// Projects the current couple into a `CountdownSnapshot`, persists it to the
    /// shared store, and reloads every widget timeline. Safe to call from any
    /// site that mutates the couple — it is cheap and idempotent.
    @MainActor
    static func update(couple: Couple?, currentUserID: String?) {
        let snapshot: CountdownSnapshot

        if let couple {
            snapshot = CountdownSnapshot(
                reunionDate: couple.reunionDate,
                partnerName: partnerName(in: couple, currentUserID: currentUserID),
                isPaired: couple.partnerBIdentifier != nil,
                startDate: couple.createdAt
            )
        } else {
            snapshot = CountdownSnapshot()
        }

        let previous = PekisSharedStore.load()
        guard previous != snapshot else { return }

        PekisSharedStore.save(snapshot)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Resolves the *other* partner's name from the local user's perspective.
    private static func partnerName(in couple: Couple, currentUserID: String?) -> String? {
        guard let currentUserID else { return couple.partnerBName ?? couple.partnerAName }
        if couple.partnerAIdentifier == currentUserID {
            return couple.partnerBName
        }
        return couple.partnerAName
    }
}
