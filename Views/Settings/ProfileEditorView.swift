import SwiftUI
import SwiftData

/// Edits the user's profile (all fields optional). Creates the single profile record if needed.
struct ProfileEditorView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first {
                ProfileForm(profile: profile)
            } else {
                ProgressView()
                    .onAppear { context.insert(UserProfile()) }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// The actual form, once a `UserProfile` exists to bind to.
private struct ProfileForm: View {
    @Bindable var profile: UserProfile
    @AppStorage("displayName") private var displayName: String = ""
    @AppStorage("weightUnit") private var weightUnit: String = "lb"

    private var defaultBirthday: Date {
        Calendar.current.date(byAdding: .year, value: -25, to: .now) ?? .now
    }

    private var hasBirthday: Binding<Bool> {
        Binding(
            get: { profile.birthday != nil },
            set: { profile.birthday = $0 ? (profile.birthday ?? defaultBirthday) : nil }
        )
    }

    private var birthdayValue: Binding<Date> {
        Binding(get: { profile.birthday ?? defaultBirthday }, set: { profile.birthday = $0 })
    }

    private var gender: Binding<Gender?> {
        Binding(get: { profile.gender }, set: { profile.gender = $0 })
    }

    var body: some View {
        Form {
            Section("You") {
                TextField("Name", text: $displayName)

                Toggle("Add birthday", isOn: hasBirthday)
                if profile.birthday != nil {
                    DatePicker("Birthday", selection: birthdayValue, in: ...Date.now, displayedComponents: .date)
                    if let age = profile.age {
                        LabeledContent("Age", value: "\(age)")
                    }
                }

                Picker("Gender", selection: gender) {
                    Text("Not set").tag(Gender?.none)
                    ForEach(Gender.allCases) { Text($0.displayName).tag(Optional($0)) }
                }
            }

            Section {
                HeightField(heightCM: $profile.heightCM, isMetric: weightUnit == "kg")
            } header: {
                Text("Body")
            } footer: {
                Text("Optional. Your height is used to show your BMI on the Weight tab.")
            }

            if HealthKitService.shared.isAvailable {
                Section {
                    Button("Import from Apple Health") { importFromHealth() }
                } footer: {
                    Text("Fills your birthday, sex, and height from Apple Health.")
                }
            }
        }
    }

    /// Reads birthday, biological sex, and height from Apple Health into the profile.
    private func importFromHealth() {
        Task {
            await HealthKitService.shared.requestAuthorization()
            let data = await HealthKitService.shared.readProfile()
            if let birthday = data.birthday { profile.birthday = birthday }
            if let gender = data.gender { profile.gender = gender }
            if let heightCM = data.heightCM, heightCM > 0 { profile.heightCM = heightCM }
        }
    }
}
