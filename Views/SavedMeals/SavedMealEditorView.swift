import SwiftUI
import SwiftData

/// Rename a saved meal and edit or remove its items.
struct SavedMealEditorView: View {
    @Environment(\.modelContext) private var context
    @Query private var savedMeals: [SavedMeal]

    let savedMeal: SavedMeal
    @State private var name: String

    init(savedMeal: SavedMeal) {
        self.savedMeal = savedMeal
        _name = State(initialValue: savedMeal.name)
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }
    private var isDuplicate: Bool {
        savedMeals.contains {
            $0.id != savedMeal.id
                && $0.name.trimmingCharacters(in: .whitespaces).lowercased() == trimmed.lowercased()
        }
    }
    private var isValid: Bool { !trimmed.isEmpty && !isDuplicate }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
            } header: {
                Text("Name")
            } footer: {
                if trimmed.isEmpty {
                    Text("Name can't be empty.").foregroundStyle(.red)
                } else if isDuplicate {
                    Text("Another saved meal named \"\(trimmed)\" already exists.")
                        .foregroundStyle(.red)
                }
            }

            Section {
                MacroSummaryView(calories: savedMeal.totalCalories,
                                 protein: savedMeal.totalProtein,
                                 carbs: savedMeal.totalCarbs,
                                 fat: savedMeal.totalFat,
                                 hasMissingData: savedMeal.hasMissingNutrition)
                .padding(.vertical, 4)
            }

            Section {
                if savedMeal.items.isEmpty {
                    Text("No items.").foregroundStyle(.secondary)
                } else {
                    ForEach(savedMeal.items) { item in
                        NavigationLink {
                            SavedMealItemEditorView(item: item)
                        } label: {
                            SavedMealItemRow(item: item)
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            } header: {
                Text("Items")
            } footer: {
                Text("Swipe an item to remove it, or tap to edit its details.")
            }
        }
        .navigationTitle("Edit Meal")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: name) { _, _ in
            // Only commit the rename while it's non-empty and unique.
            if isValid {
                savedMeal.name = trimmed
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            context.delete(savedMeal.items[index])
        }
    }
}
