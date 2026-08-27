import Foundation

/// A small, shareable summary of the day's macros and the active goal's targets.
/// Written by the app into the App Group so the widget can read it.
struct DaySnapshot: Codable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var calorieGoal: Double?
    var proteinGoal: Double?
    var carbGoal: Double?
    var fatGoal: Double?
    /// The day these totals are for (widget shows 0 for a new day).
    var date: Date
}

/// App-side writer for the shared day snapshot.
enum SharedStore {
    static let appGroupID = "group.com.bradycarden.DietBuddy"
    static let snapshotKey = "daySnapshot"

    static func save(_ snapshot: DaySnapshot) {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }
}
