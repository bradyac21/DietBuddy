import SwiftUI
import SwiftData

/// Nutrition facts (per 100 g) carried between a lookup/library source and the entry form.
struct FoodDraft {
    var name: String = ""
    var brand: String = ""
    var calories: Double?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
}

extension FoodDraft {
    init(from food: Food) {
        name = food.name
        brand = food.brand ?? ""
        calories = food.caloriesPer100g
        protein = food.proteinPer100g
        carbs = food.carbsPer100g
        fat = food.fatPer100g
    }

    init(from result: FoodLookupResult) {
        name = result.name
        brand = result.brand ?? ""
        calories = result.caloriesPer100g
        protein = result.proteinPer100g
        carbs = result.carbsPer100g
        fat = result.fatPer100g
    }
}

/// How the entry form presents a food's details.
enum FoodEntryMode {
    /// Blank, fully editable; only a name is required.
    case manual
    /// Details came from a barcode lookup — name, brand and nutrition are read-only.
    case scanned
    /// An existing library food — editable, portion required.
    case library
}

/// Form for reviewing/editing a food's per-100g nutrition and choosing a portion.
struct FoodEntryForm: View {
    @Environment(\.modelContext) private var context

    let title: String
    let mode: FoodEntryMode
    var note: String?
    var existingFood: Food?
    let onCommit: (Food, Double) -> Void

    // Editable fields (used in .manual and .library modes). Numbers are stored as text so they
    // start empty rather than showing a placeholder value like 0.
    @State private var name: String
    @State private var brand: String
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbsText: String
    @State private var fatText: String

    // The read-only source for .scanned mode.
    private let scannedDraft: FoodDraft

    @State private var amountText: String = ""
    @State private var unit: PortionUnit = .grams

    init(title: String,
         mode: FoodEntryMode,
         draft: FoodDraft = FoodDraft(),
         note: String? = nil,
         existingFood: Food? = nil,
         onCommit: @escaping (Food, Double) -> Void) {
        self.title = title
        self.mode = mode
        self.note = note
        self.existingFood = existingFood
        self.onCommit = onCommit
        self.scannedDraft = draft
        _name = State(initialValue: draft.name)
        _brand = State(initialValue: draft.brand)
        _caloriesText = State(initialValue: Self.numberString(draft.calories))
        _proteinText = State(initialValue: Self.numberString(draft.protein))
        _carbsText = State(initialValue: Self.numberString(draft.carbs))
        _fatText = State(initialValue: Self.numberString(draft.fat))
    }

    private var isReadOnly: Bool { mode == .scanned }
    private var portionRequired: Bool { mode != .manual }

    private var amount: Double? { Double(amountText) }
    private var grams: Double { unit.toGrams(amount ?? 0) }

    private var resolvedName: String {
        isReadOnly ? scannedDraft.name : name.trimmingCharacters(in: .whitespaces)
    }
    private var resolvedCalories: Double {
        isReadOnly ? (scannedDraft.calories ?? 0) : (Double(caloriesText) ?? 0)
    }
    private var portionCalories: Double { resolvedCalories * grams / 100 }

    private var canAdd: Bool {
        guard !resolvedName.isEmpty else { return false }
        if portionRequired { return (amount ?? 0) > 0 }
        return true
    }

    var body: some View {
        Form {
            if let note {
                Section {
                    Text(note).font(.footnote).foregroundStyle(.secondary)
                }
            }

            Section("Food") {
                if isReadOnly {
                    LabeledContent("Name", value: scannedDraft.name)
                    if !scannedDraft.brand.isEmpty {
                        LabeledContent("Brand", value: scannedDraft.brand)
                    }
                } else {
                    TextField("Name", text: $name)
                    TextField("Brand (optional)", text: $brand)
                }
            }

            Section {
                if isReadOnly {
                    MacroValueRow(label: "Calories", value: scannedDraft.calories, unit: "kcal")
                    MacroValueRow(label: "Protein", value: scannedDraft.protein, unit: "g")
                    MacroValueRow(label: "Carbs", value: scannedDraft.carbs, unit: "g")
                    MacroValueRow(label: "Fat", value: scannedDraft.fat, unit: "g")
                } else {
                    LabeledDecimalField(label: "Calories (kcal)", text: $caloriesText)
                    LabeledDecimalField(label: "Protein (g)", text: $proteinText)
                    LabeledDecimalField(label: "Carbs (g)", text: $carbsText)
                    LabeledDecimalField(label: "Fat (g)", text: $fatText)
                }
            } header: {
                Text("Nutrition (per 100 g)")
            } footer: {
                if mode == .manual {
                    Text("Only a name is required. Nutrition and portion are optional.")
                }
            }

            Section("Portion") {
                HStack {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    Picker("Unit", selection: $unit) {
                        ForEach(PortionUnit.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                if amount != nil {
                    LabeledContent("In this portion",
                                   value: "\(portionCalories.formatted(.number.precision(.fractionLength(0)))) kcal")
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") { add() }
                    .disabled(!canAdd)
            }
        }
    }

    private static func numberString(_ value: Double?) -> String {
        value.map { $0.formatted(.number.precision(.fractionLength(0...2))) } ?? ""
    }

    /// True when the user typed at least one nutrition value in an editable form.
    private var nutritionProvided: Bool {
        ![caloriesText, proteinText, carbsText, fatText]
            .allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private func add() {
        let brandValue = brand.trimmingCharacters(in: .whitespaces)
        let food: Food
        if let existingFood {
            existingFood.name = resolvedName
            existingFood.brand = brandValue.isEmpty ? nil : brandValue
            existingFood.caloriesPer100g = Double(caloriesText) ?? 0
            existingFood.proteinPer100g = Double(proteinText) ?? 0
            existingFood.carbsPer100g = Double(carbsText) ?? 0
            existingFood.fatPer100g = Double(fatText) ?? 0
            existingFood.hasNutritionData = nutritionProvided
            food = existingFood
        } else if isReadOnly {
            // Scanned data always counts as supplied nutrition facts.
            food = Food(name: scannedDraft.name,
                        brand: scannedDraft.brand.isEmpty ? nil : scannedDraft.brand,
                        caloriesPer100g: scannedDraft.calories ?? 0,
                        proteinPer100g: scannedDraft.protein ?? 0,
                        carbsPer100g: scannedDraft.carbs ?? 0,
                        fatPer100g: scannedDraft.fat ?? 0,
                        hasNutritionData: true)
            context.insert(food)
        } else {
            food = Food(name: resolvedName,
                        brand: brandValue.isEmpty ? nil : brandValue,
                        caloriesPer100g: Double(caloriesText) ?? 0,
                        proteinPer100g: Double(proteinText) ?? 0,
                        carbsPer100g: Double(carbsText) ?? 0,
                        fatPer100g: Double(fatText) ?? 0,
                        hasNutritionData: nutritionProvided)
            context.insert(food)
        }
        onCommit(food, grams)
    }
}
