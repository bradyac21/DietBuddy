import SwiftUI

/// A `ContentUnavailableView` whose icon and title use the app accent color.
struct EmptyStateView: View {
    @Environment(\.appAccentColor) private var accent

    let title: String
    let systemImage: String
    var description: String? = nil

    var body: some View {
        ContentUnavailableView {
            Label {
                Text(title).foregroundStyle(accent)
            } icon: {
                Image(systemName: systemImage).foregroundStyle(accent)
            }
        } description: {
            if let description {
                Text(description)
            }
        }
    }
}
