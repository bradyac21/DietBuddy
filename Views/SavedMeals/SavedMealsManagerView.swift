import SwiftUI
import SwiftData

/// Account-screen management of saved meals: browse, rename, edit items, and remove.
struct SavedMealsManagerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\SavedMeal.name)]) private var savedMeals: [SavedMeal]

    var body: some View {
        List {
            if savedMeals.isEmpty {
                EmptyStateView(title: "No Saved Meals",
                               systemImage: "bookmark",
                               description: "Save a meal from the Food tab and it will appear here to manage.")
            } else {
                ForEach(savedMeals) { saved in
                    NavigationLink {
                        SavedMealEditorView(savedMeal: saved)
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
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(savedMeals[index])
        }
    }
}
