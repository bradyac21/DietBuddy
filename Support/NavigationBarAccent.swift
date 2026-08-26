import SwiftUI
import UIKit

/// Applies the accent color to system navigation bar titles (both large and inline).
///
/// This updates the global `UINavigationBar` appearance proxy (for bars created later) *and*
/// walks the live view-controller hierarchy so currently visible titles recolor immediately.
@MainActor
func applyNavigationBarAccent(_ color: Color) {
    let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor(color)]

    let proxy = UINavigationBar.appearance()
    proxy.largeTitleTextAttributes = attrs
    proxy.titleTextAttributes = attrs

    for scene in UIApplication.shared.connectedScenes {
        guard let windowScene = scene as? UIWindowScene else { continue }
        for window in windowScene.windows {
            recolorNavigationBars(from: window.rootViewController, attrs: attrs)
        }
    }
}

/// Recursively updates every live navigation bar's title colors so the change is immediate.
@MainActor
private func recolorNavigationBars(from viewController: UIViewController?, attrs: [NSAttributedString.Key: Any]) {
    guard let viewController else { return }

    if let nav = viewController as? UINavigationController {
        let bar = nav.navigationBar
        for appearance in [bar.standardAppearance, bar.compactAppearance, bar.scrollEdgeAppearance].compactMap({ $0 }) {
            appearance.largeTitleTextAttributes = attrs
            appearance.titleTextAttributes = attrs
        }
        bar.largeTitleTextAttributes = attrs
        bar.titleTextAttributes = attrs
        bar.setNeedsLayout()
    }

    for child in viewController.children {
        recolorNavigationBars(from: child, attrs: attrs)
    }
    recolorNavigationBars(from: viewController.presentedViewController, attrs: attrs)
}
