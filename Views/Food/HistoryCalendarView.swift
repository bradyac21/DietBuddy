import SwiftUI

/// A month calendar for browsing history. Opens on the current month; left/right
/// step between months. Days with logged food are marked, and tapping any day
/// navigates to that day's food.
struct HistoryCalendarView: View {
    /// Start-of-day dates that have logged food, for marking cells.
    let daysWithData: Set<Date>

    @Environment(\.appAccentColor) private var accent

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    @State private var monthAnchor: Date = Calendar.current.startOfMonth(for: .now)
    @State private var shakeTrigger = 0

    /// Whether the displayed month is the current month (forward navigation stops here).
    private var isCurrentMonth: Bool {
        calendar.isDate(monthAnchor, equalTo: .now, toGranularity: .month)
    }

    /// The earliest month that has logged food; backward navigation stops here.
    private var earliestMonth: Date {
        guard let earliest = daysWithData.min() else { return calendar.startOfMonth(for: .now) }
        return calendar.startOfMonth(for: earliest)
    }

    private var canGoBack: Bool { monthAnchor > earliestMonth }

    var body: some View {
        VStack(spacing: 16) {
            monthHeader
            weekdayHeader
            daysGrid
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var monthHeader: some View {
        HStack {
            Button {
                if canGoBack { shiftMonth(by: -1) } else { triggerShake() }
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)

            Spacer()

            Text(monthAnchor, format: .dateTime.month(.wide).year())
                .font(.headline)
                .shake(shakeTrigger)

            Spacer()

            Button {
                if isCurrentMonth { triggerShake() } else { shiftMonth(by: 1) }
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)
        }
        .font(.title3)
        .foregroundStyle(accent)
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var daysGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(Array(monthCells.enumerated()), id: \.offset) { _, cellDate in
                if let cellDate {
                    dayCell(cellDate)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let hasData = daysWithData.contains(calendar.startOfDay(for: date))
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > .now && !isToday

        return NavigationLink {
            DayFoodView(date: date)
        } label: {
            Text("\(calendar.component(.day, from: date))")
                .font(.callout)
                .fontWeight(hasData ? .semibold : .regular)
                .foregroundStyle(isFuture ? AnyShapeStyle(.tertiary)
                                 : hasData ? AnyShapeStyle(accent) : AnyShapeStyle(.primary))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background {
                    if hasData {
                        Circle().fill(accent.opacity(0.18))
                    }
                    if isToday {
                        Circle().stroke(accent, lineWidth: 1.5)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
    }

    // MARK: - Layout data

    /// Weekday header symbols, ordered to match the calendar's first weekday.
    private var weekdaySymbols: [String] {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let shift = calendar.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    /// Cells for the month: leading `nil`s for the first-week offset, then each day.
    private var monthCells: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: monthAnchor) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: monthAnchor)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7

        var cells: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for day in range {
            cells.append(calendar.date(byAdding: .day, value: day - 1, to: monthAnchor))
        }
        return cells
    }

    private func shiftMonth(by months: Int) {
        if let newAnchor = calendar.date(byAdding: .month, value: months, to: monthAnchor) {
            withAnimation { monthAnchor = newAnchor }
        }
    }

    private func triggerShake() {
        withAnimation(.linear(duration: 0.4)) { shakeTrigger += 1 }
    }
}

private extension Calendar {
    /// The first instant of the month containing `date`.
    func startOfMonth(for date: Date) -> Date {
        self.date(from: dateComponents([.year, .month], from: date)) ?? startOfDay(for: date)
    }
}
