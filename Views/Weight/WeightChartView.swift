import SwiftUI
import Charts

/// The weight trend line chart, or a placeholder when there aren't enough points.
struct WeightChartView: View {
    /// Entries in oldest-first order.
    let entries: [WeightEntry]

    var body: some View {
        if entries.count >= 2 {
            Chart(entries) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weight)
                )
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", entry.date),
                    y: .value("Weight", entry.weight)
                )
            }
            .chartYScale(domain: .automatic(includesZero: false))
        } else {
            EmptyStateView(title: "Not Enough Data",
                           systemImage: "chart.line.uptrend.xyaxis",
                           description: "Log at least two weigh-ins in this period to see a trend.")
        }
    }
}
