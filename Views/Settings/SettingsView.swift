import SwiftUI
import SwiftData
import UIKit

/// Settings tab. The account is stored locally for now.
struct SettingsView: View {
    @Environment(\.appAccentColor) private var accent
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var context
    @State private var notificationsDenied = false
    @State private var showingResetAlert = false
    @State private var healthMessage = ""
    @State private var showingHealthMessage = false
    @AppStorage("displayName") private var displayName: String = ""
    @AppStorage("appearance") private var appearance: String = AppAppearance.system.rawValue
    @AppStorage("accentColorName") private var accentColorName: String = AppAccent.blue.rawValue
    @AppStorage("weightUnit") private var weightUnit: String = "lb"
    @AppStorage("remindersEnabled") private var remindersEnabled = false
    @AppStorage("showBMI") private var showBMI = true
    @AppStorage("healthSyncEnabled") private var healthSyncEnabled = false

    // Counts shown in the Data section.
    @Query private var weighIns: [WeightEntry]
    @Query private var meals: [Meal]
    @Query private var foods: [Food]
    @Query private var savedMeals: [SavedMeal]
    @Query private var goals: [Goal]
    @Query private var profiles: [UserProfile]

    private var feedbackURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "feedback@dietbuddy.app"
        components.queryItems = [URLQueryItem(name: "subject", value: "DietBuddy Feedback")]
        return components.url
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    TextField("Your name", text: $displayName)
                }

                NavigationLink {
                    ProfileEditorView()
                } label: {
                    Label("Profile & Body", systemImage: "person.text.rectangle")
                }
            } header: {
                Text("Account")
            } footer: {
                Text("Your account is stored locally on this device.")
            }

            Section("Meals") {
                NavigationLink {
                    SavedMealsManagerView()
                } label: {
                    Label("Saved Meals", systemImage: "bookmark")
                }
            }

            Section {
                Toggle("Show BMI", isOn: $showBMI)
            } header: {
                Text("Health")
            } footer: {
                Text("BMI is a rough screening metric based only on height and weight, so it can misclassify muscular builds. Turn it off to hide it on the Weight tab.")
            }

            if HealthKitService.shared.isAvailable {
                Section {
                    Toggle("Sync with Apple Health", isOn: $healthSyncEnabled)
                        .onChange(of: healthSyncEnabled) { _, enabled in
                            if enabled {
                                Task { await HealthKitService.shared.requestAuthorization() }
                            }
                        }
                    Button("Import Profile from Health") { importProfileFromHealth() }
                    Button("Import Weight from Health") { importWeightFromHealth() }
                } header: {
                    Text("Apple Health")
                } footer: {
                    Text("When on, new weigh-ins and logged meals are saved to Apple Health. Importing pulls your profile and past weigh-ins in.")
                }
            }

            Section("Appearance") {
                // Only the right side is a Menu so the row label stays primary (white),
                // instead of the whole row being a tinted button.
                HStack {
                    Text("Theme")
                    Spacer()
                    Menu {
                        Picker("Theme", selection: $appearance) {
                            ForEach(AppAppearance.allCases) { option in
                                Text(option.displayName).tag(option.rawValue)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(AppAppearance(rawValue: appearance)?.displayName ?? "System")
                            Image(systemName: "chevron.up.chevron.down").font(.caption2)
                        }
                    }
                }

                HStack {
                    Text("Accent Color")
                    Spacer()
                    Menu {
                        Picker("Accent Color", selection: $accentColorName) {
                            ForEach(AppAccent.allCases) { option in
                                Label {
                                    Text(option.displayName)
                                } icon: {
                                    // A rendered swatch with .original rendering mode keeps its
                                    // color in the menu; a template symbol would be tinted blue.
                                    swatchImage(option.color)
                                }
                                .tag(option.rawValue)
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Circle().fill(accent).frame(width: 22, height: 22)
                            Image(systemName: "chevron.up.chevron.down").font(.caption2)
                        }
                    }
                }
            }

            Section("Units") {
                HStack {
                    Text("Weight Unit")
                    Spacer()
                    Menu {
                        Picker("Weight Unit", selection: $weightUnit) {
                            Text("Pounds (lb)").tag("lb")
                            Text("Kilograms (kg)").tag("kg")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(weightUnit == "kg" ? "Kilograms (kg)" : "Pounds (lb)")
                            Image(systemName: "chevron.up.chevron.down").font(.caption2)
                        }
                    }
                }
            }

            Section {
                Toggle("Check-in reminders", isOn: $remindersEnabled)
                if remindersEnabled && notificationsDenied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
            } header: {
                Text("Reminders")
            } footer: {
                if remindersEnabled && notificationsDenied {
                    Text("Notifications are turned off for DietBuddy. Turn them on in Settings to receive check-in reminders.")
                        .foregroundStyle(.red)
                } else {
                    Text("If you haven't opened DietBuddy in a few days, we'll send a gentle reminder to log your weight or a meal.")
                }
            }
            .onChange(of: remindersEnabled) { _, enabled in
                Task {
                    await ReminderScheduler.setEnabled(enabled)
                    await refreshNotificationStatus()
                }
            }

            Section {
                LabeledContent("Weigh-ins", value: "\(weighIns.count)")
                LabeledContent("Meals", value: "\(meals.count)")
                LabeledContent("Foods", value: "\(foods.count)")
                LabeledContent("Saved Meals", value: "\(savedMeals.count)")
                LabeledContent("Goals", value: "\(goals.count)")

                Button("Reset All Data", role: .destructive) {
                    showingResetAlert = true
                }
            } header: {
                Text("Data")
            } footer: {
                Text("Everything you log is stored on this device.")
            }

            Section("Support") {
                if let feedbackURL {
                    Link(destination: feedbackURL) {
                        Label("Send Feedback", systemImage: "envelope")
                    }
                }
            }

            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .task { await refreshNotificationStatus() }
        .alert("Reset All Data?", isPresented: $showingResetAlert) {
            Button("Delete Everything", role: .destructive) { resetAllData() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently deletes all logged foods, meals, weigh-ins, saved meals, goals, and your profile. This can't be undone.")
        }
        .alert("Apple Health", isPresented: $showingHealthMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(healthMessage)
        }
    }

    private func refreshNotificationStatus() async {
        notificationsDenied = await ReminderScheduler.authorizationStatus() == .denied
    }

    /// Reads date of birth, biological sex, and height from Health into the profile.
    private func importProfileFromHealth() {
        Task {
            await HealthKitService.shared.requestAuthorization()
            let data = await HealthKitService.shared.readProfile()

            let profile = profiles.first ?? {
                let created = UserProfile()
                context.insert(created)
                return created
            }()

            var imported: [String] = []
            if let birthday = data.birthday { profile.birthday = birthday; imported.append("birthday") }
            if let gender = data.gender { profile.gender = gender; imported.append("sex") }
            if let heightCM = data.heightCM, heightCM > 0 { profile.heightCM = heightCM; imported.append("height") }

            healthMessage = imported.isEmpty
                ? "No profile data was available in Apple Health."
                : "Imported \(imported.joined(separator: ", ")) from Apple Health."
            showingHealthMessage = true
        }
    }

    /// Imports body-mass samples from Health as weigh-ins, skipping ones already logged.
    private func importWeightFromHealth() {
        Task {
            await HealthKitService.shared.requestAuthorization()
            let samples = await HealthKitService.shared.readWeights(weightUnit: weightUnit)
            let existing = Set(weighIns.map { $0.date.timeIntervalSince1970.rounded() })

            var added = 0
            for sample in samples where !existing.contains(sample.date.timeIntervalSince1970.rounded()) {
                context.insert(WeightEntry(date: sample.date, weight: sample.weight))
                added += 1
            }

            healthMessage = added == 0
                ? "No new weigh-ins to import from Apple Health."
                : "Imported \(added) weigh-in\(added == 1 ? "" : "s") from Apple Health."
            showingHealthMessage = true
        }
    }

    /// Permanently deletes every stored record. Preferences (theme, units, etc.) are kept.
    private func resetAllData() {
        try? context.delete(model: MealItem.self)
        try? context.delete(model: Meal.self)
        try? context.delete(model: SavedMealItem.self)
        try? context.delete(model: SavedMeal.self)
        try? context.delete(model: WeightEntry.self)
        try? context.delete(model: Food.self)
        try? context.delete(model: Goal.self)
        try? context.delete(model: UserProfile.self)
        try? context.save()
        displayName = ""
    }

    /// Renders a filled circle to an image so menu items show their real color
    /// (SF Symbols in a Picker menu are template-tinted and would all appear blue).
    @MainActor
    private func swatchImage(_ color: Color) -> Image {
        let renderer = ImageRenderer(content: Circle().fill(color).frame(width: 18, height: 18))
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage).renderingMode(.original)
        }
        return Image(systemName: "circle.fill")
    }

}
