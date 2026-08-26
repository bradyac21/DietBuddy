import SwiftUI
import SwiftData

/// Lists all user-created goals and provides create / edit / delete / set-active.
struct GoalListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]

    @State private var isCreating = false

    var body: some View {
        List {
            if goals.isEmpty {
                EmptyStateView(title: "No Goals Yet",
                               systemImage: "target",
                               description: "Create a goal to track your daily targets.")
            } else {
                ForEach(goals) { goal in
                    NavigationLink {
                        GoalEditor(goal: goal)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
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
                            Text("\(goal.dailyCalories, format: .number.precision(.fractionLength(0))) kcal · P \(goal.protein, format: .number.precision(.fractionLength(0)))g · C \(goal.carbs, format: .number.precision(.fractionLength(0)))g · F \(goal.fat, format: .number.precision(.fractionLength(0)))g")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Created \(goal.createdAt, format: .dateTime.month().day().year())")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        if !goal.isActive {
                            Button {
                                setActive(goal)
                            } label: {
                                Label("Set Active", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                    }
                }
                .onDelete(perform: deleteGoals)
            }
        }
        .navigationTitle("Goals")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isCreating = true
                } label: {
                    Label("New Goal", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isCreating) {
            NavigationStack {
                GoalEditor(goal: nil)
            }
        }
        .onAppear { ensureActiveExists() }
    }

    private func setActive(_ goal: Goal) {
        for candidate in goals {
            candidate.isActive = (candidate.id == goal.id)
        }
    }

    /// Guarantees one active goal exists when there are goals (activates the most recent).
    private func ensureActiveExists() {
        guard !goals.isEmpty, !goals.contains(where: { $0.isActive }) else { return }
        goals.first?.isActive = true
    }

    private func deleteGoals(at offsets: IndexSet) {
        let deletingActive = offsets.contains { goals[$0].isActive }
        let deletedIDs = Set(offsets.map { goals[$0].id })
        for index in offsets {
            context.delete(goals[index])
        }
        // If the active goal was removed, promote the most recent remaining goal.
        if deletingActive {
            let survivors = goals.filter { !deletedIDs.contains($0.id) }
            survivors.sorted { $0.createdAt > $1.createdAt }.first?.isActive = true
        }
    }
}
