import SwiftUI
import SwiftData

/// A collapsible meal within the Food tab: its items (or saved-meal bundles), a macro line,
/// an add-item action, and a long-press menu to save/unsave the meal.
struct MealDisclosureView: View {
    @Environment(\.modelContext) private var context

    let meal: Meal
    var onAddItem: (Meal) -> Void
    var onSaveMeal: (Meal) -> Void
    var onUnsaveMeal: (Meal) -> Void

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            let entries = mealEntries(meal.items)
            ForEach(entries) { entry in
                switch entry {
                case .item(let item):
                    NavigationLink {
                        MealItemDetailView(item: item)
                    } label: {
                        MealItemRow(item: item)
                    }
                case .bundle(_, let name, let items):
                    NavigationLink {
                        MealBundleDetailView(name: name, items: items)
                    } label: {
                        BundleRow(name: name, items: items)
                    }
                }
            }
            .onDelete { offsets in
                deleteEntries(at: offsets, entries: entries)
            }

            if !meal.items.isEmpty {
                Text("P \(meal.totalProtein, format: .number.precision(.fractionLength(0)))g · C \(meal.totalCarbs, format: .number.precision(.fractionLength(0)))g · F \(meal.totalFat, format: .number.precision(.fractionLength(0)))g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                onAddItem(meal)
            } label: {
                Label("Add Item", systemImage: "plus.circle")
            }
        } label: {
            HStack {
                Text(meal.name).font(.headline)
                Spacer()
                Text("\(meal.totalCalories, format: .number.precision(.fractionLength(0)))\(meal.hasMissingNutrition ? "*" : "") kcal")
                    .foregroundStyle(.secondary)
            }
            .contextMenu {
                if !meal.items.isEmpty {
                    if meal.savedMeal == nil {
                        Button {
                            onSaveMeal(meal)
                        } label: {
                            Label("Save Meal", systemImage: "bookmark")
                        }
                    } else {
                        Button(role: .destructive) {
                            onUnsaveMeal(meal)
                        } label: {
                            Label("Unsave Meal", systemImage: "bookmark.fill")
                        }
                    }
                }
            }
        }
    }

    private func deleteEntries(at offsets: IndexSet, entries: [MealEntry]) {
        for index in offsets {
            switch entries[index] {
            case .item(let item):
                context.delete(item)
            case .bundle(_, _, let items):
                items.forEach { context.delete($0) }
            }
        }
    }
}
