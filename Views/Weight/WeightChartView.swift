import SwiftUI
import Charts

/// A single day's total calorie intake, for the optional overlay on the weight chart.
struct CaloriePoint: Identifiable {
    let date: Date
    let calories: Double
    var id: Date { date }
}

/// The weight trend line chart, or a placeholder when there aren't enough points.
///
/// Optionally overlays daily calorie intake. Because weight and calories live on very
/// different scales, the calorie series is linearly mapped into the weight axis's domain
/// and a second (trailing) axis is drawn showing the real calorie values.
struct WeightChartView: View {
    @Environment(\.appAccentColor) private var accent

    /// Entries in oldest-first order.
    let entries: [WeightEntry]
    /// Daily calorie totals in oldest-first order (empty when unavailable).
    var caloriePoints: [CaloriePoint] = []
    /// Whether to overlay the calorie series.
    var showCalories: Bool = false

    private let calorieColor = Color.orange

    private var canShowCalories: Bool { showCalories && !caloriePoints.isEmpty }

    /// Padded weight range used as the chart's y-domain.
    private var weightDomain: ClosedRange<Double> {
        let values = entries.map(\.weight)
        guard let lo = values.min(), let hi = values.max() else { return 0...1 }
        guard hi > lo else { return (lo - 1)...(hi + 1) }
        let pad = (hi - lo) * 0.1
        return (lo - pad)...(hi + pad)
    }

    /// Padded calorie range mapped onto the weight axis.
    private var calorieDomain: ClosedRange<Double> {
        let values = caloriePoints.map(\.calories)
        guard let lo = values.min(), let hi = values.max() else { return 0...1 }
        guard hi > lo else { return max(0, lo - 1)...(hi + 1) }
        let pad = (hi - lo) * 0.1
        return max(0, lo - pad)...(hi + pad)
    }

    /// Maps a calorie value into the weight axis domain so both series share one scale.
    private func calorieToWeight(_ calories: Double) -> Double {
        let cal = calorieDomain
        let w = weightDomain
        guard cal.upperBound > cal.lowerBound else { return w.lowerBound }
        let t = (calories - cal.lowerBound) / (cal.upperBound - cal.lowerBound)
        return w.lowerBound + t * (w.upperBound - w.lowerBound)
    }

    /// Inverse of `calorieToWeight`, used to label the trailing axis with real calorie values.
    private func weightToCalorie(_ weight: Double) -> Double {
        let cal = calorieDomain
        let w = weightDomain
        guard w.upperBound > w.lowerBound else { return cal.lowerBound }
        let t = (weight - w.lowerBound) / (w.upperBound - w.lowerBound)
        return cal.lowerBound + t * (cal.upperBound - cal.lowerBound)
    }

    /// A pair of adjacent calorie points. `isGap` is true when the two days aren't
    /// consecutive, so the connecting line can be dashed to signal interpolation.
    private struct CalorieSegment {
        let points: [CaloriePoint]
        let isGap: Bool
    }

    /// The calorie points split into drawable segments between adjacent days.
    private var calorieSegments: [CalorieSegment] {
        guard caloriePoints.count >= 2 else { return [] }
        var segments: [CalorieSegment] = []
        for i in 1..<caloriePoints.count {
            let a = caloriePoints[i - 1]
            let b = caloriePoints[i]
            let days = Calendar.current.dateComponents([.day], from: a.date, to: b.date).day ?? 1
            segments.append(CalorieSegment(points: [a, b], isGap: days > 1))
        }
        return segments
    }

    var body: some View {
        if entries.count >= 2 {
            Chart {
                ForEach(entries) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight),
                        series: .value("Metric", "Weight")
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(by: .value("Metric", "Weight"))

                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weight)
                    )
                    .foregroundStyle(by: .value("Metric", "Weight"))
                }

                if canShowCalories {
                    // Draw each segment separately so gaps between non-consecutive days
                    // can be dashed while contiguous days stay solid. Linear interpolation
                    // avoids the overshoot spikes a smoothed curve produces on sparse data.
                    ForEach(Array(calorieSegments.enumerated()), id: \.offset) { index, segment in
                        ForEach(segment.points) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Weight", calorieToWeight(point.calories)),
                                series: .value("Segment", index)
                            )
                            .interpolationMethod(.linear)
                            .foregroundStyle(by: .value("Metric", "Calories"))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: segment.isGap ? [4, 4] : []))
                        }
                    }

                    ForEach(caloriePoints) { point in
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Weight", calorieToWeight(point.calories))
                        )
                        .foregroundStyle(by: .value("Metric", "Calories"))
                    }
                }
            }
            .chartForegroundStyleScale(["Weight": accent, "Calories": calorieColor])
            .chartYScale(domain: weightDomain)
            .chartYAxis {
                AxisMarks(position: .leading)
                if canShowCalories {
                    AxisMarks(position: .trailing) { value in
                        AxisTick()
                        AxisValueLabel {
                            if let weight = value.as(Double.self) {
                                let calories = (weightToCalorie(weight) / 50).rounded() * 50
                                Text("\(Int(calories))")
                            }
                        }
                    }
                }
            }
            .chartLegend(canShowCalories ? .visible : .hidden)
        } else {
            EmptyStateView(title: "Not Enough Data",
                           systemImage: "chart.line.uptrend.xyaxis",
                           description: "Log at least two weigh-ins in this period to see a trend.")
        }
    }
}
