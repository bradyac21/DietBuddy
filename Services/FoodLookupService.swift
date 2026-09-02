import Foundation

/// Nutrition facts for a scanned product, normalized to a per-100g basis.
struct FoodLookupResult {
    var name: String
    var brand: String?
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    /// True when Open Food Facts categorizes the product as a drink.
    var isBeverage: Bool
}

enum FoodLookupError: LocalizedError {
    case notFound
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "We couldn't find that product. Enter its details manually below."
        case .invalidResponse:
            return "Lookup failed. Check your connection or enter details manually below."
        }
    }
}

/// Looks up product nutrition facts by barcode using the free Open Food Facts database.
struct OpenFoodFactsService {
    func lookup(barcode: String) async throws -> FoodLookupResult {
        let trimmed = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(trimmed).json?fields=product_name,brands,nutriments,categories_tags") else {
            throw FoodLookupError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("DietBuddy - iOS - Version 1.0", forHTTPHeaderField: "User-Agent")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw FoodLookupError.invalidResponse
        }

        guard let http = response as? HTTPURLResponse else { throw FoodLookupError.invalidResponse }
        if http.statusCode == 404 { throw FoodLookupError.notFound }
        guard (200..<300).contains(http.statusCode) else { throw FoodLookupError.invalidResponse }

        guard let decoded = try? JSONDecoder().decode(OFFResponse.self, from: data) else {
            throw FoodLookupError.invalidResponse
        }
        guard decoded.status == 1, let product = decoded.product else {
            throw FoodLookupError.notFound
        }

        let name = (product.productName?.isEmpty == false) ? product.productName! : "Scanned Item"
        let categories = product.categoriesTags ?? []
        let isBeverage = categories.contains { $0.contains("beverage") || $0.contains("drink") }
        return FoodLookupResult(
            name: name,
            brand: product.brands?.isEmpty == false ? product.brands : nil,
            caloriesPer100g: product.nutriments?.energyKcal100g ?? 0,
            proteinPer100g: product.nutriments?.proteins100g ?? 0,
            carbsPer100g: product.nutriments?.carbohydrates100g ?? 0,
            fatPer100g: product.nutriments?.fat100g ?? 0,
            isBeverage: isBeverage
        )
    }
}

// MARK: - Open Food Facts response models

private struct OFFResponse: Decodable {
    let status: Int
    let product: OFFProduct?
}

private struct OFFProduct: Decodable {
    let productName: String?
    let brands: String?
    let nutriments: OFFNutriments?
    let categoriesTags: [String]?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case nutriments
        case categoriesTags = "categories_tags"
    }
}

/// Nutriment values are sometimes encoded as numbers and sometimes as strings, so decode leniently.
private struct OFFNutriments: Decodable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        energyKcal100g = Self.lenientDouble(container, .energyKcal100g)
        proteins100g = Self.lenientDouble(container, .proteins100g)
        carbohydrates100g = Self.lenientDouble(container, .carbohydrates100g)
        fat100g = Self.lenientDouble(container, .fat100g)
    }

    private static func lenientDouble(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Double? {
        if let value = try? container.decode(Double.self, forKey: key) { return value }
        if let string = try? container.decode(String.self, forKey: key) { return Double(string) }
        return nil
    }
}
