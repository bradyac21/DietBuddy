import SwiftUI
import SwiftData

/// Three-tab root: Weight tracking, Food tracking, and Settings.
struct RootTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("appearance") private var appearance: String = AppAppearance.system.rawValue
    @AppStorage("accentColorName") private var accentColorName: String = AppAccent.blue.rawValue
    @AppStorage("remindersEnabled") private var remindersEnabled = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private var preferredScheme: ColorScheme? {
        AppAppearance(rawValue: appearance)?.colorScheme
    }

    private var accentColor: Color {
        (AppAccent(rawValue: accentColorName) ?? .blue).color
    }

    /// Tabs, in display order. The app opens to Food.
    private enum AppTab: Hashable { case weight, food, settings }
    @State private var selection: AppTab = .food

    var body: some View {
        TabView(selection: $selection) {
            Tab("Weight", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.weight) {
                NavigationStack { WeightView() }
            }
            Tab("Food", systemImage: "fork.knife", value: AppTab.food) {
                NavigationStack { MealMainView() }
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack { SettingsView() }
            }
        }
        .tint(accentColor)
        .preferredColorScheme(preferredScheme)
        .environment(\.appAccentColor, accentColor)
        .onAppear { applyNavigationBarAccent(accentColor) }
        .onChange(of: accentColorName) { _, _ in applyNavigationBarAccent(accentColor) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await ReminderScheduler.appBecameActive(remindersEnabled: remindersEnabled) }
            }
        }
        .fullScreenCover(isPresented: Binding(get: { !hasCompletedOnboarding }, set: { _ in })) {
            OnboardingView()
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: [WeightEntry.self, Food.self, Meal.self, MealItem.self, Goal.self,
                              SavedMeal.self, SavedMealItem.self, UserProfile.self],
                        inMemory: true)
}
