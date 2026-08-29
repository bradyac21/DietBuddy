import SwiftUI
import SwiftData

/// Read-only view of a single goal. The Edit button opens the editor to make changes.
struct GoalDetailView: View {
    @Query private var allGoals: [Goal]
    let goal: Goal

    @State private var isEditing = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 6) {
                    Text(goal.title).font(.headline)
                    if goal.isActive {
                        Text("Active")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.2), in: Capsule())
                            .foregroundStyle(.green)
                    }
                }
            }

            Section("Daily Targets") {
                LabeledContent("Calories", value: "\(whole(goal.dailyCalories)) kcal")
                LabeledContent("Protein", value: "\(whole(goal.protein)) g")
                LabeledContent("Carbs", value: "\(whole(goal.carbs)) g")
                LabeledContent("Fat", value: "\(whole(goal.fat)) g")
            }

            Section {
                LabeledContent("Created", value: goal.createdAt.formatted(date: .abbreviated, time: .omitted))
            }

            if !goal.isActive {
                Section {
                    Button("Set as Active Goal") { setActive() }
                }
            }
        }
        .navigationTitle("Goal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                GoalEditor(goal: goal)
            }
        }
    }

    private func whole(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }

    private func setActive() {
        for candidate in allGoals {
            candidate.isActive = (candidate.id == goal.id)
        }
    }
}
