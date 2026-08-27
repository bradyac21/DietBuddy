import WidgetKit
import SwiftUI

// MARK: - Shared snapshot (mirrors the app's DaySnapshot by JSON field names)

struct DaySnapshot: Codable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var calorieGoal: Double?
    var proteinGoal: Double?
    var carbGoal: Double?
    var fatGoal: Double?
    var date: Date
}

enum WidgetSharedStore {
    static let appGroupID = "group.com.bradycarden.DietBuddy"
    static let snapshotKey = "daySnapshot"

    static func load() -> DaySnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(DaySnapshot.self, from: data)
    }
}

// MARK: - Timeline

struct MacroEntry: TimelineEntry {
    let date: Date
    let snapshot: DaySnapshot?
}

struct MacroProvider: TimelineProvider {
    private static let sample = DaySnapshot(calories: 1450, protein: 120, carbs: 130, fat: 45,
                                            calorieGoal: 2000, proteinGoal: 180, carbGoal: 180, fatGoal: 60,
                                            date: .now)

    func placeholder(in context: Context) -> MacroEntry {
        MacroEntry(date: .now, snapshot: Self.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (MacroEntry) -> Void) {
        let snapshot = context.isPreview ? Self.sample : (WidgetSharedStore.load() ?? Self.sample)
        completion(MacroEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MacroEntry>) -> Void) {
        let entry = MacroEntry(date: .now, snapshot: WidgetSharedStore.load())
        // The app reloads timelines on change; refresh hourly as a fallback (also handles day rollover).
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Views

struct DietBuddyWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: MacroProvider.Entry

    private var isToday: Bool {
        entry.snapshot.map { Calendar.current.isDateInToday($0.date) } ?? false
    }

    private var metrics: [MacroMetric] {
        let snapshot = entry.snapshot
        // A new day (or no data yet) shows 0 logged, but keeps the goal targets.
        let logged = isToday
        return [
            MacroMetric(title: "Cal", current: logged ? (snapshot?.calories ?? 0) : 0, goal: snapshot?.calorieGoal),
            MacroMetric(title: "Protein", current: logged ? (snapshot?.protein ?? 0) : 0, goal: snapshot?.proteinGoal),
            MacroMetric(title: "Carbs", current: logged ? (snapshot?.carbs ?? 0) : 0, goal: snapshot?.carbGoal),
            MacroMetric(title: "Fat", current: logged ? (snapshot?.fat ?? 0) : 0, goal: snapshot?.fatGoal)
        ]
    }

    var body: some View {
        if family == .systemSmall {
            // Calories only, shown large.
            WidgetMacroRing(metric: MacroMetric(title: "Calories",
                                                current: metrics[0].current,
                                                goal: metrics[0].goal),
                            lineWidth: 10,
                            prominent: true)
        } else {
            HStack(spacing: 12) {
                ForEach(metrics) { WidgetMacroRing(metric: $0) }
            }
        }
    }
}

struct MacroMetric: Identifiable {
    let title: String
    let current: Double
    let goal: Double?
    var id: String { title }
}

struct WidgetMacroRing: View {
    let metric: MacroMetric
    var lineWidth: CGFloat = 5
    var prominent: Bool = false

    private var hasGoal: Bool { (metric.goal ?? 0) > 0 }
    private var progress: Double {
        guard let goal = metric.goal, goal > 0 else { return 0 }
        return max(0, min(metric.current / goal, 1))
    }
    private var isOver: Bool { hasGoal && metric.current > (metric.goal ?? 0) }
    private var ringColor: Color {
        isOver ? .purple : Color(hue: 0.33 * progress, saturation: 0.85, brightness: 0.85)
    }

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle().stroke(Color.gray.opacity(0.25), lineWidth: 5)
                if hasGoal {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                Text("\(metric.current, format: .number.precision(.fractionLength(0)))")
                    .font(.caption).bold()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }

            Text(metric.title)
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let goal = metric.goal, goal > 0 {
                Text("of \(goal, format: .number.precision(.fractionLength(0)))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Widget

struct DietBuddyWidget: Widget {
    let kind = "DietBuddyMacros"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MacroProvider()) { entry in
            DietBuddyWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Macros")
        .description("Today's calories and macros versus your goal.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    DietBuddyWidget()
} timeline: {
    MacroEntry(date: .now,
               snapshot: DaySnapshot(calories: 1450, protein: 120, carbs: 130, fat: 45,
                                     calorieGoal: 2000, proteinGoal: 180, carbGoal: 180, fatGoal: 60,
                                     date: .now))
}
