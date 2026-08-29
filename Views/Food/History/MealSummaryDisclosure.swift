import SwiftUI

/// A read-only, collapsible meal row for history views. Mirrors the main screen's
/// disclosure group (items or saved-meal bundles + a macro line) but has no editing.
struct MealSummaryDisclosure: View {
    let meal: Meal
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(mealEntries(meal.items)) { entry in
                switch entry {
                case .item(let item):
                    MealItemRow(item: item)
                case .bundle(_, let name, let items):
                    BundleRow(name: name, items: items)
                }
            }

            if !meal.items.isEmpty {
                Text("P \(meal.totalProtein, format: .number.precision(.fractionLength(0)))g · C \(meal.totalCarbs, format: .number.precision(.fractionLength(0)))g · F \(meal.totalFat, format: .number.precision(.fractionLength(0)))g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            HStack {
                Text(meal.name).font(.headline)
                Spacer()
                Text("\(meal.totalCalories, format: .number.precision(.fractionLength(0)))\(meal.hasMissingNutrition ? "*" : "") kcal")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
