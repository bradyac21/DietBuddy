import SwiftUI

/// Shows the net weight change over the selected period, colored by direction.
struct WeightChangeSummaryView: View {
    let change: Double
    let unit: String
    let period: String

    var body: some View {
        let isLoss = change < 0
        HStack {
            Image(systemName: isLoss ? "arrow.down.right" : (change == 0 ? "arrow.right" : "arrow.up.right"))
            Text("\(change >= 0 ? "+" : "")\(change, format: .number.precision(.fractionLength(1))) \(unit) over \(period)")
            Spacer()
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(change == 0 ? Color.secondary : (isLoss ? Color.green : Color.orange))
    }
}
