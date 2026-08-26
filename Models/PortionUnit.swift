import Foundation

/// Portion measurement units. Nutrition is stored per 100 g, so everything converts to grams.
enum PortionUnit: String, CaseIterable, Identifiable {
    case grams = "g"
    case ounces = "oz"

    var id: String { rawValue }

    private var gramsPerUnit: Double {
        switch self {
        case .grams: return 1
        case .ounces: return 28.349523125
        }
    }

    func toGrams(_ amount: Double) -> Double { amount * gramsPerUnit }
}
