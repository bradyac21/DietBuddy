import SwiftUI
import SwiftData

/// Three-tab root: Weight tracking, Food tracking, and Account/Settings.
struct RootTabView: View {
    @AppStorage("appearance") private var appearance: String = AppAppearance.system.rawValue
    @AppStorage("accentColorName") private var accentColorName: String = AppAccent.blue.rawValue

    private var preferredScheme: ColorScheme? {
        AppAppearance(rawValue: appearance)?.colorScheme
    }

    private var accentColor: Color {
        (AppAccent(rawValue: accentColorName) ?? .blue).color
    }

    /// Tabs, in display order. The app opens to Food.
    private enum AppTab: Hashable { case weight, food, account }
    @State private var selection: AppTab = .food

    var body: some View {
        TabView(selection: $selection) {
            Tab("Weight", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.weight) {
                NavigationStack { WeightView() }
            }
            Tab("Food", systemImage: "fork.knife", value: AppTab.food) {
                NavigationStack { MealMainView() }
            }
            Tab("Account", systemImage: "person.crop.circle", value: AppTab.account) {
                NavigationStack { AccountSettingsView() }
            }
        }
        .tint(accentColor)
        .preferredColorScheme(preferredScheme)
        .environment(\.appAccentColor, accentColor)
        .onAppear { applyNavigationBarAccent(accentColor) }
        .onChange(of: accentColorName) { _, _ in applyNavigationBarAccent(accentColor) }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [WeightEntry.self, Food.self, Meal.self, MealItem.self, Goal.self,
                              SavedMeal.self, SavedMealItem.self],
                        inMemory: true)
}
