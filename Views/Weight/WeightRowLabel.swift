import SwiftUI

/// A tappable weight-history row: date/time, weight, and a chevron affordance.
struct WeightRowLabel: View {
    let entry: WeightEntry
    let unit: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date, format: .dateTime.month().day().year())
                    .foregroundStyle(.primary)
                Text(entry.date, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(entry.weight, format: .number.precision(.fractionLength(1))) \(unit)")
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}
