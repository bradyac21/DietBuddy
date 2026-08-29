import SwiftUI
import SwiftData
import UIKit

/// Create or edit a single goal. When `goal` is nil a new goal is created on save.
///
/// Two entry modes keep calories and macros consistent so impossible goals can't be
/// saved: enter a calorie goal and pick a split (macros are derived), or enter macros
/// (calories are derived).
struct GoalEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allGoals: [Goal]

    let goal: Goal?

    private enum Mode { case caloriesSplit, macros }

    @State private var title: String
    @State private var mode: Mode
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var carbsText: String
    @State private var fatText: String
    @State private var preset: MacroSplitPreset
    @State private var proteinPctText: String
    @State private var carbsPctText: String
    @State private var fatPctText: String
    @State private var showingPercentAlert = false

    init(goal: Goal?) {
        self.goal = goal
        _title = State(initialValue: goal?.title ?? "")
        _caloriesText = State(initialValue: Self.numberString(goal?.dailyCalories))
        _proteinText = State(initialValue: Self.numberString(goal?.protein))
        _carbsText = State(initialValue: Self.numberString(goal?.carbs))
        _fatText = State(initialValue: Self.numberString(goal?.fat))
        // New goals start in Calories mode; editing starts in Macros mode so the
        // existing macros are preserved exactly unless the user changes them.
        _mode = State(initialValue: goal == nil ? .caloriesSplit : .macros)

        if let goal, goal.dailyCalories > 0 {
            // Seed the split from the goal's actual macro percentages so switching to
            // Calories mode doesn't silently change the targets.
            _preset = State(initialValue: .custom)
            _proteinPctText = State(initialValue: Self.wholeString(goal.protein * MacroMath.proteinKcalPerGram / goal.dailyCalories * 100))
            _carbsPctText = State(initialValue: Self.wholeString(goal.carbs * MacroMath.carbsKcalPerGram / goal.dailyCalories * 100))
            _fatPctText = State(initialValue: Self.wholeString(goal.fat * MacroMath.fatKcalPerGram / goal.dailyCalories * 100))
        } else {
            _preset = State(initialValue: .balanced)
            _proteinPctText = State(initialValue: "30")
            _carbsPctText = State(initialValue: "40")
            _fatPctText = State(initialValue: "30")
        }
    }

    private static func numberString(_ value: Double?) -> String {
        guard let value, value > 0 else { return "" }
        return value.formatted(.number.precision(.fractionLength(0...2)))
    }

    private static func wholeString(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }

    // MARK: - Derived values

    private var caloriesInput: Double { Double(caloriesText) ?? 0 }
    private var proteinInput: Double { Double(proteinText) ?? 0 }
    private var carbsInput: Double { Double(carbsText) ?? 0 }
    private var fatInput: Double { Double(fatText) ?? 0 }

    /// The ratio in effect for the calorie split (a preset, or the custom percentages).
    private var activeRatio: MacroRatio {
        if preset == .custom {
            return MacroRatio(proteinPercent: Double(proteinPctText) ?? 0,
                              carbsPercent: Double(carbsPctText) ?? 0,
                              fatPercent: Double(fatPctText) ?? 0)
        }
        return preset.ratio
    }

    private var percentSum: Double {
        activeRatio.proteinPercent + activeRatio.carbsPercent + activeRatio.fatPercent
    }

    private var customPercentsValid: Bool { abs(percentSum - 100) < 0.5 }

    private var splitGrams: (protein: Double, carbs: Double, fat: Double) {
        activeRatio.grams(forCalories: caloriesInput)
    }

    /// The final values that will be saved, guaranteed self-consistent.
    private var resolved: (calories: Double, protein: Double, carbs: Double, fat: Double) {
        switch mode {
        case .macros:
            return (MacroMath.calories(protein: proteinInput, carbs: carbsInput, fat: fatInput),
                    proteinInput, carbsInput, fatInput)
        case .caloriesSplit:
            let g = splitGrams
            return (caloriesInput, g.protein, g.carbs, g.fat)
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && resolved.calories > 0
    }

    var body: some View {
        Form {
            Section("Title") {
                TextField("e.g. Cutting, Maintenance", text: $title)
            }

            Section {
                Picker("Method", selection: $mode) {
                    Text("Calories").tag(Mode.caloriesSplit)
                    Text("Macros").tag(Mode.macros)
                }
                .pickerStyle(.segmented)
            }

            switch mode {
            case .caloriesSplit:
                Section("Calorie Goal") {
                    LabeledDecimalField(label: "Calories (kcal)", text: $caloriesText)
                }
                Section {
                    Picker("Split", selection: $preset) {
                        ForEach(MacroSplitPreset.allCases) { option in
                            Text(option.name).tag(option)
                        }
                    }

                    if preset == .custom {
                        LabeledDecimalField(label: "Protein %", text: $proteinPctText)
                        LabeledDecimalField(label: "Carbs %", text: $carbsPctText)
                        LabeledDecimalField(label: "Fat %", text: $fatPctText)
                        LabeledContent("Total", value: "\(whole(percentSum))%")
                    } else {
                        LabeledContent("Ratio", value: preset.summary)
                    }

                    LabeledContent("Protein", value: "\(whole(splitGrams.protein)) g")
                    LabeledContent("Carbs", value: "\(whole(splitGrams.carbs)) g")
                    LabeledContent("Fat", value: "\(whole(splitGrams.fat)) g")
                } header: {
                    Text("Macro Split")
                } footer: {
                    Text("Macros are calculated from your calorie goal and the selected split.")
                }
            case .macros:
                Section {
                    LabeledDecimalField(label: "Protein (g)", text: $proteinText)
                    LabeledDecimalField(label: "Carbs (g)", text: $carbsText)
                    LabeledDecimalField(label: "Fat (g)", text: $fatText)
                    LabeledContent("Calories", value: "\(whole(resolved.calories)) kcal")
                } header: {
                    Text("Daily Macros")
                } footer: {
                    Text("Calories are calculated from your macros (4 kcal per gram of protein and carbs, 9 for fat).")
                }
            }
        }
        .navigationTitle(goal == nil ? "New Goal" : "Edit Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!canSave)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                    to: nil, from: nil, for: nil)
                }
            }
        }
        .alert("Macro Split Must Total 100%", isPresented: $showingPercentAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your custom split adds up to \(whole(percentSum))%. Adjust the percentages so they total 100%.")
        }
    }

    private func whole(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }

    private func save() {
        if mode == .caloriesSplit, preset == .custom, !customPercentsValid {
            showingPercentAlert = true
            return
        }

        let trimmed = title.trimmingCharacters(in: .whitespaces)
        let r = resolved

        if let goal {
            goal.title = trimmed
            goal.dailyCalories = r.calories.rounded()
            goal.protein = r.protein.rounded()
            goal.carbs = r.carbs.rounded()
            goal.fat = r.fat.rounded()
        } else {
            let shouldActivate = !allGoals.contains { $0.isActive }
            context.insert(Goal(title: trimmed,
                                dailyCalories: r.calories.rounded(),
                                protein: r.protein.rounded(),
                                carbs: r.carbs.rounded(),
                                fat: r.fat.rounded(),
                                isActive: shouldActivate))
        }
        dismiss()
    }
}
