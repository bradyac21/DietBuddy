import SwiftUI

/// Sheet for naming and saving a meal, enforcing unique saved-meal names.
struct SaveMealSheet: View {
    @Environment(\.dismiss) private var dismiss

    let meal: Meal
    let existingNames: Set<String>
    let onSave: (String) -> Void

    @State private var name: String

    init(meal: Meal, existingNames: Set<String>, onSave: @escaping (String) -> Void) {
        self.meal = meal
        self.existingNames = existingNames
        self.onSave = onSave
        _name = State(initialValue: meal.name)
    }

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }
    private var isDuplicate: Bool { existingNames.contains(trimmed.lowercased()) }
    private var canSave: Bool { !trimmed.isEmpty && !isDuplicate }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                } footer: {
                    if isDuplicate {
                        Text("A saved meal named \"\(trimmed)\" already exists. Choose a different name.")
                            .foregroundStyle(.red)
                    } else {
                        Text("Save this meal so you can quickly add it again later.")
                    }
                }
            }
            .navigationTitle("Save Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(trimmed)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
