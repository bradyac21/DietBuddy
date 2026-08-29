import SwiftUI
import SwiftData

/// Entry point sheet for logging a food. Offers barcode scanning, manual entry, and the saved library.
struct AddMealItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Food.name, order: .forward) private var foods: [Food]

    /// The meal this item will be added to (shown in the title).
    var mealName: String
    /// Called when the user picks a saved meal to add all of its items at once.
    var onAddSavedMeal: (SavedMeal) -> Void
    /// Called with the chosen food and portion size (grams) when the user confirms.
    var onSave: (Food, Double) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ScanFoodView(onCommit: commit)
                    } label: {
                        Label("Scan Barcode", systemImage: "barcode.viewfinder")
                    }
                    NavigationLink {
                        FoodEntryForm(title: "Manual Entry", mode: .manual, onCommit: commit)
                    } label: {
                        Label("Enter Manually", systemImage: "square.and.pencil")
                    }
                } header: {
                    Text("Add New")
                } footer: {
                    Text("Scan a packaged item's barcode, or enter nutrition by hand for restaurant meals where posted facts are unreliable.")
                }

                Section {
                    NavigationLink {
                        SavedMealsPickerView { saved in
                            commitSavedMeal(saved)
                        }
                    } label: {
                        Label("Saved Meals", systemImage: "bookmark")
                    }
                }

                if !foods.isEmpty {
                    Section("From Library") {
                        ForEach(foods) { food in
                            NavigationLink {
                                FoodEntryForm(title: food.name,
                                              mode: .library,
                                              draft: FoodDraft(from: food),
                                              existingFood: food,
                                              onCommit: commit)
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(food.name)
                                    Text("\(food.caloriesPer100g, format: .number.precision(.fractionLength(0))) kcal / 100 g")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to \(mealName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func commit(_ food: Food, _ grams: Double) {
        onSave(food, grams)
        dismiss()
    }

    private func commitSavedMeal(_ saved: SavedMeal) {
        onAddSavedMeal(saved)
        dismiss()
    }
}
