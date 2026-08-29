import SwiftUI

/// A row describing a saved food: its name, optional brand, per-100g calories,
/// and how many times it's been logged.
struct FoodLibraryRow: View {
    let food: Food

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(food.name)
            HStack(spacing: 6) {
                if let brand = food.brand, !brand.isEmpty {
                    Text(brand)
                    Text("·")
                }
                Text("\(food.caloriesPer100g, format: .number.precision(.fractionLength(0))) kcal / 100 g")
                if food.timesLogged > 0 {
                    Text("·")
                    Text("logged \(food.timesLogged)×")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
