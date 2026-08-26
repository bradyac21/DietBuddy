import SwiftUI
import SwiftData

/// Shows past days of tracked meals, grouped by day and meal.
struct MealHistoryView: View {
    @Query(sort: [SortDescriptor(\Meal.date, order: .reverse),
                  SortDescriptor(\Meal.sortIndex)]) private var allMeals: [Meal]

    private var days: [(date: Date, meals: [Meal])] {
        let tracked = allMeals.filter { !$0.items.isEmpty }
        let grouped = Dictionary(grouping: tracked) { Calendar.current.startOfDay(for: $0.date) }
        return grouped
            .map { (date: $0.key, meals: $0.value.sorted { $0.sortIndex < $1.sortIndex }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            if days.isEmpty {
                EmptyStateView(title: "No History",
                               systemImage: "clock",
                               description: "Meals you log will appear here.")
            } else {
                ForEach(days, id: \.date) { day in
                    Section(day.date.formatted(.dateTime.weekday().month().day())) {
                        ForEach(day.meals) { meal in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(meal.name).font(.headline)
                                    Spacer()
                                    Text("\(meal.totalCalories, format: .number.precision(.fractionLength(0)))\(meal.hasMissingNutrition ? "*" : "") kcal")
                                        .foregroundStyle(.secondary)
                                }
                                ForEach(mealEntries(meal.items)) { entry in
                                    switch entry {
                                    case .item(let item):
                                        MealItemRow(item: item)
                                    case .bundle(_, let name, let items):
                                        BundleRow(name: name, items: items)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
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
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}
