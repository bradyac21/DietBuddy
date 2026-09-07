import SwiftUI
import SwiftData

/// Storage summary and the reset-all-data action.
struct DataSettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("displayName") private var displayName: String = ""

    @Query private var weighIns: [WeightEntry]
    @Query private var meals: [Meal]
    @Query private var foods: [Food]
    @Query private var savedMeals: [SavedMeal]
    @Query private var goals: [Goal]

    @State private var showingResetAlert = false

    var body: some View {
        List {
            Section {
                LabeledContent("Weigh-ins", value: "\(weighIns.count)")
                LabeledContent("Meals", value: "\(meals.count)")
                LabeledContent("Foods", value: "\(foods.count)")
                LabeledContent("Saved Meals", value: "\(savedMeals.count)")
                LabeledContent("Goals", value: "\(goals.count)")
            } header: {
                Text("Stored Data")
            } footer: {
                Text("Everything you log is stored on this device.")
            }

            Section {
                Button("Reset All Data", role: .destructive) {
                    showingResetAlert = true
                }
            }
        }
        .navigationTitle("Data")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Reset All Data?", isPresented: $showingResetAlert) {
            Button("Delete Everything", role: .destructive) { resetAllData() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently deletes all logged foods, meals, weigh-ins, saved meals, goals, and your profile. This can't be undone.")
        }
    }

    /// Permanently deletes every stored record. Preferences (theme, units, etc.) are kept.
    private func resetAllData() {
        try? context.delete(model: MealItem.self)
        try? context.delete(model: Meal.self)
        try? context.delete(model: SavedMealItem.self)
        try? context.delete(model: SavedMeal.self)
        try? context.delete(model: WeightEntry.self)
        try? context.delete(model: Food.self)
        try? context.delete(model: Goal.self)
        try? context.delete(model: UserProfile.self)
        try? context.save()
        displayName = ""
    }
}
