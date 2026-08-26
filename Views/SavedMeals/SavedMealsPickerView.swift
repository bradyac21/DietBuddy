import SwiftUI
import SwiftData

/// Lists the user's saved meals so they can browse and add one to the current meal.
struct SavedMealsPickerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\SavedMeal.name)]) private var savedMeals: [SavedMeal]

    /// Called when the user chooses a saved meal to add.
    let onSelect: (SavedMeal) -> Void

    var body: some View {
        List {
            if savedMeals.isEmpty {
                EmptyStateView(title: "No Saved Meals",
                               systemImage: "bookmark",
                               description: "Save a meal from the Food tab to quickly add it again here.")
            } else {
                ForEach(savedMeals) { saved in
                    NavigationLink {
                        SavedMealDetailView(savedMeal: saved) { onSelect(saved) }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(saved.name)
                            Text("\(saved.items.count) \(saved.items.count == 1 ? "item" : "items") · \(saved.totalCalories, format: .number.precision(.fractionLength(0)))\(saved.hasMissingNutrition ? "*" : "") kcal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Saved Meals")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(savedMeals[index])
        }
    }
}
