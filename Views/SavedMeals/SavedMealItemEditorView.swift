import SwiftUI

/// Edit a single saved-meal item's details and portion.
struct SavedMealItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let item: SavedMealItem

    @State private var nameText: String
    @State private var brandText: String
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbsText: String
    @State private var fatText: String
    @State private var gramsText: String

    init(item: SavedMealItem) {
        self.item = item
        _nameText = State(initialValue: item.foodName)
        _brandText = State(initialValue: item.brand ?? "")
        _caloriesText = State(initialValue: Self.numberString(item.caloriesPer100g))
        _proteinText = State(initialValue: Self.numberString(item.proteinPer100g))
        _carbsText = State(initialValue: Self.numberString(item.carbsPer100g))
        _fatText = State(initialValue: Self.numberString(item.fatPer100g))
        _gramsText = State(initialValue: Self.numberString(item.grams))
    }

    private var canSave: Bool {
        !nameText.trimmingCharacters(in: .whitespaces).isEmpty && (Double(gramsText) ?? 0) > 0
    }

    private var nutritionProvided: Bool {
        ![caloriesText, proteinText, carbsText, fatText]
            .allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        Form {
            Section("Food") {
                TextField("Name", text: $nameText)
                TextField("Brand (optional)", text: $brandText)
            }
            Section("Nutrition (per 100 g)") {
                macroField("Calories (kcal)", text: $caloriesText)
                macroField("Protein (g)", text: $proteinText)
                macroField("Carbs (g)", text: $carbsText)
                macroField("Fat (g)", text: $fatText)
            }
            Section("Portion") {
                macroField("Grams", text: $gramsText)
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

    private static func numberString(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }

    private func save() {
        item.foodName = nameText.trimmingCharacters(in: .whitespaces)
        let brandValue = brandText.trimmingCharacters(in: .whitespaces)
        item.brand = brandValue.isEmpty ? nil : brandValue
        item.caloriesPer100g = Double(caloriesText) ?? 0
        item.proteinPer100g = Double(proteinText) ?? 0
        item.carbsPer100g = Double(carbsText) ?? 0
        item.fatPer100g = Double(fatText) ?? 0
        item.hasNutritionData = nutritionProvided
        item.grams = Double(gramsText) ?? item.grams
        dismiss()
    }
}
