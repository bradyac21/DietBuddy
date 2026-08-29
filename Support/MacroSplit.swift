import Foundation

/// Calorie math for macronutrients (Atwater factors: 4/4/9 kcal per gram).
enum MacroMath {
    static let proteinKcalPerGram: Double = 4
    static let carbsKcalPerGram: Double = 4
    static let fatKcalPerGram: Double = 9

    /// The calories represented by the given macro grams.
    static func calories(protein: Double, carbs: Double, fat: Double) -> Double {
        protein * proteinKcalPerGram + carbs * carbsKcalPerGram + fat * fatKcalPerGram
    }
}

/// A macro distribution expressed as a percentage of total calories (sums to 100).
struct MacroRatio {
    var proteinPercent: Double
    var carbsPercent: Double
    var fatPercent: Double

    /// Grams of each macro for a given calorie target.
    func grams(forCalories calories: Double) -> (protein: Double, carbs: Double, fat: Double) {
        (protein: calories * proteinPercent / 100 / MacroMath.proteinKcalPerGram,
         carbs: calories * carbsPercent / 100 / MacroMath.carbsKcalPerGram,
         fat: calories * fatPercent / 100 / MacroMath.fatKcalPerGram)
    }
}

/// Common macro splits (percent of calories) used to derive macros from a calorie goal.
enum MacroSplitPreset: String, CaseIterable, Identifiable {
    case balanced, highProtein, lowCarb, lowFat, custom

    var id: String { rawValue }

    var name: String {
        switch self {
        case .balanced: "Balanced"
        case .highProtein: "High Protein"
        case .lowCarb: "Low Carb"
        case .lowFat: "Low Fat"
        case .custom: "Custom"
        }
    }

    /// Protein / Carbs / Fat as a percentage of calories. `custom` returns a neutral
    /// starting point; the editor supplies the user's own percentages.
    var ratio: MacroRatio {
        switch self {
        case .balanced: MacroRatio(proteinPercent: 30, carbsPercent: 40, fatPercent: 30)
        case .highProtein: MacroRatio(proteinPercent: 40, carbsPercent: 30, fatPercent: 30)
        case .lowCarb: MacroRatio(proteinPercent: 40, carbsPercent: 20, fatPercent: 40)
        case .lowFat: MacroRatio(proteinPercent: 30, carbsPercent: 50, fatPercent: 20)
        case .custom: MacroRatio(proteinPercent: 30, carbsPercent: 40, fatPercent: 30)
        }
    }

    /// A short "P 30% · C 40% · F 30%" summary.
    var summary: String {
        let r = ratio
        return "P \(Int(r.proteinPercent))% · C \(Int(r.carbsPercent))% · F \(Int(r.fatPercent))%"
    }
}
