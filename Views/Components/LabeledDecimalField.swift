import SwiftUI

/// A form row with a label and a right-aligned decimal text field.
struct LabeledDecimalField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField(label, text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }
}
