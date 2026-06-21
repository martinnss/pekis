import WidgetKit
import SwiftUI

/// Routes each widget family to its layout.
struct CountdownWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CountdownEntry

    var body: some View {
        switch family {
        case .systemMedium:
            MediumCountdownView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        default:
            SmallCountdownView(entry: entry)
        }
    }
}

// MARK: - Static Widget Mascot

/// A fully static, self-contained Peki cat for widget rendering.
/// No @State, no UIColor, no external dependencies.
private struct WidgetCat: View {
    var size: CGFloat = 72
    /// heart eyes instead of normal eyes
    var celebrate: Bool = false

    private let body1 = WidgetPalette.coralLight
    private let body2 = WidgetPalette.coral
    private let bodyD = WidgetPalette.coralDark
    private let berry = WidgetPalette.berry
    private let ink   = Color(red: 0.227, green: 0.18, blue: 0.212)

    var body: some View {
        ZStack {
            tail
            ears
            catBody
            face
            paws
        }
        .frame(width: size, height: size)
    }

    // MARK: Tail

    private var tail: some View {
        CatTailShape()
            .stroke(
                LinearGradient(colors: [body2, body1], startPoint: .bottom, endPoint: .top),
                style: StrokeStyle(lineWidth: size * 0.12, lineCap: .round)
            )
            .frame(width: size * 0.5, height: size * 0.5)
            .offset(x: size * 0.34, y: size * 0.18)
    }

    // MARK: Ears

    private var ears: some View {
        HStack(spacing: size * 0.30) {
            singleEar.rotationEffect(.degrees(-8), anchor: .bottom)
            singleEar.scaleEffect(x: -1).rotationEffect(.degrees(8), anchor: .bottom)
        }
        .offset(y: -size * 0.27)
    }

    private var singleEar: some View {
        CatEarShape()
            .fill(body2)
            .overlay(
                CatEarShape()
                    .fill(berry.opacity(0.4))
                    .scaleEffect(0.5, anchor: .bottom)
            )
            .overlay(CatEarShape().stroke(bodyD.opacity(0.4), lineWidth: 1.5))
            .frame(width: size * 0.26, height: size * 0.28)
    }

    // MARK: Body

    private var catBody: some View {
        Ellipse()
            .fill(LinearGradient(colors: [body1, body2], startPoint: .top, endPoint: .bottom))
            .frame(width: size * 0.82, height: size * 0.78)
            .overlay(Ellipse().stroke(bodyD.opacity(0.4), lineWidth: 1.5))
            .offset(y: size * 0.07)
            .shadow(color: body2.opacity(0.25), radius: 8, y: 6)
    }

    // MARK: Face

    private var face: some View {
        ZStack {
            whiskers

            HStack(spacing: size * 0.20) {
                leftEye
                rightEye
            }
            .offset(y: -size * 0.01)

            // Blush cheeks
            HStack(spacing: size * 0.44) {
                blush
                blush
            }
            .offset(y: size * 0.12)

            // Heart nose (upside-down)
            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.07))
                .foregroundStyle(berry)
                .rotationEffect(.degrees(180))
                .offset(y: size * 0.10)
        }
        .offset(y: size * 0.02)
    }

    @ViewBuilder
    private var leftEye: some View {
        if celebrate {
            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.16))
                .foregroundStyle(berry)
        } else {
            ZStack {
                Capsule().fill(ink).frame(width: size * 0.11, height: size * 0.14)
                Circle().fill(.white).frame(width: size * 0.04, height: size * 0.04)
                    .offset(x: size * 0.02, y: -size * 0.03)
            }
        }
    }

    @ViewBuilder
    private var rightEye: some View {
        if celebrate {
            Image(systemName: "heart.fill")
                .font(.system(size: size * 0.16))
                .foregroundStyle(berry)
        } else {
            ZStack {
                Capsule().fill(ink).frame(width: size * 0.11, height: size * 0.14)
                Circle().fill(.white).frame(width: size * 0.04, height: size * 0.04)
                    .offset(x: size * 0.02, y: -size * 0.03)
            }
        }
    }

    private var blush: some View {
        Ellipse()
            .fill(berry.opacity(0.3))
            .frame(width: size * 0.13, height: size * 0.085)
    }

    private var whiskers: some View {
        HStack(spacing: size * 0.30) {
            CatWhiskerShape()
                .stroke(ink.opacity(0.45), style: StrokeStyle(lineWidth: size * 0.012, lineCap: .round))
                .frame(width: size * 0.24, height: size * 0.16)
            CatWhiskerShape()
                .stroke(ink.opacity(0.45), style: StrokeStyle(lineWidth: size * 0.012, lineCap: .round))
                .scaleEffect(x: -1)
                .frame(width: size * 0.24, height: size * 0.16)
        }
        .offset(y: size * 0.12)
    }

    // MARK: Paws

    private var paws: some View {
        HStack {
            Ellipse()
                .fill(bodyD)
                .frame(width: size * 0.18, height: size * 0.14)
                .overlay(Ellipse().stroke(bodyD.opacity(0.4), lineWidth: 1.5))
                .rotationEffect(.degrees(-6), anchor: .top)
            Spacer()
            Ellipse()
                .fill(bodyD)
                .frame(width: size * 0.18, height: size * 0.14)
                .overlay(Ellipse().stroke(bodyD.opacity(0.4), lineWidth: 1.5))
                .rotationEffect(.degrees(6), anchor: .top)
        }
        .frame(width: size * 0.78)
        .offset(y: size * 0.26)
    }
}

// MARK: - Shapes

private struct CatEarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.midX + rect.width * 0.12, y: rect.minY),
            control: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.1)
        )
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.45)
        )
        p.closeSubpath()
        return p
    }
}

private struct CatWhiskerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let ox = rect.maxX
        let my = rect.midY
        p.move(to: CGPoint(x: ox, y: my))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.1))
        p.move(to: CGPoint(x: ox, y: my))
        p.addLine(to: CGPoint(x: rect.minX, y: my))
        p.move(to: CGPoint(x: ox, y: my))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - rect.height * 0.1))
        return p
    }
}

private struct CatTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addCurve(
            to: CGPoint(x: rect.maxX * 0.85, y: rect.minY + rect.height * 0.18),
            control1: CGPoint(x: rect.maxX * 0.6, y: rect.maxY),
            control2: CGPoint(x: rect.maxX, y: rect.midY)
        )
        return p
    }
}

// MARK: - Helpers

private func formattedTarget(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "EEE, MMM d"
    return f.string(from: date)
}

// MARK: - Small (home screen)

private struct SmallCountdownView: View {
    let entry: CountdownEntry

    var body: some View {
        if let days = entry.daysRemaining {
            VStack(alignment: .leading, spacing: 0) {
                // Label
                Text(entry.configuration.label.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(WidgetPalette.inkSoft)
                    .lineLimit(1)

                Spacer(minLength: 4)

                if days == 0 {
                    Text("Today! 🎉")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(WidgetPalette.purple)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                } else {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text("\(days)")
                            .font(.system(size: 52, weight: .heavy, design: .rounded))
                            .foregroundStyle(WidgetPalette.purple)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                            .contentTransition(.numericText())
                        Text(days == 1 ? "day" : "days")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(WidgetPalette.inkSoft)
                            .padding(.bottom, 7)
                    }
                }

                Spacer(minLength: 4)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        if entry.configuration.showPartnerName,
                           let name = entry.snapshot.partnerName, !name.isEmpty,
                           !entry.configuration.useCustomDate {
                            Text("with \(name)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(WidgetPalette.coral)
                                .lineLimit(1)
                        }
                        if let target = entry.targetDate {
                            Text(formattedTarget(target))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(WidgetPalette.inkSoft)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                    WidgetCat(size: 44, celebrate: entry.daysRemaining == 0)
                        .offset(x: 6, y: 10)
                }
            }
        } else {
            SmallEmptyStateView()
        }
    }
}

// MARK: - Medium (home screen)

private struct MediumCountdownView: View {
    let entry: CountdownEntry

    var body: some View {
        if let days = entry.daysRemaining {
            HStack(spacing: 0) {
                // Left: text content
                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.configuration.label.uppercased())
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(WidgetPalette.inkSoft)
                        .lineLimit(1)

                    if entry.configuration.showPartnerName,
                       let name = entry.snapshot.partnerName, !name.isEmpty,
                       !entry.configuration.useCustomDate {
                        Text("with \(name)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(WidgetPalette.coral)
                            .lineLimit(1)
                    }

                    if days == 0 {
                        Text("Today! 🎉")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .foregroundStyle(WidgetPalette.purple)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    } else {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(days)")
                                .font(.system(size: 56, weight: .heavy, design: .rounded))
                                .foregroundStyle(WidgetPalette.purple)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .contentTransition(.numericText())
                            Text(days == 1 ? "day" : "days")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(WidgetPalette.inkSoft)
                                .padding(.bottom, 8)
                        }
                    }

                    Spacer(minLength: 0)

                    if let target = entry.targetDate {
                        HStack(spacing: 5) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10, weight: .bold))
                            Text(formattedTarget(target))
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(WidgetPalette.inkSoft)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right: mascot
                WidgetCat(size: 84, celebrate: days == 0)
                    .frame(width: 96)
                    .padding(.trailing, 4)
            }
            .padding(.vertical, 2)
        } else {
            MediumEmptyStateView()
        }
    }
}

// MARK: - Empty states

private struct SmallEmptyStateView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            WidgetCat(size: 48, celebrate: false)
            Spacer(minLength: 0)
            Text("Set a date")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(WidgetPalette.ink)
            Text("Open Pekis to start your countdown.")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(WidgetPalette.inkSoft)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

private struct MediumEmptyStateView: View {
    var body: some View {
        HStack(spacing: 16) {
            WidgetCat(size: 72, celebrate: false)
            VStack(alignment: .leading, spacing: 6) {
                Text("Set your next visit")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.ink)
                Text("Open Pekis and tap the countdown card to pick a date.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(WidgetPalette.inkSoft)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

#Preview("Small – Today", as: .systemSmall) {
    PekisCountdownWidget()
} timeline: {
    CountdownEntry(
        date: .now,
        configuration: CountdownConfigIntent(),
        snapshot: CountdownSnapshot(
            reunionDate: .now,
            partnerName: "Sam",
            isPaired: true,
            startDate: Calendar.current.date(byAdding: .day, value: -14, to: .now)
        )
    )
}
