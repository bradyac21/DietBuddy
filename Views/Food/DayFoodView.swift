import SwiftUI
import SwiftData

/// Read-only view of the food logged on a single day. A header shows the date with
/// left/right buttons to step to the previous/next day (never past today).
struct DayFoodView: View {
    @Query(sort: [SortDescriptor(\Meal.date, order: .reverse),
                  SortDescriptor(\Meal.sortIndex)]) private var allMeals: [Meal]
    @Environment(\.appAccentColor) private var accent

    @State var date: Date
    @State private var shakeTrigger = 0

    private let calendar = Calendar.current

    private var dayMeals: [Meal] {
        allMeals
            .filter { calendar.isDate($0.date, inSameDayAs: date) && !$0.items.isEmpty }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    private var dayCalories: Double { dayMeals.reduce(0) { $0 + $1.totalCalories } }
    private var dayProtein: Double { dayMeals.reduce(0) { $0 + $1.totalProtein } }
    private var dayCarbs: Double { dayMeals.reduce(0) { $0 + $1.totalCarbs } }
    private var dayFat: Double { dayMeals.reduce(0) { $0 + $1.totalFat } }
    private var dayHasMissing: Bool { dayMeals.contains { $0.hasMissingNutrition } }

    /// The next day is unavailable once we're at today (no future logging).
    private var canGoForward: Bool { !calendar.isDateInToday(date) && date < .now }

    /// The earliest day with logged food; backward navigation stops here.
    private var earliestDay: Date {
        let days = allMeals.filter { !$0.items.isEmpty }.map { calendar.startOfDay(for: $0.date) }
        return days.min() ?? calendar.startOfDay(for: .now)
    }

    private var canGoBack: Bool { calendar.startOfDay(for: date) > earliestDay }

    var body: some View {
        List {
            Section {
                header
            }

            if dayMeals.isEmpty {
                Section {
                    EmptyStateView(title: "No Meals Logged",
                                   systemImage: "fork.knife",
                                   description: "Nothing was tracked on this day.")
                }
            } else {
                Section {
                    MacroSummaryView(calories: dayCalories,
                                     protein: dayProtein,
                                     carbs: dayCarbs,
                                     fat: dayFat,
                                     hasMissingData: dayHasMissing)
                    .padding(.vertical, 4)
                }

                Section("Meals") {
                    ForEach(dayMeals) { meal in
                        MealSummaryDisclosure(meal: meal)
                    }

                    HStack {
                        Text("Day Total").bold()
                        Spacer()
                        Text("\(dayCalories, format: .number.precision(.fractionLength(0))) kcal").bold()
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack {
            Button {
                if canGoBack { shiftDay(by: -1) } else { triggerShake() }
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)

            Spacer()

            VStack(spacing: 2) {
                Text(date, format: .dateTime.weekday(.wide))
                    .font(.headline)
                Text(date, format: .dateTime.month().day().year())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .shake(shakeTrigger)

            Spacer()

            Button {
                if canGoForward { shiftDay(by: 1) } else { triggerShake() }
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)
        }
        .font(.title3)
        .foregroundStyle(accent)
    }

    private func shiftDay(by days: Int) {
        if let newDate = calendar.date(byAdding: .day, value: days, to: date) {
            withAnimation { date = newDate }
        }
    }

    private func triggerShake() {
        withAnimation(.linear(duration: 0.4)) { shakeTrigger += 1 }
    }
}
