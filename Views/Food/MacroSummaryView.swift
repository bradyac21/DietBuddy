import SwiftUI

/// A card summarizing the day's macros. When a `goal` is supplied, each metric shows a progress
/// ring that fills toward the goal and shifts from red to green (purple once over).
struct MacroSummaryView: View {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    var goal: Goal? = nil
    var hasMissingData: Bool = false

    @State private var showingInfo = false

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                MacroRing(title: "Calories", current: calories, goal: goal?.dailyCalories, unit: "kcal", showMissingIndicator: hasMissingData)
                MacroRing(title: "Protein", current: protein, goal: goal?.protein, unit: "g")
                MacroRing(title: "Carbs", current: carbs, goal: goal?.carbs, unit: "g")
                MacroRing(title: "Fat", current: fat, goal: goal?.fat, unit: "g")
            }

            if hasMissingData {
                Button {
                    showingInfo = true
                } label: {
                    Label("Some items are missing nutrition", systemImage: "info.circle")
                        .font(.caption2)
                }
                .buttonStyle(.borderless)
            }
        }
        .frame(maxWidth: .infinity)
        .alert("Incomplete Nutrition", isPresented: $showingInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Some items today were logged without nutrition facts, so these totals may be lower than what you actually ate. Edit those items to add their nutrition.")
        }
    }
}

/// A single macro metric. Shows a red→green (→purple over) progress ring toward `goal` when one is
/// provided, otherwise a plain value.
struct MacroRing: View {
    let title: String
    let current: Double
    let goal: Double?
    let unit: String
    var showMissingIndicator: Bool = false

    private var hasGoal: Bool { (goal ?? 0) > 0 }

    private var progress: Double {
        guard let goal, goal > 0 else { return 0 }
        return max(0, min(current / goal, 1))
    }

    private var isOver: Bool { hasGoal && current > (goal ?? 0) }

    /// Red at 0%, amber mid, green at 100%, purple once over the goal.
    private var ringColor: Color {
        isOver ? .purple : Color(hue: 0.33 * progress, saturation: 0.85, brightness: 0.85)
    }

    var body: some View {
        if hasGoal {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeOut, value: progress)
                    VStack(spacing: 0) {
                        Text("\(current, format: .number.precision(.fractionLength(0)))\(showMissingIndicator ? "*" : "")")
                            .font(.subheadline.weight(.semibold))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        Text("/\(goal ?? 0, format: .number.precision(.fractionLength(0)))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(4)
                }
                .frame(width: 68, height: 68)
                Text(title).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 2) {
                Text("\(current, format: .number.precision(.fractionLength(0)))\(showMissingIndicator ? "*" : "")")
                    .font(.headline)
                Text(unit).font(.caption2).foregroundStyle(.secondary)
                Text(title).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
