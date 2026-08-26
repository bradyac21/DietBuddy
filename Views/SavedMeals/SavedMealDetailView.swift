import SwiftUI

/// Previews a saved meal's items and offers to add them all to the current meal.
struct SavedMealDetailView: View {
    let savedMeal: SavedMeal
    let onAdd: () -> Void

    var body: some View {
        List {
            Section {
                MacroSummaryView(calories: savedMeal.totalCalories,
                                 protein: savedMeal.totalProtein,
                                 carbs: savedMeal.totalCarbs,
                                 fat: savedMeal.totalFat,
                                 hasMissingData: savedMeal.hasMissingNutrition)
                .padding(.vertical, 4)
            }

            Section("Items") {
                ForEach(savedMeal.items) { item in
                    SavedMealItemRow(item: item)
                }
            }

            Section {
                Button {
                    onAdd()
                } label: {
                    Label("Add to Meal", systemImage: "plus")
                }
            }
        }
        .navigationTitle(savedMeal.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
