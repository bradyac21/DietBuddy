import Foundation

/// A row in a meal: either a standalone item or a collapsed saved-meal bundle.
enum MealEntry: Identifiable {
    case item(MealItem)
    case bundle(id: UUID, name: String, items: [MealItem])

    var id: String {
        switch self {
        case .item(let item): return "item-\(item.id.uuidString)"
        case .bundle(let id, _, _): return "bundle-\(id.uuidString)"
        }
    }
}

/// Groups a meal's items so items added together from a saved meal collapse into a single bundle,
/// preserving overall order (a bundle appears at its first item's position).
func mealEntries(_ items: [MealItem]) -> [MealEntry] {
    var result: [MealEntry] = []
    var seenBundles: Set<UUID> = []
    for item in items {
        if let bundleID = item.bundleID {
            guard !seenBundles.contains(bundleID) else { continue }
            seenBundles.insert(bundleID)
            let bundleItems = items.filter { $0.bundleID == bundleID }
            result.append(.bundle(id: bundleID, name: item.bundleName ?? "Saved Meal", items: bundleItems))
        } else {
            result.append(.item(item))
        }
    }
    return result
}
