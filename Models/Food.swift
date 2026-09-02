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
    /// When this food was most recently logged, used to surface recently-used foods.
    var lastLoggedAt: Date?
    /// How many times this food has been logged.
    var timesLogged: Int
    /// True for drinks, so logging defaults to a volume portion (fl oz).
    var isBeverage: Bool

    init(id: UUID = UUID(),
         name: String,
         brand: String? = nil,
         caloriesPer100g: Double,
         proteinPer100g: Double,
         carbsPer100g: Double,
         fatPer100g: Double,
         hasNutritionData: Bool = true,
         lastLoggedAt: Date? = nil,
         timesLogged: Int = 0,
         isBeverage: Bool = false) {
        self.id = id
        self.name = name
        self.brand = brand
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.hasNutritionData = hasNutritionData
        self.lastLoggedAt = lastLoggedAt
        self.timesLogged = timesLogged
        self.isBeverage = isBeverage
    }

    /// Marks the food as logged now, bumping its recency and count.
    func recordLogged() {
        lastLoggedAt = .now
        timesLogged += 1
    }
}
