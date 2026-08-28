import Foundation

/// A user's gender (optional profile info).
enum Gender: String, CaseIterable, Identifiable, Codable {
    case female
    case male

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .female: "Female"
        case .male: "Male"
        }
    }
}
