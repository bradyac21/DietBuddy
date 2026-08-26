import Foundation
import SwiftData

/// Preset categories a user can pick when creating a meal.
enum MealCategory: String, CaseIterable, Identifiable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon.stars"
        case .snack: return "carrot"
        }
    }
}

/// A user-created meal within a day (e.g. "Breakfast" or "Meal 1") that holds logged food items.
@Model
final class Meal {
    @Attribute(.unique) var id: UUID
    var name: String
    var date: Date
    /// Ordering of meals within a day.
    var sortIndex: Int
    @Relationship(deleteRule: .cascade, inverse: \MealItem.meal) var items: [MealItem] = []
    /// The saved meal created from this meal, if any. Drives the Save/Unsave toggle.
    var savedMeal: SavedMeal?

    init(id: UUID = UUID(), name: String, date: Date = .now, sortIndex: Int = 0) {
        self.id = id
        self.name = name
        self.date = date
        self.sortIndex = sortIndex
    }

    var totalCalories: Double { items.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { items.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double { items.reduce(0) { $0 + $1.carbs } }
    var totalFat: Double { items.reduce(0) { $0 + $1.fat } }

    /// True when any item is missing supplied nutrition facts.
    var hasMissingNutrition: Bool {
        items.contains { !$0.hasNutritionData }
    }
}
