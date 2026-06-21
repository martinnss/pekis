import AppIntents
import WidgetKit

/// The widget's user-facing configuration. Long-pressing the widget → Edit
/// surfaces every one of these parameters.
///
/// Two modes are supported:
/// - **Shared** (default): the countdown follows the reunion date the couple
///   set inside the app, so both partners' widgets stay in sync.
/// - **Personal**: flip on "Use my own date" to point the widget at any date
///   with any label — perfect for someone who just wants a private countdown.
struct CountdownConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Countdown" }
    static var description: IntentDescription {
        IntentDescription("Count down to the moment you reunite — or to any date you choose.")
    }

    @Parameter(title: "Label", default: "Until we reunite")
    var label: String

    @Parameter(title: "Show partner's name", default: true)
    var showPartnerName: Bool

    @Parameter(title: "Use my own date", default: false)
    var useCustomDate: Bool

    @Parameter(title: "My date")
    var customDate: Date?
}
