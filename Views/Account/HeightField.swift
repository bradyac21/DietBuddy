import SwiftUI

/// Height input that adapts to the user's unit: centimeters (metric) or feet + inches (imperial).
/// Reads/writes the canonical `heightCM`.
struct HeightField: View {
    @Binding var heightCM: Double
    let isMetric: Bool

    @State private var cm: String
    @State private var feet: String
    @State private var inch: String

    init(heightCM: Binding<Double>, isMetric: Bool) {
        _heightCM = heightCM
        self.isMetric = isMetric
        let value = heightCM.wrappedValue
        if value > 0 {
            cm = String(Int(value.rounded()))
            let totalInches = value / 2.54
            feet = String(Int(totalInches / 12))
            inch = String(Int(totalInches.truncatingRemainder(dividingBy: 12).rounded()))
        } else {
            cm = ""
            feet = ""
            inch = ""
        }
    }

    var body: some View {
        if isMetric {
            LabeledContent("Height") {
                HStack(spacing: 4) {
                    TextField("0", text: $cm)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 64)
                    Text("cm").foregroundStyle(.secondary)
                }
            }
            .onChange(of: cm) { _, value in
                heightCM = Double(value) ?? 0
            }
        } else {
            LabeledContent("Height") {
                HStack(spacing: 4) {
                    TextField("0", text: $feet)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 36)
                    Text("ft").foregroundStyle(.secondary)
                    TextField("0", text: $inch)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 36)
                    Text("in").foregroundStyle(.secondary)
                }
            }
            .onChange(of: feet) { _, _ in commitImperial() }
            .onChange(of: inch) { _, _ in commitImperial() }
        }
    }

    private func commitImperial() {
        let f = Double(feet) ?? 0
        let i = Double(inch) ?? 0
        heightCM = (f * 12 + i) * 2.54
    }
}
