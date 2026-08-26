import SwiftUI

/// Accent color options shared between the settings screen and the app's tint.
enum AppAccent: String, CaseIterable, Identifiable {
    case blue, red, orange, green, mint, teal, indigo, purple, pink

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .red: return .red
        case .orange: return .orange
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        }
    }

    var displayName: String { rawValue.capitalized }
}

/// Appearance options shared between the settings screen and the app's color scheme.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var displayName: String { rawValue.capitalized }
}

// MARK: - Accent color propagation

private struct AppAccentColorKey: EnvironmentKey {
    static let defaultValue: Color = .blue
}

extension EnvironmentValues {
    /// The user's chosen accent color, injected at the app root so any view can tint content with it.
    var appAccentColor: Color {
        get { self[AppAccentColorKey.self] }
        set { self[AppAccentColorKey.self] = newValue }
    }
}
