import SwiftUI
import UIKit

/// Account & settings tab. The account is stored locally for now.
struct AccountSettingsView: View {
    @Environment(\.appAccentColor) private var accent
    @Environment(\.openURL) private var openURL
    @State private var notificationsDenied = false
    @AppStorage("displayName") private var displayName: String = ""
    @AppStorage("appearance") private var appearance: String = AppAppearance.system.rawValue
    @AppStorage("accentColorName") private var accentColorName: String = AppAccent.blue.rawValue
    @AppStorage("weightUnit") private var weightUnit: String = "lb"
    @AppStorage("remindersEnabled") private var remindersEnabled = false

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
            Section("Account") {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    TextField("Your name", text: $displayName)
                }
                Text("Your account is stored locally on this device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Meals") {
                NavigationLink {
                    SavedMealsManagerView()
                } label: {
                    Label("Saved Meals", systemImage: "bookmark")
                }
            }

            Section("Appearance") {
                Menu {
                    Picker("Theme", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                } label: {
                    settingRow("Theme", value: AppAppearance(rawValue: appearance)?.displayName ?? "System")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Accent Color")
                    AccentColorPicker(selection: $accentColorName)
                }
                .padding(.vertical, 4)
            }

            Section("Units") {
                Menu {
                    Picker("Weight Unit", selection: $weightUnit) {
                        Text("Pounds (lb)").tag("lb")
                        Text("Kilograms (kg)").tag("kg")
                    }
                } label: {
                    settingRow("Weight Unit", value: weightUnit == "kg" ? "Kilograms (kg)" : "Pounds (lb)")
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
        .navigationTitle("Account")
        .task { await refreshNotificationStatus() }
    }

    private func refreshNotificationStatus() async {
        notificationsDenied = await ReminderScheduler.authorizationStatus() == .denied
    }

    /// A settings row whose value and chevron use the accent color and update live with it.
    private func settingRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.primary)
            Spacer()
            Text(value).foregroundStyle(accent)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2)
                .foregroundStyle(accent)
        }
        .contentShape(Rectangle())
    }
}
