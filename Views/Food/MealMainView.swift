import SwiftUI
import SwiftData

/// Main food-tracking tab: the day's macro totals, user-created meals, and the active goal.
struct MealMainView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Meal.date, order: .reverse),
                  SortDescriptor(\Meal.sortIndex)]) private var allMeals: [Meal]
    @Query private var goals: [Goal]
    @Query private var savedMeals: [SavedMeal]

    @State private var isAddingMeal = false
    @State private var addItemTarget: Meal?
    @State private var pendingItemMeal: Meal?
    @State private var savingMeal: Meal?

    private var todayMeals: [Meal] {
        allMeals
            .filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    private var dayCalories: Double { todayMeals.reduce(0) { $0 + $1.totalCalories } }
    private var dayProtein: Double { todayMeals.reduce(0) { $0 + $1.totalProtein } }
    private var dayCarbs: Double { todayMeals.reduce(0) { $0 + $1.totalCarbs } }
    private var dayFat: Double { todayMeals.reduce(0) { $0 + $1.totalFat } }
    private var dayHasMissingNutrition: Bool { todayMeals.contains { $0.hasMissingNutrition } }

    /// The goal that drives the day's targets: the active one, or the most recent as a fallback.
    private var activeGoal: Goal? {
        goals.first(where: { $0.isActive }) ?? goals.sorted { $0.createdAt > $1.createdAt }.first
    }

    /// Lowercased, trimmed names of existing saved meals, for uniqueness checks.
    private var savedMealNames: Set<String> {
        Set(savedMeals.map { $0.name.trimmingCharacters(in: .whitespaces).lowercased() })
    }

    var body: some View {
        List {
            Section("Today · \(Date.now, format: .dateTime.month().day())") {
                MacroSummaryView(calories: dayCalories,
                                 protein: dayProtein,
                                 carbs: dayCarbs,
                                 fat: dayFat,
                                 goal: activeGoal,
                                 hasMissingData: dayHasMissingNutrition)
                .padding(.vertical, 4)
            }

            if todayMeals.isEmpty {
                Section {
                    EmptyStateView(title: "No Meals Yet",
                                   systemImage: "fork.knife",
                                   description: "Tap the + button to add a meal like Breakfast or Meal 1.")
                }
            } else {
                Section("Meals") {
                    ForEach(todayMeals) { meal in
                        MealDisclosureView(meal: meal,
                                           onAddItem: { addItemTarget = $0 },
                                           onSaveMeal: { savingMeal = $0 },
                                           onUnsaveMeal: { unsaveMeal($0) })
                    }
                }
            }

            Section("Goal") {
                if let goal = activeGoal {
                    NavigationLink {
                        GoalListView()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal.title).font(.headline)
                            Text("\(goal.dailyCalories, format: .number.precision(.fractionLength(0))) kcal · P \(goal.protein, format: .number.precision(.fractionLength(0)))g · C \(goal.carbs, format: .number.precision(.fractionLength(0)))g · F \(goal.fat, format: .number.precision(.fractionLength(0)))g")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    NavigationLink {
                        GoalListView()
                    } label: {
                        Label("Create your first goal", systemImage: "target")
                    }
                }
            }

            Section {
                NavigationLink {
                    MealHistoryView()
                } label: {
                    Label("Tracking History", systemImage: "clock.arrow.circlepath")
                }
            }
        }
        .navigationTitle("Food")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddingMeal = true
                } label: {
                    Label("Add Meal", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingMeal, onDismiss: {
            // Chain straight into adding the first item once the "Add Meal" sheet has dismissed.
            if let meal = pendingItemMeal {
                pendingItemMeal = nil
                addItemTarget = meal
            }
        }) {
            AddMealView(date: .now, existingCount: todayMeals.count) { meal in
                pendingItemMeal = meal
            }
        }
        .sheet(item: $addItemTarget) { meal in
            AddMealItemView(mealName: meal.name, onAddSavedMeal: { saved in
                let bundleID = UUID()
                for savedItem in saved.items {
                    let item = MealItem(savedItem: savedItem)
                    item.bundleID = bundleID
                    item.bundleName = saved.name
                    context.insert(item)
                    meal.items.append(item)
                }
            }) { food, grams in
                let item = MealItem(food: food, grams: grams)
                context.insert(item)
                meal.items.append(item)
            }
        }
        .sheet(item: $savingMeal) { meal in
            SaveMealSheet(meal: meal, existingNames: savedMealNames) { name in
                performSaveMeal(meal, name: name)
            }
        }
        .onAppear {
            // Ensure one active goal exists so the day rings track a stable target.
            if !goals.isEmpty, !goals.contains(where: { $0.isActive }) {
                goals.sorted { $0.createdAt > $1.createdAt }.first?.isActive = true
            }
        }
    }

    private func performSaveMeal(_ meal: Meal, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let saved = SavedMeal(name: trimmed.isEmpty ? meal.name : trimmed)
        context.insert(saved)
        for item in meal.items {
            let savedItem = SavedMealItem(from: item)
            context.insert(savedItem)
            saved.items.append(savedItem)
        }
        meal.savedMeal = saved
    }

    private func unsaveMeal(_ meal: Meal) {
        if let saved = meal.savedMeal {
            context.delete(saved)
        }
        meal.savedMeal = nil
    }
}
