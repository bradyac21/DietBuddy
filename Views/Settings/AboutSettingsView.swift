import SwiftUI

/// Support links and app version.
struct AboutSettingsView: View {
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
            } footer: {
                Text("Your account and data are stored locally on this device.")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
