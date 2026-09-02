import Foundation

/// Portion measurement units. Nutrition is stored per 100 g, so everything converts to grams.
/// Volume units assume a density of ~1 g/mL, which is accurate for water and most drinks.
enum PortionUnit: String, CaseIterable, Identifiable {
    case grams = "g"
    case ounces = "oz"
    case fluidOunces = "fl oz"
    case milliliters = "mL"

    var id: String { rawValue }

    private var gramsPerUnit: Double {
        switch self {
        case .grams: return 1
        case .ounces: return 28.349523125
        case .fluidOunces: return 29.5735295625   // 1 US fl oz of water ≈ 29.57 g
        case .milliliters: return 1               // ~1 g/mL
        }
    }

    func toGrams(_ amount: Double) -> Double { amount * gramsPerUnit }
}
