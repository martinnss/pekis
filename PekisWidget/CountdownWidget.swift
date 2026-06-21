import WidgetKit
import SwiftUI

/// One rendered moment in the widget's timeline.
struct CountdownEntry: TimelineEntry {
    let date: Date
    let configuration: CountdownConfigIntent
    let snapshot: CountdownSnapshot

    /// The date being counted toward, honouring the personal-date override.
    var targetDate: Date? {
        if configuration.useCustomDate {
            return configuration.customDate
        }
        return snapshot.reunionDate
    }

    /// Whole days from this entry's day to the target day (never negative).
    var daysRemaining: Int? {
        guard let targetDate else { return nil }
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: date)
        let to = calendar.startOfDay(for: targetDate)
        let days = calendar.dateComponents([.day], from: from, to: to).day ?? 0
        return max(0, days)
    }

    /// Elapsed fraction of the journey, for the progress ring. Only available
    /// in shared mode where we know when the couple started.
    var progress: Double? {
        guard !configuration.useCustomDate,
              let start = snapshot.startDate,
              let target = snapshot.reunionDate,
              target > start else { return nil }
        let total = target.timeIntervalSince(start)
        let done = date.timeIntervalSince(start)
        return min(1, max(0, done / total))
    }
}

struct CountdownProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(
            date: Date(),
            configuration: CountdownConfigIntent(),
            snapshot: CountdownSnapshot(
                reunionDate: Calendar.current.date(byAdding: .day, value: 28, to: Date()),
                partnerName: "Alex",
                isPaired: true,
                startDate: Calendar.current.date(byAdding: .day, value: -34, to: Date())
            )
        )
    }

    func snapshot(for configuration: CountdownConfigIntent, in context: Context) async -> CountdownEntry {
        CountdownEntry(
            date: Date(),
            configuration: configuration,
            snapshot: PekisSharedStore.load() ?? placeholder(in: context).snapshot
        )
    }

    func timeline(for configuration: CountdownConfigIntent, in context: Context) async -> Timeline<CountdownEntry> {
        let snapshot = PekisSharedStore.load() ?? CountdownSnapshot()
        let calendar = Calendar.current
        let now = Date()

        // One entry per upcoming local midnight so the day count ticks down on
        // its own without waking the process; refresh the whole timeline daily.
        var entries: [CountdownEntry] = []
        let startOfToday = calendar.startOfDay(for: now)
        for dayOffset in 0..<14 {
            guard let entryDate = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) else { continue }
            let stamp = dayOffset == 0 ? now : entryDate
            entries.append(CountdownEntry(date: stamp, configuration: configuration, snapshot: snapshot))
        }

        let refresh = calendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now.addingTimeInterval(3600)
        return Timeline(entries: entries, policy: .after(refresh))
    }
}

struct PekisCountdownWidget: Widget {
    let kind = "PekisCountdownWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: CountdownConfigIntent.self,
            provider: CountdownProvider()
        ) { entry in
            CountdownWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetPalette.background
                }
        }
        .configurationDisplayName("Together Countdown")
        .description("Count the days until you're together again.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline
        ])
    }
}
