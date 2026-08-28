import SwiftUI

/// Explains what BMI is and lists the standard category ranges. Shown in a popover
/// from the info button on the Weight tab's BMI row.
struct BMIInfoView: View {
    private struct CategoryRange: Identifiable {
        let id = UUID()
        let name: String
        let value: String
        let color: Color
    }

    // Colors come from BMICalculator so the ranges match the value shown on the Weight tab.
    private let ranges: [CategoryRange] = [
        CategoryRange(name: "Underweight", value: "Below 18.5", color: BMICalculator.categoryColor(17)),
        CategoryRange(name: "Normal", value: "18.5 – 24.9", color: BMICalculator.categoryColor(22)),
        CategoryRange(name: "Overweight", value: "25.0 – 29.9", color: BMICalculator.categoryColor(27)),
        CategoryRange(name: "Obese", value: "30.0 and above", color: BMICalculator.categoryColor(32))
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About BMI").font(.headline)

            Text("Body Mass Index estimates body fat from your height and weight. It's a general screening guide and doesn't account for muscle mass or body composition.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                ForEach(ranges) { range in
                    HStack(spacing: 10) {
                        Circle().fill(range.color).frame(width: 10, height: 10)
                        Text(range.name)
                        Spacer()
                        Text(range.value).foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
        .frame(width: 300)
    }
}
