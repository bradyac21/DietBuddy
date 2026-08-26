import SwiftUI

/// Editable detail for a single logged food item. Editing the serving size rescales the shown
/// nutrition (which is derived from the item's per-100g basis). Items without nutrition data can
/// have it entered here.
struct MealItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let item: MealItem

    @State private var nameText: String
    @State private var brandText: String
    @State private var gramsText: String

    // Only used when the item has no nutrition data yet (entered as this-serving totals).
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbsText: String
    @State private var fatText: String

    init(item: MealItem) {
        self.item = item
        _nameText = State(initialValue: item.foodName)
        _brandText = State(initialValue: item.brand ?? "")
        _gramsText = State(initialValue: Self.numberString(item.grams))
        _caloriesText = State(initialValue: "")
        _proteinText = State(initialValue: "")
        _carbsText = State(initialValue: "")
        _fatText = State(initialValue: "")
    }

    private var grams: Double { Double(gramsText) ?? 0 }
    /// Scale factor from per-100g to the current serving.
    private var factor: Double { grams / 100.0 }

    private var nutritionProvided: Bool {
        ![caloriesText, proteinText, carbsText, fatText]
            .allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
    private var canSave: Bool {
        !nameText.trimmingCharacters(in: .whitespaces).isEmpty && grams > 0
    }

    var body: some View {
        Form {
            Section("Food") {
                TextField("Name", text: $nameText)
                TextField("Brand (optional)", text: $brandText)
            }

            Section("Portion") {
                macroField("Grams", text: $gramsText)
            }

            if item.hasNutritionData {
                // Derived from the per-100g basis, so it updates as the serving size changes.
                Section("Nutrition (this serving)") {
                    servingRow("Calories", item.caloriesPer100g * factor, "kcal")
                    servingRow("Protein", item.proteinPer100g * factor, "g")
                    servingRow("Carbs", item.carbsPer100g * factor, "g")
                    servingRow("Fat", item.fatPer100g * factor, "g")
                }
            } else {
                Section {
                    macroField("Calories (kcal)", text: $caloriesText)
                    macroField("Protein (g)", text: $proteinText)
                    macroField("Carbs (g)", text: $carbsText)
                    macroField("Fat (g)", text: $fatText)
                } header: {
                    Text("Nutrition (this serving)")
                } footer: {
                    Text("This item was logged without nutrition. Add it here if you know it.")
                }
            }

            Section {
                LabeledContent("Logged", value: item.loggedAt.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .navigationTitle("Edit Item")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!canSave)
            }
        }
    }

    private func macroField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField(label, text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }

    private func servingRow(_ label: String, _ value: Double, _ unit: String) -> some View {
        LabeledContent(label, value: "\(value.formatted(.number.precision(.fractionLength(0...1)))) \(unit)")
    }

    private static func numberString(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }

    private func save() {
        item.foodName = nameText.trimmingCharacters(in: .whitespaces)
        let brand = brandText.trimmingCharacters(in: .whitespaces)
        item.brand = brand.isEmpty ? nil : brand
        item.grams = grams

        // For items without nutrition, any values entered are this-serving totals — convert to
        // per-100g using the serving size so future serving changes scale correctly.
        if !item.hasNutritionData, nutritionProvided, grams > 0 {
            let toPer100g = 100.0 / grams
            item.caloriesPer100g = (Double(caloriesText) ?? 0) * toPer100g
            item.proteinPer100g = (Double(proteinText) ?? 0) * toPer100g
            item.carbsPer100g = (Double(carbsText) ?? 0) * toPer100g
            item.fatPer100g = (Double(fatText) ?? 0) * toPer100g
            item.hasNutritionData = true
        }
        dismiss()
    }
}
