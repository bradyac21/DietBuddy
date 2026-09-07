import SwiftUI

/// Appearance and unit preferences.
struct AppearanceSettingsView: View {
    @Environment(\.appAccentColor) private var accent
    @AppStorage("appearance") private var appearance: String = AppAppearance.system.rawValue
    @AppStorage("accentColorName") private var accentColorName: String = AppAccent.blue.rawValue
    @AppStorage("weightUnit") private var weightUnit: String = "lb"

    var body: some View {
        List {
            Section("Appearance") {
                // Only the right side is a Menu so the row label stays primary (white).
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
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
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
