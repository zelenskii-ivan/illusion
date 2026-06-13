import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

/// Обёртка над HealthKit: запрос доступа и импорт суточных метрик.
/// Безопасно деградирует на платформах/симуляторах без HealthKit.
@MainActor
final class HealthKitService {
    #if canImport(HealthKit)
    // Ленивая инициализация: HKHealthStore не создаётся на старте приложения.
    // Иначе на реальном устройстве без HealthKit-entitlement обращение к
    // HealthKit при запуске роняет приложение (в симуляторе entitlements не
    // проверяются, поэтому там всё работало).
    private lazy var store = HKHealthStore()
    #endif

    var isAvailable: Bool {
        #if canImport(HealthKit)
        return HKHealthStore.isHealthDataAvailable()
        #else
        return false
        #endif
    }

    func requestAuthorization() async -> Bool {
        #if canImport(HealthKit)
        guard isAvailable else { return false }
        var readTypes: Set<HKObjectType> = []
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { readTypes.insert(steps) }
        if let energy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { readTypes.insert(energy) }
        if let rhr = HKObjectType.quantityType(forIdentifier: .restingHeartRate) { readTypes.insert(rhr) }
        if let hr = HKObjectType.quantityType(forIdentifier: .heartRate) { readTypes.insert(hr) }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { readTypes.insert(sleep) }
        if let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) { readTypes.insert(weight) }

        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            return true
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    /// Импортирует суммарные суточные значения за последние `days` дней.
    func importDailyMetrics(days: Int = 7) async -> [MetricSample] {
        #if canImport(HealthKit)
        guard isAvailable else { return [] }
        var samples: [MetricSample] = []
        samples += await sumQuantity(.stepCount, unit: .count(), as: .steps, days: days)
        samples += await sumQuantity(.activeEnergyBurned, unit: .kilocalorie(), as: .activeEnergy, days: days)
        samples += await averageQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()), as: .restingHeartRate, days: days)
        return samples
        #else
        return []
        #endif
    }

    #if canImport(HealthKit)
    private func sumQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit, as type: MetricType, days: Int) async -> [MetricSample] {
        await collect(id: id, unit: unit, type: type, days: days, options: .cumulativeSum)
    }

    private func averageQuantity(_ id: HKQuantityTypeIdentifier, unit: HKUnit, as type: MetricType, days: Int) async -> [MetricSample] {
        await collect(id: id, unit: unit, type: type, days: days, options: .discreteAverage)
    }

    private func collect(id: HKQuantityTypeIdentifier, unit: HKUnit, type: MetricType, days: Int, options: HKStatisticsOptions) async -> [MetricSample] {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: id) else { return [] }
        let calendar = Calendar.current
        let anchor = calendar.startOfDay(for: .now)
        guard let start = calendar.date(byAdding: .day, value: -days, to: anchor) else { return [] }
        var interval = DateComponents(); interval.day = 1

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: nil,
                options: options,
                anchorDate: anchor,
                intervalComponents: interval
            )
            query.initialResultsHandler = { _, results, _ in
                var collected: [MetricSample] = []
                results?.enumerateStatistics(from: start, to: anchor) { stat, _ in
                    let quantity = options == .cumulativeSum ? stat.sumQuantity() : stat.averageQuantity()
                    if let value = quantity?.doubleValue(for: unit), value > 0 {
                        collected.append(MetricSample(type: type, value: value, date: stat.startDate, source: .healthKit))
                    }
                }
                continuation.resume(returning: collected)
            }
            store.execute(query)
        }
    }
    #endif
}
