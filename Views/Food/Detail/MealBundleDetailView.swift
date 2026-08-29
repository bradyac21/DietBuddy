import SwiftUI

/// A single collapsed row representing a saved meal that was logged.
struct BundleRow: View {
    let name: String
    let items: [MealItem]

    private var calories: Double { items.reduce(0) { $0 + $1.calories } }
    private var hasMissing: Bool { items.contains { !$0.hasNutritionData } }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "bookmark.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(name)
                }
                Text("\(items.count) \(items.count == 1 ? "item" : "items")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(calories, format: .number.precision(.fractionLength(0)))\(hasMissing ? "*" : "") kcal")
                .foregroundStyle(.secondary)
        }
    }
}

/// Detail for a logged saved-meal bundle: its macro summary and constituent items.
struct MealBundleDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let name: String
    let items: [MealItem]

    private var totalCalories: Double { items.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Double { items.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Double { items.reduce(0) { $0 + $1.carbs } }
    private var totalFat: Double { items.reduce(0) { $0 + $1.fat } }
    private var hasMissing: Bool { items.contains { !$0.hasNutritionData } }

    var body: some View {
        List {
            Section {
                MacroSummaryView(calories: totalCalories,
                                 protein: totalProtein,
                                 carbs: totalCarbs,
                                 fat: totalFat,
                                 hasMissingData: hasMissing)
                .padding(.vertical, 4)
            }

            Section("Items") {
                ForEach(items) { item in
                    NavigationLink {
                        MealItemDetailView(item: item)
                    } label: {
                        MealItemRow(item: item)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    ungroup()
                } label: {
                    Label("Ungroup", systemImage: "rectangle.split.3x1")
                }
            } footer: {
                Text("Splits this saved meal back into individual items in the meal.")
            }
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func ungroup() {
        for item in items {
            item.bundleID = nil
            item.bundleName = nil
        }
        dismiss()
    }
}
