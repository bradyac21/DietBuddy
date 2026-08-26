import Foundation
import SwiftData

/// A named, reusable snapshot of a meal's items, saved for quick logging later.
@Model
final class SavedMeal {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \SavedMealItem.savedMeal) var items: [SavedMealItem] = []

    init(id: UUID = UUID(), name: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }

    var totalCalories: Double { items.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { items.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double { items.reduce(0) { $0 + $1.carbs } }
    var totalFat: Double { items.reduce(0) { $0 + $1.fat } }

    var hasMissingNutrition: Bool { items.contains { !$0.hasNutritionData } }
}
