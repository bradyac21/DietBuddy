import Foundation
import SwiftData

/// The single local user profile. Everything is optional — the user can skip any of it.
/// Birthday drives an auto-updating age; height feeds the BMI shown on the Weight tab.
@Model
final class UserProfile {
    var birthday: Date?
    var genderRaw: String?
    /// Height in centimeters (canonical). 0 means "not set".
    var heightCM: Double

    init(birthday: Date? = nil, gender: Gender? = nil, heightCM: Double = 0) {
        self.birthday = birthday
        self.genderRaw = gender?.rawValue
        self.heightCM = heightCM
    }

    var gender: Gender? {
        get { genderRaw.flatMap(Gender.init(rawValue:)) }
        set { genderRaw = newValue?.rawValue }
    }

    /// Whole years since `birthday`, or nil if no birthday is set.
    var age: Int? {
        guard let birthday else { return nil }
        return Calendar.current.dateComponents([.year], from: birthday, to: .now).year
    }

    var hasHeight: Bool { heightCM > 0 }
}
