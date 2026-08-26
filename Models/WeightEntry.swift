import Foundation
import SwiftData

@Model
final class WeightEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var weight: Double // kilograms

    init(id: UUID = UUID(), date: Date = .now, weight: Double) {
        self.id = id
        self.date = date
        self.weight = weight
    }
}
