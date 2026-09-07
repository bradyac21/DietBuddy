import SwiftUI
import SwiftData

/// BMI display preference and Apple Health sync/import.
struct HealthSettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("showBMI") private var showBMI = true
    @AppStorage("healthSyncEnabled") private var healthSyncEnabled = false

    @Query private var profiles: [UserProfile]
    @Query private var weighIns: [WeightEntry]

    @State private var healthMessage = ""
    @State private var showingHealthMessage = false

    var body: some View {
        List {
            Section {
                Toggle("Show BMI", isOn: $showBMI)
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
        }
        .navigationTitle("Health")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Apple Health", isPresented: $showingHealthMessage) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(healthMessage)
        }
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
            let samples = await HealthKitService.shared.readWeights(weightUnit: UserDefaults.standard.string(forKey: "weightUnit") ?? "lb")
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
}
