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
    /// True for drinks, so the portion defaults to a volume unit.
    var isBeverage: Bool = false
}

extension FoodDraft {
    init(from food: Food) {
        name = food.name
        brand = food.brand ?? ""
        calories = food.caloriesPer100g
        protein = food.proteinPer100g
        carbs = food.carbsPer100g
        fat = food.fatPer100g
        isBeverage = food.isBeverage
    }

    init(from result: FoodLookupResult) {
        name = result.name
        brand = result.brand ?? ""
        calories = result.caloriesPer100g
        protein = result.proteinPer100g
        carbs = result.carbsPer100g
        fat = result.fatPer100g
        isBeverage = result.isBeverage
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
    @State private var unit: PortionUnit
    @State private var isBeverage: Bool

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
        // Editable fields show values in the display basis (per fl oz for drinks).
        let basisGrams = draft.isBeverage ? Self.gramsPerFluidOunce : 100
        _caloriesText = State(initialValue: Self.numberString(draft.calories.map { $0 * basisGrams / 100 }))
        _proteinText = State(initialValue: Self.numberString(draft.protein.map { $0 * basisGrams / 100 }))
        _carbsText = State(initialValue: Self.numberString(draft.carbs.map { $0 * basisGrams / 100 }))
        _fatText = State(initialValue: Self.numberString(draft.fat.map { $0 * basisGrams / 100 }))
        // Beverages default to a volume unit (fl oz); everything else to grams.
        _unit = State(initialValue: draft.isBeverage ? .fluidOunces : .grams)
        _isBeverage = State(initialValue: draft.isBeverage)
    }

    private var isReadOnly: Bool { mode == .scanned }
    private var portionRequired: Bool { mode != .manual }

    /// Grams in one unit of the nutrition basis: per fl oz for drinks, per 100 g for food.
    private static let gramsPerFluidOunce = 29.5735295625
    private var nutritionBasisGrams: Double { isBeverage ? Self.gramsPerFluidOunce : 100 }

    /// Drinks measure by volume (fl oz / mL, nutrition per fl oz); foods by weight (g / oz, per 100 g).
    private var unitOptions: [PortionUnit] { isBeverage ? [.fluidOunces, .milliliters] : [.grams, .ounces] }
    private var basisLabel: String { isBeverage ? "per fl oz" : "per 100 g" }

    /// Converts a stored per-100g value into the current display basis.
    private func inBasis(_ per100: Double?) -> Double? {
        per100.map { $0 * nutritionBasisGrams / 100 }
    }

    private var amount: Double? { Double(amountText) }
    private var grams: Double { unit.toGrams(amount ?? 0) }

    private var resolvedName: String {
        isReadOnly ? scannedDraft.name : name.trimmingCharacters(in: .whitespaces)
    }
    private var resolvedCalories: Double {
        // Always a per-100g value, for portion math.
        if isReadOnly { return scannedDraft.calories ?? 0 }
        return (Double(caloriesText) ?? 0) * 100 / nutritionBasisGrams
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

            Section {
                Picker("Type", selection: $isBeverage) {
                    Text("Food").tag(false)
                    Text("Drink").tag(true)
                }
                .pickerStyle(.segmented)
                .onChange(of: isBeverage) { _, drink in
                    unit = drink ? .fluidOunces : .grams
                }
            }

            Section("Details") {
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
                    MacroValueRow(label: "Calories", value: inBasis(scannedDraft.calories), unit: "kcal")
                    MacroValueRow(label: "Protein", value: inBasis(scannedDraft.protein), unit: "g")
                    MacroValueRow(label: "Carbs", value: inBasis(scannedDraft.carbs), unit: "g")
                    MacroValueRow(label: "Fat", value: inBasis(scannedDraft.fat), unit: "g")
                } else {
                    LabeledDecimalField(label: "Calories (kcal)", text: $caloriesText)
                    LabeledDecimalField(label: "Protein (g)", text: $proteinText)
                    LabeledDecimalField(label: "Carbs (g)", text: $carbsText)
                    LabeledDecimalField(label: "Fat (g)", text: $fatText)
                }
            } header: {
                Text("Nutrition (\(basisLabel))")
            } footer: {
                if mode == .manual {
                    Text("Only a name is required. Nutrition and portion are optional.")
                }
            }

            Section("Portion") {
                TextField("Amount", text: $amountText)
                    .keyboardType(.decimalPad)

                Picker("Unit", selection: $unit) {
                    ForEach(unitOptions) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

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
            existingFood.caloriesPer100g = (Double(caloriesText) ?? 0) * 100 / nutritionBasisGrams
            existingFood.proteinPer100g = (Double(proteinText) ?? 0) * 100 / nutritionBasisGrams
            existingFood.carbsPer100g = (Double(carbsText) ?? 0) * 100 / nutritionBasisGrams
            existingFood.fatPer100g = (Double(fatText) ?? 0) * 100 / nutritionBasisGrams
            existingFood.hasNutritionData = nutritionProvided
            existingFood.isBeverage = isBeverage
            food = existingFood
        } else if isReadOnly {
            // Scanned data always counts as supplied nutrition facts.
            food = Food(name: scannedDraft.name,
                        brand: scannedDraft.brand.isEmpty ? nil : scannedDraft.brand,
                        caloriesPer100g: scannedDraft.calories ?? 0,
                        proteinPer100g: scannedDraft.protein ?? 0,
                        carbsPer100g: scannedDraft.carbs ?? 0,
                        fatPer100g: scannedDraft.fat ?? 0,
                        hasNutritionData: true,
                        isBeverage: isBeverage)
            context.insert(food)
        } else {
            food = Food(name: resolvedName,
                        brand: brandValue.isEmpty ? nil : brandValue,
                        caloriesPer100g: (Double(caloriesText) ?? 0) * 100 / nutritionBasisGrams,
                        proteinPer100g: (Double(proteinText) ?? 0) * 100 / nutritionBasisGrams,
                        carbsPer100g: (Double(carbsText) ?? 0) * 100 / nutritionBasisGrams,
                        fatPer100g: (Double(fatText) ?? 0) * 100 / nutritionBasisGrams,
                        hasNutritionData: nutritionProvided,
                        isBeverage: isBeverage)
            context.insert(food)
        }
        onCommit(food, grams)
    }
}
