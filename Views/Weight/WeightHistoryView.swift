import SwiftUI
import SwiftData

/// Full, editable weight history.
struct WeightHistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]
    @AppStorage("weightUnit") private var weightUnit: String = "lb"

    @State private var editingEntry: WeightEntry?

    var body: some View {
        List {
            ForEach(entries) { entry in
                Button {
                    editingEntry = entry
                } label: {
                    WeightRowLabel(entry: entry, unit: weightUnit)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: deleteEntries)
        }
        .navigationTitle("Weight History")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if entries.isEmpty {
                EmptyStateView(title: "No Weigh-Ins Yet",
                               systemImage: "scalemass",
                               description: "Log a weight to start building history.")
            }
        }
        .sheet(item: $editingEntry) { entry in
            WeightEntryEditor(entry: entry, unit: weightUnit)
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            context.delete(entries[index])
        }
    }
}
