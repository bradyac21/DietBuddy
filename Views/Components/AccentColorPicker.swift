import SwiftUI

/// A grid of tappable color swatches for choosing the accent color.
struct AccentColorPicker: View {
    @Binding var selection: String

    private let columns = [GridItem(.adaptive(minimum: 44), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(AppAccent.allCases) { accent in
                let isSelected = accent.rawValue == selection
                Button {
                    selection = accent.rawValue
                } label: {
                    Circle()
                        .fill(accent.color)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Circle()
                                .strokeBorder(.primary, lineWidth: isSelected ? 2 : 0)
                                .padding(-3)
                        }
                        .overlay {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accent.displayName)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
