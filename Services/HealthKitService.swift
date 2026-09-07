import Foundation
import HealthKit

/// Thin wrapper over HealthKit for reading profile/weight and writing weigh-ins and nutrition.
/// All work is no-ops when Health data isn't available (e.g. iPad without Health, or the
/// capability/entitlement isn't configured), so callers can invoke it unconditionally.
@MainActor
final class HealthKitService {
    static let shared = HealthKitService()

    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Types

    private var quantity: (HKQuantityTypeIdentifier) -> HKQuantityType? { HKQuantityType.quantityType(forIdentifier:) }

    private var shareTypes: Set<HKSampleType> {
        let ids: [HKQuantityTypeIdentifier] = [.bodyMass, .dietaryEnergyConsumed, .dietaryProtein,
                                               .dietaryCarbohydrates, .dietaryFatTotal, .dietaryWater]
        return Set(ids.compactMap { HKQuantityType.quantityType(forIdentifier: $0) as HKSampleType? })
    }

    private var readTypes: Set<HKObjectType> {
        var types: [HKObjectType] = [HKQuantityTypeIdentifier.bodyMass, .height, .stepCount]
            .compactMap { HKQuantityType.quantityType(forIdentifier: $0) }
        if let dob = HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth) { types.append(dob) }
        if let sex = HKCharacteristicType.characteristicType(forIdentifier: .biologicalSex) { types.append(sex) }
        return Set(types)
    }

    /// Requests read/write access. Returns false only when Health is unavailable or the
    /// request throws; HealthKit intentionally doesn't reveal the user's per-type choices.
    @discardableResult
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Writing

    private func hkWeightUnit(_ weightUnit: String) -> HKUnit { weightUnit == "kg" ? .gramUnit(with: .kilo) : .pound() }

    /// Saves a body-mass sample in the user's unit.
    func saveWeight(_ weight: Double, weightUnit: String, date: Date) async {
        guard isAvailable, weight > 0, let type = quantity(.bodyMass) else { return }
        let sample = HKQuantitySample(type: type,
                                      quantity: HKQuantity(unit: hkWeightUnit(weightUnit), doubleValue: weight),
                                      start: date, end: date)
        try? await store.save(sample)
    }

    /// Saves nutrition samples for a single logged item. `waterMilliliters` is written only
    /// for drinks.
    func saveNutrition(calories: Double, protein: Double, carbs: Double, fat: Double,
                       waterMilliliters: Double?, date: Date) async {
        guard isAvailable else { return }
        var samples: [HKSample] = []
        func add(_ id: HKQuantityTypeIdentifier, _ unit: HKUnit, _ value: Double) {
            guard value > 0, let type = quantity(id) else { return }
            samples.append(HKQuantitySample(type: type,
                                            quantity: HKQuantity(unit: unit, doubleValue: value),
                                            start: date, end: date))
        }
        add(.dietaryEnergyConsumed, .kilocalorie(), calories)
        add(.dietaryProtein, .gram(), protein)
        add(.dietaryCarbohydrates, .gram(), carbs)
        add(.dietaryFatTotal, .gram(), fat)
        if let waterMilliliters { add(.dietaryWater, .literUnit(with: .milli), waterMilliliters) }

        guard !samples.isEmpty else { return }
        try? await store.save(samples)
    }

    // MARK: - Reading

    struct ImportedProfile {
        var birthday: Date?
        var gender: Gender?
        var heightCM: Double?
    }

    /// Reads date of birth, biological sex, and most recent height from Health.
    func readProfile() async -> ImportedProfile {
        guard isAvailable else { return ImportedProfile() }
        var result = ImportedProfile()

        if let components = try? store.dateOfBirthComponents() {
            result.birthday = components.date
        }
        if let sex = try? store.biologicalSex().biologicalSex {
            switch sex {
            case .male: result.gender = .male
            case .female: result.gender = .female
            default: break
            }
        }
        if let type = quantity(.height), let sample = await mostRecentSample(of: type) {
            result.heightCM = sample.quantity.doubleValue(for: .meterUnit(with: .centi))
        }

        #if DEBUG
        // Simulators have no Health profile data; fall back to sample values so importing
        // demonstrably populates fields.
        if result.birthday == nil {
            result.birthday = Calendar.current.date(from: DateComponents(year: 1995, month: 6, day: 15))
        }
        if result.gender == nil { result.gender = .male }
        if (result.heightCM ?? 0) == 0 { result.heightCM = 178 }
        #endif

        return result
    }

    /// Total step count recorded since midnight today, or nil if unavailable.
    func todaySteps() async -> Int? {
        let steps = await queryTodaySteps()
        #if DEBUG
        // Simulators have no step data, so fall back to a sample value to exercise the UI.
        if (steps ?? 0) == 0 { return 6_842 }
        #endif
        return steps
    }

    private func queryTodaySteps() async -> Int? {
        guard isAvailable, let type = quantity(.stepCount) else { return nil }
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, stats, _ in
                let steps = stats?.sumQuantity()?.doubleValue(for: .count())
                continuation.resume(returning: steps.map { Int($0) })
            }
            store.execute(query)
        }
    }

    /// Returns all body-mass samples as (date, weight in the user's unit), newest first.
    func readWeights(weightUnit: String) async -> [(date: Date, weight: Double)] {
        guard isAvailable, let type = quantity(.bodyMass) else { return [] }
        let unit = hkWeightUnit(weightUnit)
        return await samples(of: type, limit: HKObjectQueryNoLimit)
            .map { (date: $0.startDate, weight: $0.quantity.doubleValue(for: unit)) }
    }

    // MARK: - Query helpers

    private func mostRecentSample(of type: HKQuantityType) async -> HKQuantitySample? {
        await samples(of: type, limit: 1).first
    }

    private func samples(of type: HKQuantityType, limit: Int) async -> [HKQuantitySample] {
        await withCheckedContinuation { continuation in
            let sort = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: limit, sortDescriptors: sort) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKQuantitySample]) ?? [])
            }
            store.execute(query)
        }
    }
}
