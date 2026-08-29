import SwiftUI

/// A horizontal shake, driven by an integer trigger you increment inside `withAnimation`.
struct ShakeEffect: GeometryEffect {
    var travelDistance: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let dx = travelDistance * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: dx, y: 0))
    }
}

extension View {
    /// Shakes whenever `trigger` changes. Increment `trigger` inside `withAnimation`
    /// to signal an out-of-bounds action (e.g. navigating past the available range).
    func shake(_ trigger: Int) -> some View {
        modifier(ShakeEffect(animatableData: CGFloat(trigger)))
    }
}
