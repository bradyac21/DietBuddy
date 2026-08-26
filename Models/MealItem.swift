import Foundation
import SwiftData

/// A single logged portion of a food.
///
/// Nutrition is snapshotted at log time (rather than read from a `Food` relationship) so that
/// later edits to the Food library never change previously logged entries.
@Model
final class MealItem {
    @Attribute(.unique) var id: UUID
    var foodName: String
    var brand: String?
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    var hasNutritionData: Bool
    var grams: Double
    /// When this item was logged.
    var loggedAt: Date
    /// If this item was added as part of a saved meal, a shared id linking the bundle's items.
    var bundleID: UUID?
    /// The saved meal's name, shown for the collapsed bundle row.
    var bundleName: String?
    /// The meal this item belongs to (set when appended to a meal's `items`).
    var meal: Meal?

    init(id: UUID = UUID(),
         foodName: String,
         brand: String? = nil,
         caloriesPer100g: Double,
         proteinPer100g: Double,
         carbsPer100g: Double,
         fatPer100g: Double,
         hasNutritionData: Bool,
         grams: Double,
         loggedAt: Date = .now) {
        self.id = id
        self.foodName = foodName
        self.brand = brand
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.hasNutritionData = hasNutritionData
        self.grams = grams
        self.loggedAt = loggedAt
    }

    private var factor: Double { grams / 100.0 }

    var calories: Double { caloriesPer100g * factor }
    var protein: Double { proteinPer100g * factor }
    var carbs: Double { carbsPer100g * factor }
    var fat: Double { fatPer100g * factor }
}

extension MealItem {
    /// Snapshot a library food into a newly logged item.
    convenience init(food: Food, grams: Double) {
        self.init(foodName: food.name,
                  brand: food.brand,
                  caloriesPer100g: food.caloriesPer100g,
                  proteinPer100g: food.proteinPer100g,
                  carbsPer100g: food.carbsPer100g,
                  fatPer100g: food.fatPer100g,
                  hasNutritionData: food.hasNutritionData,
                  grams: grams)
    }

    /// Recreate a logged item from a saved-meal item snapshot.
    convenience init(savedItem: SavedMealItem) {
        self.init(foodName: savedItem.foodName,
                  brand: savedItem.brand,
                  caloriesPer100g: savedItem.caloriesPer100g,
                  proteinPer100g: savedItem.proteinPer100g,
                  carbsPer100g: savedItem.carbsPer100g,
                  fatPer100g: savedItem.fatPer100g,
                  hasNutritionData: savedItem.hasNutritionData,
                  grams: savedItem.grams)
    }
}
