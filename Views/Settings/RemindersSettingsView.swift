import SwiftUI
import UIKit

/// Check-in reminder preferences.
struct RemindersSettingsView: View {
    @Environment(\.openURL) private var openURL
    @AppStorage("remindersEnabled") private var remindersEnabled = false
    @State private var notificationsDenied = false

    var body: some View {
        List {
            Section {
                Toggle("Check-in reminders", isOn: $remindersEnabled)
                if remindersEnabled && notificationsDenied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
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
        }
        .navigationTitle("Reminders")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refreshNotificationStatus() }
    }

    private func refreshNotificationStatus() async {
        notificationsDenied = await ReminderScheduler.authorizationStatus() == .denied
    }
}
