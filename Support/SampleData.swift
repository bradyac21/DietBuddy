#if DEBUG
import Foundation
import SwiftData

/// Seeds the store with realistic sample data for development and previews.
/// Compiled only in DEBUG builds, so it never ships in a release.
enum SampleData {

    /// Seeds base data (foods, weight, saved meals, goal) once, and always re-anchors the sample
    /// logged meals to the past three days (including today) so they never go stale.
    static func populateIfEmpty(_ context: ModelContext) {
        let hasFoods = ((try? context.fetchCount(FetchDescriptor<Food>())) ?? 0) > 0
        if !hasFoods {
            seedBaseData(context)
            try? context.save() // persist so foods can be fetched when rebuilding meals
        }
        refreshSampleMeals(context)
        try? context.save()
    }

    // MARK: - Base data (seeded once)

    private static func seedBaseData(_ context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        // Foods (library)
        let chicken = Food(name: "Chicken Breast", caloriesPer100g: 165, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 3.6)
        let rice = Food(name: "White Rice, cooked", caloriesPer100g: 130, proteinPer100g: 2.7, carbsPer100g: 28, fatPer100g: 0.3)
        let broccoli = Food(name: "Broccoli", caloriesPer100g: 34, proteinPer100g: 2.8, carbsPer100g: 7, fatPer100g: 0.4)
        let banana = Food(name: "Banana", caloriesPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 23, fatPer100g: 0.3)
        let oats = Food(name: "Rolled Oats", caloriesPer100g: 389, proteinPer100g: 16.9, carbsPer100g: 66, fatPer100g: 6.9)
        let peanutButter = Food(name: "Peanut Butter", brand: "Jif", caloriesPer100g: 588, proteinPer100g: 25, carbsPer100g: 20, fatPer100g: 50)
        let whey = Food(name: "Whey Protein", brand: "Optimum Nutrition", caloriesPer100g: 400, proteinPer100g: 80, carbsPer100g: 8, fatPer100g: 6)
        let salmon = Food(name: "Salmon", caloriesPer100g: 208, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 13)
        let egg = Food(name: "Egg", caloriesPer100g: 155, proteinPer100g: 13, carbsPer100g: 1.1, fatPer100g: 11)
        let almonds = Food(name: "Almonds", caloriesPer100g: 579, proteinPer100g: 21, carbsPer100g: 22, fatPer100g: 50)
        let greekYogurt = Food(name: "Greek Yogurt", brand: "Fage", caloriesPer100g: 59, proteinPer100g: 10, carbsPer100g: 3.6, fatPer100g: 0.4)
        // A restaurant item logged without nutrition facts — demonstrates the "missing data" indicator.
        let burger = Food(name: "Restaurant Cheeseburger", caloriesPer100g: 0, proteinPer100g: 0, carbsPer100g: 0, fatPer100g: 0, hasNutritionData: false)

        for food in [chicken, rice, broccoli, banana, oats, peanutButter, whey, salmon, egg, almonds, greekYogurt, burger] {
            context.insert(food)
        }

        // Weight history (~90 days, gentle downward trend with noise)
        let startWeight = 190.0
        for dayOffset in stride(from: 90, through: 0, by: -3) {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dated = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: day) ?? day
            let progress = Double(90 - dayOffset) / 90.0
            let trend = startWeight - progress * 12.0
            let noise = Double.random(in: -0.8...0.8)
            let weight = ((trend + noise) * 10).rounded() / 10
            context.insert(WeightEntry(date: dated, weight: weight))
        }

        // Saved meals
        func makeSaved(_ name: String, items: [(Food, Double)]) {
            let saved = SavedMeal(name: name)
            context.insert(saved)
            for (food, grams) in items {
                let savedItem = SavedMealItem(food: food, grams: grams)
                context.insert(savedItem)
                saved.items.append(savedItem)
            }
        }

        makeSaved("Protein Oatmeal", items: [(oats, 60), (whey, 30), (banana, 100), (peanutButter, 15)])
        makeSaved("Chicken & Rice", items: [(chicken, 200), (rice, 250), (broccoli, 150)])
        makeSaved("Greek Yogurt Bowl", items: [(greekYogurt, 200), (almonds, 25), (banana, 100)])

        // Goal
        context.insert(Goal(title: "Cutting", dailyCalories: 2000, protein: 180, carbs: 180, fat: 60, isActive: true))

        // Profile for the seeded user (onboarding still shows on a fresh install so it can be previewed).
        let birthday = Calendar.current.date(byAdding: .year, value: -30, to: .now)
        context.insert(UserProfile(birthday: birthday, gender: .male, heightCM: 180))
        UserDefaults.standard.set("Alex", forKey: "displayName")
    }

    // MARK: - Logged meals (always the past three days, including today)

    private static func refreshSampleMeals(_ context: ModelContext) {
        // Clear existing meals so the sample always reflects exactly the past three days.
        if let existing = try? context.fetch(FetchDescriptor<Meal>()) {
            for meal in existing {
                context.delete(meal)
            }
        }

        let foods = (try? context.fetch(FetchDescriptor<Food>())) ?? []
        func food(_ name: String) -> Food? { foods.first { $0.name == name } }

        let savedMeals = (try? context.fetch(FetchDescriptor<SavedMeal>())) ?? []
        func savedMeal(_ name: String) -> SavedMeal? { savedMeals.first { $0.name == name } }

        let today = Calendar.current.startOfDay(for: .now)

        func loggedTime(_ mealName: String, dayOffset: Int) -> Date {
            let day = Calendar.current.date(byAdding: .day, value: -dayOffset, to: today) ?? today
            let hour: Int
            switch mealName {
            case "Breakfast": hour = 8
            case "Lunch": hour = 12
            case "Dinner": hour = 19
            default: hour = 15
            }
            return Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
        }

        func makeMeal(_ name: String, dayOffset: Int, sortIndex: Int, items: [(String, Double)]) {
            guard let day = Calendar.current.date(byAdding: .day, value: -dayOffset, to: today) else { return }
            let loggedAt = loggedTime(name, dayOffset: dayOffset)
            let meal = Meal(name: name, date: day, sortIndex: sortIndex)
            context.insert(meal)
            for (foodName, grams) in items {
                guard let source = food(foodName) else { continue }
                let item = MealItem(food: source, grams: grams)
                item.loggedAt = loggedAt
                context.insert(item)
                meal.items.append(item)
            }
        }

        // Logs a saved meal into a new meal as a single collapsed bundle.
        func logSavedMeal(_ savedName: String, mealName: String, dayOffset: Int, sortIndex: Int) {
            guard let saved = savedMeal(savedName),
                  let day = Calendar.current.date(byAdding: .day, value: -dayOffset, to: today) else { return }
            let loggedAt = loggedTime(mealName, dayOffset: dayOffset)
            let meal = Meal(name: mealName, date: day, sortIndex: sortIndex)
            context.insert(meal)
            let bundleID = UUID()
            for savedItem in saved.items {
                let item = MealItem(savedItem: savedItem)
                item.bundleID = bundleID
                item.bundleName = saved.name
                item.loggedAt = loggedAt
                context.insert(item)
                meal.items.append(item)
            }
        }

        // Today — Breakfast logged from the "Protein Oatmeal" saved meal (shown as one bundle row).
        logSavedMeal("Protein Oatmeal", mealName: "Breakfast", dayOffset: 0, sortIndex: 0)
        makeMeal("Lunch", dayOffset: 0, sortIndex: 1, items: [("Chicken Breast", 150), ("White Rice, cooked", 200), ("Broccoli", 100)])
        makeMeal("Snack", dayOffset: 0, sortIndex: 2, items: [("Greek Yogurt", 170), ("Almonds", 30), ("Restaurant Cheeseburger", 250)])

        // Yesterday
        makeMeal("Breakfast", dayOffset: 1, sortIndex: 0, items: [("Egg", 100), ("Rolled Oats", 50)])
        makeMeal("Dinner", dayOffset: 1, sortIndex: 1, items: [("Salmon", 180), ("White Rice, cooked", 220), ("Broccoli", 120)])

        // Two days ago — Lunch logged from the "Chicken & Rice" saved meal (bundle).
        logSavedMeal("Chicken & Rice", mealName: "Lunch", dayOffset: 2, sortIndex: 0)
    }
}
#endif
