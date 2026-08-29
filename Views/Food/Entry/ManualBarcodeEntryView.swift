import SwiftUI

/// Fallback for devices without a usable camera: type a barcode number to look up.
struct ManualBarcodeEntryView: View {
    @Binding var barcode: String
    var onLookUp: (String) -> Void

    var body: some View {
        Form {
            Section {
                TextField("Barcode number", text: $barcode)
                    .keyboardType(.numberPad)
                Button("Look Up") { onLookUp(barcode) }
                    .disabled(barcode.trimmingCharacters(in: .whitespaces).isEmpty)
            } footer: {
                Text("Camera scanning isn't available on this device. Type the barcode digits to look it up, or add the food manually.")
            }
        }
        .navigationTitle("Enter Barcode")
        .navigationBarTitleDisplayMode(.inline)
    }
}
