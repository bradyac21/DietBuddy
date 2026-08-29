import SwiftUI
import SwiftData

/// An index of every unique food that's been logged, with per-food averages and totals.
/// Reached from the tracking history screen.
struct FoodIndexView: View {
    @Query private var items: [MealItem]
    @State private var sort: FoodIndexSort = .nameAscending

    /// Logged items grouped into one summary per unique food (name + brand), then sorted.
    private var summaries: [LoggedFoodSummary] {
        let groups = Dictionary(grouping: items) { item in
            "\(item.foodName.trimmingCharacters(in: .whitespaces).lowercased())|\(item.brand?.lowercased() ?? "")"
        }
        let list = groups.map { key, groupItems in LoggedFoodSummary(id: key, items: groupItems) }
        return sorted(list)
    }

    var body: some View {
        List {
            if summaries.isEmpty {
                EmptyStateView(title: "No Logged Foods",
                               systemImage: "text.book.closed",
                               description: "Foods you log will be indexed here.")
            } else {
                ForEach(summaries) { summary in
                    LoggedFoodRow(summary: summary)
                }
            }
        }
        .navigationTitle("Food Index")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker("Sort", selection: $sort) {
                        ForEach(FoodIndexSort.allCases) { option in
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

    private func sorted(_ list: [LoggedFoodSummary]) -> [LoggedFoodSummary] {
        switch sort {
        case .nameAscending:
            list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending:
            list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .countAscending:
            list.sorted { $0.count < $1.count }
        case .countDescending:
            list.sorted { $0.count > $1.count }
        }
    }
}

/// Sort orders for the food index.
enum FoodIndexSort: String, CaseIterable, Identifiable {
    case nameAscending, nameDescending, countAscending, countDescending

    var id: String { rawValue }

    var label: String {
        switch self {
        case .nameAscending: "Name (A–Z)"
        case .nameDescending: "Name (Z–A)"
        case .countAscending: "Times Logged (Low–High)"
        case .countDescending: "Times Logged (High–Low)"
        }
    }
}

/// Aggregated stats for one unique logged food.
struct LoggedFoodSummary: Identifiable {
    let id: String
    let name: String
    let brand: String?
    let count: Int
    let averageGrams: Double
    let averageCalories: Double
    let averageProtein: Double
    let averageCarbs: Double
    let averageFat: Double
    let totalGrams: Double
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double

    init(id: String, items: [MealItem]) {
        self.id = id
        self.name = items.first?.foodName ?? ""
        self.brand = items.first?.brand
        self.count = items.count

        let n = Double(max(items.count, 1))
        totalGrams = items.reduce(0) { $0 + $1.grams }
        totalCalories = items.reduce(0) { $0 + $1.calories }
        totalProtein = items.reduce(0) { $0 + $1.protein }
        totalCarbs = items.reduce(0) { $0 + $1.carbs }
        totalFat = items.reduce(0) { $0 + $1.fat }
        averageGrams = totalGrams / n
        averageCalories = totalCalories / n
        averageProtein = totalProtein / n
        averageCarbs = totalCarbs / n
        averageFat = totalFat / n
    }
}

/// A collapsible index entry: the food name with a times-logged badge, expanding to
/// its average-per-serving and total-logged stats.
private struct LoggedFoodRow: View {
    let summary: LoggedFoodSummary
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    Text("")
                        .gridColumnAlignment(.leading)
                    Text("Average")
                        .gridColumnAlignment(.trailing)
                    Text("Total")
                        .gridColumnAlignment(.trailing)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Divider().gridCellColumns(3)

                GridRow {
                    Text("Serving").foregroundStyle(.secondary)
                    Text(format(summary.averageGrams, "g"))
                    Text(format(summary.totalGrams, "g"))
                }
                GridRow {
                    Text("Calories").foregroundStyle(.secondary)
                    Text(format(summary.averageCalories, "kcal"))
                    Text(format(summary.totalCalories, "kcal"))
                }
                GridRow {
                    Text("Protein").foregroundStyle(.secondary)
                    Text(format(summary.averageProtein, "g"))
                    Text(format(summary.totalProtein, "g"))
                }
                GridRow {
                    Text("Carbs").foregroundStyle(.secondary)
                    Text(format(summary.averageCarbs, "g"))
                    Text(format(summary.totalCarbs, "g"))
                }
                GridRow {
                    Text("Fat").foregroundStyle(.secondary)
                    Text(format(summary.averageFat, "g"))
                    Text(format(summary.totalFat, "g"))
                }
            }
            .font(.subheadline)
            .padding(.vertical, 4)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.name)
                    if let brand = summary.brand, !brand.isEmpty {
                        Text(brand).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("\(summary.count)×")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func format(_ value: Double, _ unit: String) -> String {
        "\(value.formatted(.number.precision(.fractionLength(0...1)))) \(unit)"
    }
}
