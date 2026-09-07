import SwiftUI

/// Settings tab: a menu of categories, each pushing a dedicated screen.
struct SettingsView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    ProfileEditorView()
                } label: {
                    Label("Profile", systemImage: "person.crop.circle")
                }
            } footer: {
                Text("Your account and data are stored locally on this device.")
            }

            Section {
                NavigationLink {
                    AppearanceSettingsView()
                } label: {
                    Label("Appearance", systemImage: "paintbrush")
                }
                NavigationLink {
                    HealthSettingsView()
                } label: {
                    Label("Health", systemImage: "heart")
                }
                NavigationLink {
                    SavedMealsManagerView()
                } label: {
                    Label("Saved Meals", systemImage: "bookmark")
                }
                NavigationLink {
                    RemindersSettingsView()
                } label: {
                    Label("Reminders", systemImage: "bell")
                }
            }

            Section {
                NavigationLink {
                    DataSettingsView()
                } label: {
                    Label("Data", systemImage: "externaldrive")
                }
                NavigationLink {
                    AboutSettingsView()
                } label: {
                    Label("About", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Settings")
    }
}
