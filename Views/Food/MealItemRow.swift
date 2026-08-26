import SwiftUI

/// A row summarizing one logged food portion.
struct MealItemRow: View {
    let item: MealItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.foodName)
                Text("\(item.grams, format: .number.precision(.fractionLength(0))) g")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if item.hasNutritionData {
                Text("\(item.calories, format: .number.precision(.fractionLength(0))) kcal")
                    .foregroundStyle(.secondary)
            } else {
                Text("No data")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
