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
    private enum Tab: Hashable { case weight, food, account }
    @State private var selection: Tab = .food

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { WeightView() }
                .tabItem { Label("Weight", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tab.weight)

            NavigationStack { MealMainView() }
                .tabItem { Label("Food", systemImage: "fork.knife") }
                .tag(Tab.food)

            NavigationStack { AccountSettingsView() }
                .tabItem { Label("Account", systemImage: "person.crop.circle") }
                .tag(Tab.account)
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
