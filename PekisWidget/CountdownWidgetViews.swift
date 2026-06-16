import WidgetKit
import SwiftUI

/// Routes each widget family to a layout tuned for its size and rendering mode.
struct CountdownWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CountdownEntry

    private var theme: WidgetTheme { WidgetTheme.palette(for: entry.configuration.theme) }

    var body: some View {
        switch family {
        case .systemMedium:
            MediumCountdownView(entry: entry, theme: theme)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        default:
            SmallCountdownView(entry: entry, theme: theme)
        }
    }
}

// MARK: - Shared building blocks

/// A large, soft-shadowed numeral with a subtle top-down sheen so it reads as
/// a sculpted object rather than flat text.
private struct CountdownNumber: View {
    let value: Int
    let size: CGFloat

    var body: some View {
        Text("\(value)")
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, .white.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .contentTransition(.numericText())
    }
}

/// Uppercase, letter-spaced caption used for labels — small typographic touch
/// that keeps the layout from feeling generic.
private struct Eyebrow: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(1.4)
            .foregroundStyle(color)
            .lineLimit(1)
    }
}

private struct ProgressRing: View {
    let progress: Double
    let theme: WidgetTheme
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.ringTrack, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.02, progress))
                .stroke(
                    AngularGradient(
                        colors: [theme.accent.opacity(0.7), theme.accent, .white],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: theme.accent.opacity(0.5), radius: 4)
        }
    }
}

private func formattedTarget(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE, MMM d"
    return formatter.string(from: date)
}

// MARK: - Small (home screen)

private struct SmallCountdownView: View {
    let entry: CountdownEntry
    let theme: WidgetTheme

    var body: some View {
        if let days = entry.daysRemaining {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Eyebrow(text: entry.configuration.label, color: theme.secondaryText)
                    Spacer(minLength: 0)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.accent)
                }

                Spacer(minLength: 4)

                if days == 0 {
                    Text("Today")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                } else {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        CountdownNumber(value: days, size: 56)
                        Text(days == 1 ? "day" : "days")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.secondaryText)
                            .padding(.bottom, 8)
                    }
                }

                Spacer(minLength: 4)

                if entry.configuration.showPartnerName,
                   let name = entry.snapshot.partnerName, !name.isEmpty,
                   !entry.configuration.useCustomDate {
                    Text("with \(name)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.secondaryText)
                        .lineLimit(1)
                } else if let target = entry.targetDate {
                    Text(formattedTarget(target))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.secondaryText)
                        .lineLimit(1)
                }
            }
            .overlay(alignment: .topTrailing) {
                if let progress = entry.progress {
                    ProgressRing(progress: progress, theme: theme, lineWidth: 4)
                        .frame(width: 26, height: 26)
                        .offset(y: 22)
                }
            }
        } else {
            EmptyStateView(theme: theme, compact: true)
        }
    }
}

// MARK: - Medium (home screen)

private struct MediumCountdownView: View {
    let entry: CountdownEntry
    let theme: WidgetTheme

    var body: some View {
        if let days = entry.daysRemaining {
            HStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: entry.configuration.label, color: theme.secondaryText)

                    if entry.configuration.showPartnerName,
                       let name = entry.snapshot.partnerName, !name.isEmpty,
                       !entry.configuration.useCustomDate {
                        Text("with \(name)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.accent)
                            .lineLimit(1)
                    }

                    if days == 0 {
                        Text("Today 🎉")
                            .font(.system(size: 34, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    } else {
                        HStack(alignment: .lastTextBaseline, spacing: 6) {
                            CountdownNumber(value: days, size: 60)
                            Text(days == 1 ? "day" : "days")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.secondaryText)
                                .padding(.bottom, 9)
                        }
                    }

                    Spacer(minLength: 0)

                    if let target = entry.targetDate {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11, weight: .bold))
                            Text(formattedTarget(target))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(theme.secondaryText)
                    }
                }

                Spacer(minLength: 0)

                ZStack {
                    if let progress = entry.progress {
                        ProgressRing(progress: progress, theme: theme, lineWidth: 8)
                        VStack(spacing: 1) {
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 20, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                            Text("there")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.secondaryText)
                        }
                    } else {
                        Circle()
                            .fill(.white.opacity(0.12))
                        Image(systemName: "heart.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(theme.accent)
                            .shadow(color: theme.accent.opacity(0.6), radius: 8)
                    }
                }
                .frame(width: 96, height: 96)
            }
        } else {
            EmptyStateView(theme: theme, compact: false)
        }
    }
}

// MARK: - Empty state

private struct EmptyStateView: View {
    let theme: WidgetTheme
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: compact ? 28 : 34, weight: .semibold))
                .foregroundStyle(theme.accent)
                .shadow(color: theme.accent.opacity(0.5), radius: 8)
            Spacer(minLength: 0)
            Text("Set your date")
                .font(.system(size: compact ? 17 : 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Open Pekis to pick the day you'll be together.")
                .font(.system(size: compact ? 11 : 13, weight: .medium, design: .rounded))
                .foregroundStyle(theme.secondaryText)
                .lineLimit(compact ? 2 : 3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Lock screen accessories

private struct AccessoryRectangularView: View {
    let entry: CountdownEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(entry.configuration.label)
                .font(.caption2)
                .widgetAccentable()
            if let days = entry.daysRemaining {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(days)")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                    Text(days == 1 ? "day" : "days")
                        .font(.caption)
                }
                if entry.configuration.showPartnerName,
                   let name = entry.snapshot.partnerName, !name.isEmpty,
                   !entry.configuration.useCustomDate {
                    Text("with \(name)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Set your date")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct AccessoryCircularView: View {
    let entry: CountdownEntry

    var body: some View {
        if let days = entry.daysRemaining {
            Gauge(value: entry.progress ?? 0) {
                Image(systemName: "heart.fill")
            } currentValueLabel: {
                Text("\(days)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
            }
            .gaugeStyle(.accessoryCircular)
            .widgetAccentable()
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "calendar.badge.plus")
                    .font(.title3)
            }
        }
    }
}

private struct AccessoryInlineView: View {
    let entry: CountdownEntry

    var body: some View {
        if let days = entry.daysRemaining {
            if days == 0 {
                Label("Together today!", systemImage: "heart.fill")
            } else {
                Label("\(days) \(days == 1 ? "day" : "days") to go", systemImage: "heart.fill")
            }
        } else {
            Label("Set your date", systemImage: "calendar.badge.plus")
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    PekisCountdownWidget()
} timeline: {
    CountdownEntry(
        date: .now,
        configuration: CountdownConfigIntent(),
        snapshot: CountdownSnapshot(
            reunionDate: Calendar.current.date(byAdding: .day, value: 28, to: .now),
            partnerName: "Alex",
            isPaired: true,
            startDate: Calendar.current.date(byAdding: .day, value: -34, to: .now)
        )
    )
}

#Preview("Medium", as: .systemMedium) {
    PekisCountdownWidget()
} timeline: {
    CountdownEntry(
        date: .now,
        configuration: CountdownConfigIntent(),
        snapshot: CountdownSnapshot(
            reunionDate: Calendar.current.date(byAdding: .day, value: 12, to: .now),
            partnerName: "Sam",
            isPaired: true,
            startDate: Calendar.current.date(byAdding: .day, value: -60, to: .now)
        )
    )
}
