import SwiftUI
import UIKit

/// Settings tab. The account is stored locally for now.
struct SettingsView: View {
    @Environment(\.appAccentColor) private var accent
    @Environment(\.openURL) private var openURL
    @State private var notificationsDenied = false
    @AppStorage("displayName") private var displayName: String = ""
    @AppStorage("appearance") private var appearance: String = AppAppearance.system.rawValue
    @AppStorage("accentColorName") private var accentColorName: String = AppAccent.blue.rawValue
    @AppStorage("weightUnit") private var weightUnit: String = "lb"
    @AppStorage("remindersEnabled") private var remindersEnabled = false
    @AppStorage("showBMI") private var showBMI = true

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
    }

    private func refreshNotificationStatus() async {
        notificationsDenied = await ReminderScheduler.authorizationStatus() == .denied
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
