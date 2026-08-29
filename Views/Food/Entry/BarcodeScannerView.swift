import SwiftUI
import VisionKit

/// A live camera barcode scanner. Calls `onScan` once with the first recognized barcode payload.
struct BarcodeScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void

    /// Whether the current device can run the data scanner (false on Simulator / devices without a Neural Engine).
    static var isAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        try? uiViewController.startScanning()
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onScan: (String) -> Void
        private var hasScanned = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            handle(addedItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            handle([item])
        }

        private func handle(_ items: [RecognizedItem]) {
            guard !hasScanned else { return }
            for case let .barcode(barcode) in items {
                if let payload = barcode.payloadStringValue, !payload.isEmpty {
                    hasScanned = true
                    onScan(payload)
                    return
                }
            }
        }
    }
}
