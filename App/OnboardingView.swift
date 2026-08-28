import SwiftUI
import SwiftData

/// First-run intro in three phases: Welcome → About You (optional) → Features.
/// Uses a NavigationStack so Back is the native navigation-bar button, and tints
/// the whole flow with the chosen accent color so the preview updates live.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @AppStorage("displayName") private var displayName: String = ""
    @AppStorage("weightUnit") private var weightUnit: String = "lb"
    @AppStorage("accentColorName") private var accentColorName: String = AppAccent.blue.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private enum Phase: Hashable { case about, features }
    @State private var path: [Phase] = []

    @State private var name: String = ""
    @State private var birthday: Date = Calendar.current.date(byAdding: .year, value: -25, to: .now) ?? .now
    @State private var gender: Gender = .male
    @State private var heightCM: Double = 0

    private var accentColor: Color { AppAccent(rawValue: accentColorName)?.color ?? .blue }

    var body: some View {
        NavigationStack(path: $path) {
            WelcomePhase(onContinue: { path.append(.about) })
                .navigationTitle("Welcome")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: Phase.self) { phase in
                    switch phase {
                    case .about:
                        AboutYouPhase(name: $name,
                                      birthday: $birthday,
                                      gender: $gender,
                                      heightCM: $heightCM,
                                      accentColorName: $accentColorName,
                                      isMetric: weightUnit == "kg",
                                      onContinue: { saveInfo(); path.append(.features) },
                                      onSkip: { path.append(.features) })
                            .navigationTitle("About You")
                            .navigationBarTitleDisplayMode(.inline)
                    case .features:
                        FeaturesPhase(onFinish: { hasCompletedOnboarding = true })
                            .navigationTitle("What You Can Do")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
        }
        .tint(accentColor)
    }

    private func saveInfo() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { displayName = trimmed }

        let profile = profiles.first ?? {
            let created = UserProfile()
            context.insert(created)
            return created
        }()
        profile.birthday = birthday
        profile.gender = gender
        if heightCM > 0 { profile.heightCM = heightCM }
    }
}

// MARK: - Phases

private struct WelcomePhase: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.tint)
                Text("Welcome to DietBuddy").font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("Track your food, weight, and goals — simply.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()

            ContinueButton(title: "Continue", action: onContinue)
                .padding(.bottom)
        }
    }
}

private struct AboutYouPhase: View {
    @Binding var name: String
    @Binding var birthday: Date
    @Binding var gender: Gender
    @Binding var heightCM: Double
    @Binding var accentColorName: String
    let isMetric: Bool
    let onContinue: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField("Name", text: $name)

                    DatePicker("Birthday", selection: $birthday, in: ...Date.now, displayedComponents: .date)

                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases) { Text($0.displayName).tag($0) }
                    }

                    HeightField(heightCM: $heightCM, isMetric: isMetric)
                } header: {
                    Text("A little about you")
                } footer: {
                    Text("Used to personalize your profile and BMI. You can change this anytime in Account.")
                }

                Section {
                    AccentColorPicker(selection: $accentColorName)
                        .padding(.vertical, 8)
                } header: {
                    Text("App Accent Color")
                } footer: {
                    Text("Sets the color used to tint buttons and highlights throughout the app.")
                }
            }

            VStack(spacing: 12) {
                ContinueButton(title: "Continue", action: onContinue)
                Button("Skip", action: onSkip)
            }
            .padding(.bottom)
        }
    }
}

private struct FeaturesPhase: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("What you can do") {
                    FeatureRow(icon: "fork.knife", title: "Log food fast",
                               subtitle: "Scan a barcode or enter it by hand.")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Track your weight",
                               subtitle: "See your trend and BMI over time.")
                    FeatureRow(icon: "target", title: "Hit your goals",
                               subtitle: "Calorie and macro rings for every day.")
                    FeatureRow(icon: "square.grid.2x2", title: "Home-screen widget",
                               subtitle: "Your daily macros at a glance.")
                }
            }

            ContinueButton(title: "Get Started", action: onFinish)
                .padding(.bottom)
        }
    }
}

// MARK: - Shared

/// The primary call-to-action shared across phases.
private struct ContinueButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .fontWeight(.semibold)
            .buttonStyle(.primaryAction)
            .padding(.top, 8)
    }
}

/// A single feature highlight row.
private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon).foregroundStyle(.tint)
        }
    }
}
