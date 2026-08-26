import Foundation
import SwiftData

/// A user-created nutrition goal.
@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var title: String
    var dailyCalories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var createdAt: Date
    /// Whether this is the goal that drives the day's targets. Only one goal should be active.
    var isActive: Bool

    init(id: UUID = UUID(),
         title: String,
         dailyCalories: Double,
         protein: Double,
         carbs: Double,
         fat: Double,
         createdAt: Date = .now,
         isActive: Bool = false) {
        self.id = id
        self.title = title
        self.dailyCalories = dailyCalories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.createdAt = createdAt
        self.isActive = isActive
    }
}
