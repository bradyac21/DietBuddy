import SwiftUI
import SwiftData

/// Create or edit a single goal. When `goal` is nil a new goal is created on save.
struct GoalEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allGoals: [Goal]

    let goal: Goal?

    @State private var title: String
    @State private var dailyCaloriesText: String
    @State private var proteinText: String
    @State private var carbsText: String
    @State private var fatText: String

    init(goal: Goal?) {
        self.goal = goal
        _title = State(initialValue: goal?.title ?? "")
        _dailyCaloriesText = State(initialValue: Self.numberString(goal?.dailyCalories))
        _proteinText = State(initialValue: Self.numberString(goal?.protein))
        _carbsText = State(initialValue: Self.numberString(goal?.carbs))
        _fatText = State(initialValue: Self.numberString(goal?.fat))
    }

    private static func numberString(_ value: Double?) -> String {
        value.map { $0.formatted(.number.precision(.fractionLength(0...2))) } ?? ""
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section("Title") {
                TextField("e.g. Cutting, Maintenance", text: $title)
            }
            Section("Daily Targets") {
                macroField("Calories (kcal)", text: $dailyCaloriesText)
                macroField("Protein (g)", text: $proteinText)
                macroField("Carbs (g)", text: $carbsText)
                macroField("Fat (g)", text: $fatText)
            }
        }
        .navigationTitle(goal == nil ? "New Goal" : "Edit Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if goal == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!canSave)
            }
        }
    }

    private func macroField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField(label, text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        let calories = Double(dailyCaloriesText) ?? 0
        let proteinValue = Double(proteinText) ?? 0
        let carbsValue = Double(carbsText) ?? 0
        let fatValue = Double(fatText) ?? 0
        if let goal {
            goal.title = trimmed
            goal.dailyCalories = calories
            goal.protein = proteinValue
            goal.carbs = carbsValue
            goal.fat = fatValue
        } else {
            // Make the first goal active automatically.
            let shouldActivate = !allGoals.contains { $0.isActive }
            context.insert(Goal(title: trimmed,
                                 dailyCalories: calories,
                                 protein: proteinValue,
                                 carbs: carbsValue,
                                 fat: fatValue,
                                 isActive: shouldActivate))
        }
        dismiss()
    }
}
