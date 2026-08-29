import SwiftUI

/// A read-only labeled value row showing a formatted number with a unit (or "—" when absent).
struct MacroValueRow: View {
    let label: String
    let value: Double?
    var unit: String

    var body: some View {
        LabeledContent(label, value: value.map {
            "\($0.formatted(.number.precision(.fractionLength(0...1)))) \(unit)"
        } ?? "—")
    }
}
