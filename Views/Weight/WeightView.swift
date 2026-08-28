import SwiftUI
import SwiftData

/// Selectable time window for the weight chart.
enum WeightPeriod: String, CaseIterable, Identifiable {
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    case all = "All"

    var id: String { rawValue }

    /// Number of days the window spans, or `nil` for "all time".
    var days: Int? {
        switch self {
        case .month: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .year: return 365
        case .all: return nil
        }
    }
}

/// Weight-tracking tab: shows change in weight over time and lets the user log or edit entries.
struct WeightView: View {
    @Environment(\.appAccentColor) private var accent
    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]
    @Query private var profiles: [UserProfile]
    @AppStorage("weightUnit") private var weightUnit: String = "lb"

    @State private var period: WeightPeriod = .threeMonths
    @State private var editingEntry: WeightEntry?
    @State private var isLogging = false

    /// Newest-first, limited to the chart window.
    private var filteredEntries: [WeightEntry] {
        guard let days = period.days else { return entries }
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .distantPast
        return entries.filter { $0.date >= cutoff }
    }

    /// Oldest-first, for charting.
    private var chartEntries: [WeightEntry] { filteredEntries.reversed() }

    private var recentEntries: [WeightEntry] { Array(entries.prefix(3)) }

    private var change: Double? {
        guard let last = filteredEntries.first?.weight,
              let first = filteredEntries.last?.weight else { return nil }
        return last - first
    }

    /// BMI from the most recent weigh-in and the profile height, if both are available.
    private var bmi: Double? {
        guard let latest = entries.first?.weight else { return nil }
        return BMICalculator.bmi(weight: latest, weightUnit: weightUnit, heightCM: profiles.first?.heightCM ?? 0)
    }

    var body: some View {
        List {
            Section {
                Picker("Period", selection: $period) {
                    ForEach(WeightPeriod.allCases) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
                .pickerStyle(.segmented)

                WeightChartView(entries: chartEntries)
                    .frame(height: 220)
                    .padding(.vertical, 8)

                if let change {
                    WeightChangeSummaryView(change: change, unit: weightUnit, period: period.rawValue)
                }

                if let bmi {
                    HStack {
                        Text("BMI")
                        Spacer()
                        Text("\(bmi, format: .number.precision(.fractionLength(1)))")
                        Text("· \(BMICalculator.category(bmi))").foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }

            Section("Recent") {
                if entries.isEmpty {
                    EmptyStateView(title: "No Weigh-Ins Yet",
                                   systemImage: "scalemass",
                                   description: "Tap the + button to log your first weight.")
                } else {
                    ForEach(recentEntries) { entry in
                        Button {
                            editingEntry = entry
                        } label: {
                            WeightRowLabel(entry: entry, unit: weightUnit)
                        }
                        .buttonStyle(.plain)
                    }

                    NavigationLink {
                        WeightHistoryView()
                    } label: {
                        Text("See All History")
                            .foregroundStyle(accent)
                    }
                }
            }
        }
        .navigationTitle("Weight")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isLogging = true
                } label: {
                    Label("Log Weight", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isLogging) {
            WeightEntryEditor(entry: nil, unit: weightUnit)
        }
        .sheet(item: $editingEntry) { entry in
            WeightEntryEditor(entry: entry, unit: weightUnit)
        }
    }
}
