import Foundation
import SwiftData

/// A food definition with nutrition facts expressed per 100 grams.
@Model
final class Food {
    @Attribute(.unique) var id: UUID
    var name: String
    var brand: String?
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    /// Whether the user/database actually supplied nutrition facts (false for name-only manual entries).
    var hasNutritionData: Bool

    init(id: UUID = UUID(),
         name: String,
         brand: String? = nil,
         caloriesPer100g: Double,
         proteinPer100g: Double,
         carbsPer100g: Double,
         fatPer100g: Double,
         hasNutritionData: Bool = true) {
        self.id = id
        self.name = name
        self.brand = brand
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.hasNutritionData = hasNutritionData
    }
}
