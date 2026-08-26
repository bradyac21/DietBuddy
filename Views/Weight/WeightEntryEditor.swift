import SwiftUI
import SwiftData

/// Sheet used to create a new weigh-in or edit an existing one.
struct WeightEntryEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let entry: WeightEntry?
    let unit: String

    @State private var weightText: String
    @State private var date: Date

    init(entry: WeightEntry?, unit: String) {
        self.entry = entry
        self.unit = unit
        _weightText = State(initialValue: entry.map { $0.weight.formatted(.number.precision(.fractionLength(0...1))) } ?? "")
        _date = State(initialValue: entry?.date ?? .now)
    }

    private var weight: Double? { Double(weightText) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Weight (\(unit))") {
                    TextField("Weight", text: $weightText)
                        .keyboardType(.decimalPad)
                }
                Section {
                    DatePicker("Date & Time",
                               selection: $date,
                               in: ...Date.now,
                               displayedComponents: [.date, .hourAndMinute])
                } footer: {
                    Text("Tip: weigh yourself at the same time each day (for example, right after waking up) for the most consistent, comparable results.")
                }
            }
            .navigationTitle(entry == nil ? "Log Weight" : "Edit Weigh-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled((weight ?? 0) <= 0)
                }
            }
        }
    }

    private func save() {
        guard let weight else { return }
        if let entry {
            entry.weight = weight
            entry.date = date
        } else {
            context.insert(WeightEntry(date: date, weight: weight))
        }
        dismiss()
    }
}
