import SwiftUI

/// Body Mass Index from a weight (in the user's unit) and a height in centimeters.
enum BMICalculator {
    /// Returns BMI, or nil when weight/height aren't available.
    static func bmi(weight: Double, weightUnit: String, heightCM: Double) -> Double? {
        guard weight > 0, heightCM > 0 else { return nil }
        if weightUnit == "kg" {
            let meters = heightCM / 100
            return weight / (meters * meters)
        } else {
            let inches = heightCM / 2.54
            return 703 * weight / (inches * inches)
        }
    }

    static func category(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5: "Underweight"
        case 18.5..<25: "Normal"
        case 25..<30: "Overweight"
        default: "Obese"
        }
    }

    /// The color used for each BMI category, shared by the value label and the info popover.
    static func categoryColor(_ bmi: Double) -> Color {
        switch bmi {
        case ..<18.5: .blue
        case 18.5..<25: .green
        case 25..<30: .orange
        default: .red
        }
    }
}
