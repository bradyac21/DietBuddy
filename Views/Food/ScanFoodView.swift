import SwiftUI

/// Barcode-scanning path: scan (or type) a barcode, look it up, then confirm the details.
struct ScanFoodView: View {
    let onCommit: (Food, Double) -> Void

    @State private var draft: FoodDraft?
    @State private var mode: FoodEntryMode = .scanned
    @State private var isLooking = false
    @State private var lookupMessage: String?
    @State private var manualBarcode = ""

    var body: some View {
        Group {
            if let draft {
                FoodEntryForm(title: mode == .scanned ? "Confirm Food" : "Manual Entry",
                              mode: mode,
                              draft: draft,
                              note: lookupMessage,
                              onCommit: onCommit)
            } else if isLooking {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Looking up product…").foregroundStyle(.secondary)
                }
                .navigationTitle("Scan Barcode")
                .navigationBarTitleDisplayMode(.inline)
            } else if BarcodeScannerView.isAvailable {
                BarcodeScannerView { code in
                    lookUp(code)
                }
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .bottom) {
                    Text("Point the camera at a product barcode")
                        .font(.subheadline)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 24)
                }
                .navigationTitle("Scan Barcode")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ManualBarcodeEntryView(barcode: $manualBarcode, onLookUp: lookUp)
            }
        }
    }

    private func lookUp(_ code: String) {
        isLooking = true
        lookupMessage = nil
        Task {
            do {
                let result = try await OpenFoodFactsService().lookup(barcode: code)
                mode = .scanned
                draft = FoodDraft(from: result)
            } catch {
                // Not found / failed: drop into an editable manual form so the user can still add it.
                mode = .manual
                lookupMessage = (error as? FoodLookupError)?.errorDescription ?? "Lookup failed. Enter details manually below."
                draft = FoodDraft()
            }
            isLooking = false
        }
    }
}
