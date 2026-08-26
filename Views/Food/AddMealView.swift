import SwiftUI
import SwiftData

/// Sheet for creating a new meal for a day — either a named category, an auto-numbered
/// "Meal N", or a custom name.
struct AddMealView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let date: Date
    /// Number of meals that already exist for the day (used for numbering and ordering).
    let existingCount: Int
    /// Called with the newly created meal so the caller can immediately prompt to add an item.
    var onCreate: (Meal) -> Void

    private enum Style: String, CaseIterable, Identifiable {
        case category = "Category"
        case numbered = "Numbered"
        case custom = "Custom"
        var id: String { rawValue }
    }

    @State private var style: Style = .category
    @State private var category: MealCategory = .breakfast
    @State private var customName: String = ""

    private var resolvedName: String {
        switch style {
        case .category: return category.rawValue
        case .numbered: return "Meal \(existingCount + 1)"
        case .custom: return customName.trimmingCharacters(in: .whitespaces)
        }
    }

    private var canSave: Bool { !resolvedName.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Style", selection: $style) {
                    ForEach(Style.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                switch style {
                case .category:
                    Section("Category") {
                        Picker("Category", selection: $category) {
                            ForEach(MealCategory.allCases) { category in
                                Label(category.rawValue, systemImage: category.systemImage)
                                    .tag(category)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                case .numbered:
                    Section {
                        LabeledContent("Name", value: resolvedName)
                    } footer: {
                        Text("Numbered meals are handy if you don't want fixed categories.")
                    }
                case .custom:
                    Section("Name") {
                        TextField("e.g. Pre-Workout", text: $customName)
                    }
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let meal = Meal(name: resolvedName, date: date, sortIndex: existingCount)
        context.insert(meal)
        onCreate(meal)
        dismiss()
    }
}
