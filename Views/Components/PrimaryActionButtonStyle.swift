import SwiftUI

/// The pill button used for the primary action on each screen.
/// Reads `isEnabled` so the disabled state actually goes gray instead of
/// staying stuck on the tint color.
struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        // Match Apple's `.borderedProminent` pattern: keep tint + foreground,
        // fade the whole button when disabled. Both states stay high-contrast.
        // Uses `.tint` (not a fixed color) so it follows the app accent color.
        configuration.label
            .foregroundStyle(.white)
            .frame(width: 275, height: 44)
            .background(.tint, in: .rect(cornerRadius: 20))
            .opacity(isEnabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
    }
}

extension ButtonStyle where Self == PrimaryActionButtonStyle {
    static var primaryAction: Self { Self() }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        Button("Enabled") { }
            .buttonStyle(.primaryAction)

        Button("Disabled") { }
            .buttonStyle(.primaryAction)
            .disabled(true)
    }
    .padding()
}
#endif
