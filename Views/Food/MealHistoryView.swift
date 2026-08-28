import SwiftUI
import SwiftData

/// Past days of tracked meals. Defaults to a scrollable day-by-day list, with a
/// toolbar toggle to a month calendar for jumping to a specific day.
struct MealHistoryView: View {
    @Query(sort: [SortDescriptor(\Meal.date, order: .reverse),
                  SortDescriptor(\Meal.sortIndex)]) private var allMeals: [Meal]

    private enum Mode { case list, calendar }
    @State private var mode: Mode = .list

    private var trackedMeals: [Meal] { allMeals.filter { !$0.items.isEmpty } }

    private var days: [(date: Date, meals: [Meal])] {
        let grouped = Dictionary(grouping: trackedMeals) { Calendar.current.startOfDay(for: $0.date) }
        return grouped
            .map { (date: $0.key, meals: $0.value.sorted { $0.sortIndex < $1.sortIndex }) }
            .sorted { $0.date > $1.date }
    }

    /// Start-of-day dates that have logged food, for marking calendar cells.
    private var daysWithData: Set<Date> {
        Set(trackedMeals.map { Calendar.current.startOfDay(for: $0.date) })
    }

    var body: some View {
        Group {
            switch mode {
            case .list:
                listView
            case .calendar:
                HistoryCalendarView(daysWithData: daysWithData)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation { mode = (mode == .list ? .calendar : .list) }
                } label: {
                    Image(systemName: mode == .list ? "calendar" : "list.bullet")
                }
                .accessibilityLabel(mode == .list ? "Calendar view" : "List view")
            }
        }
    }

    private var listView: some View {
        List {
            if days.isEmpty {
                EmptyStateView(title: "No History",
                               systemImage: "clock",
                               description: "Meals you log will appear here.")
            } else {
                ForEach(days, id: \.date) { day in
                    Section(day.date.formatted(.dateTime.weekday().month().day())) {
                        ForEach(day.meals) { meal in
                            MealSummaryDisclosure(meal: meal)
                        }

                        let dayTotal = day.meals.reduce(0) { $0 + $1.totalCalories }
                        HStack {
                            Text("Day Total").bold()
                            Spacer()
                            Text("\(dayTotal, format: .number.precision(.fractionLength(0))) kcal")
                                .bold()
                        }
                    }
                }
            }
        }
    }
}
