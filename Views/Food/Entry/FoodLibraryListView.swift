import SwiftUI
import SwiftData

/// A searchable, sortable list of every previously logged food. Selecting one opens
/// the entry form (prefilled) so the user can pick a portion and re-log it.
struct FoodLibraryListView: View {
    /// Called with the chosen food and portion size (grams) when the user confirms.
    let onCommit: (Food, Double) -> Void

    @Query(sort: \Food.name) private var foods: [Food]
    @State private var searchText = ""
    @State private var sort: FoodLibrarySort = .recent

    /// Only foods that have actually been logged, filtered by the search text and sorted.
    private var results: [Food] {
        let logged = foods.filter { $0.lastLoggedAt != nil }
        let filtered: [Food]
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            filtered = logged
        } else {
            filtered = logged.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
                || ($0.brand?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        return sorted(filtered)
    }

    var body: some View {
        List {
            if results.isEmpty {
                EmptyStateView(title: "No Foods Found",
                               systemImage: "magnifyingglass",
                               description: "Foods you scan or enter will appear here.")
            } else {
                ForEach(results) { food in
                    NavigationLink {
                        FoodEntryForm(title: food.name,
                                      mode: .library,
                                      draft: FoodDraft(from: food),
                                      existingFood: food,
                                      onCommit: onCommit)
                    } label: {
                        FoodLibraryRow(food: food)
                    }
                }
            }
        }
        .navigationTitle("Previously Logged")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search foods")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Sort", selection: $sort) {
                        ForEach(FoodLibrarySort.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .accessibilityLabel("Sort")
            }
        }
    }

    private func sorted(_ list: [Food]) -> [Food] {
        switch sort {
        case .recent:
            list.sorted { ($0.lastLoggedAt ?? .distantPast) > ($1.lastLoggedAt ?? .distantPast) }
        case .mostLogged:
            list.sorted { $0.timesLogged > $1.timesLogged }
        case .nameAscending:
            list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        }
    }
}

/// Sort orders for the previously-logged food library.
enum FoodLibrarySort: String, CaseIterable, Identifiable {
    case recent, mostLogged, nameAscending, nameDescending

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recent: "Recently Logged"
        case .mostLogged: "Most Logged"
        case .nameAscending: "Name (A–Z)"
        case .nameDescending: "Name (Z–A)"
        }
    }
}
