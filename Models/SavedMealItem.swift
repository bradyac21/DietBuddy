import Foundation
import SwiftData

/// One portion snapshot stored inside a `SavedMeal`. Like `MealItem`, nutrition is captured at save
/// time so later Food edits don't change the saved meal.
@Model
final class SavedMealItem {
    @Attribute(.unique) var id: UUID
    var foodName: String
    var brand: String?
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    var hasNutritionData: Bool
    var grams: Double
    var savedMeal: SavedMeal?

    init(id: UUID = UUID(),
         foodName: String,
         brand: String? = nil,
         caloriesPer100g: Double,
         proteinPer100g: Double,
         carbsPer100g: Double,
         fatPer100g: Double,
         hasNutritionData: Bool,
         grams: Double) {
        self.id = id
        self.foodName = foodName
        self.brand = brand
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.hasNutritionData = hasNutritionData
        self.grams = grams
    }

    private var factor: Double { grams / 100.0 }

    var calories: Double { caloriesPer100g * factor }
    var protein: Double { proteinPer100g * factor }
    var carbs: Double { carbsPer100g * factor }
    var fat: Double { fatPer100g * factor }
}

extension SavedMealItem {
    /// Snapshot a library food into a saved-meal item.
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

    /// Snapshot a logged item into a saved-meal item.
    convenience init(from item: MealItem) {
        self.init(foodName: item.foodName,
                  brand: item.brand,
                  caloriesPer100g: item.caloriesPer100g,
                  proteinPer100g: item.proteinPer100g,
                  carbsPer100g: item.carbsPer100g,
                  fatPer100g: item.fatPer100g,
                  hasNutritionData: item.hasNutritionData,
                  grams: item.grams)
    }
}
