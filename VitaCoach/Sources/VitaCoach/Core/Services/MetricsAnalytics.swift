import Foundation

struct MetricPoint: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct MetricSummary: Identifiable, Hashable {
    var id: String { type.rawValue }
    let type: MetricType
    let latest: Double
    let average7d: Double
    let trend: Double          // относительное изменение vs предыдущая неделя
    let series: [MetricPoint]

    var targetProgress: Double? {
        guard let target = type.dailyTarget, target > 0 else { return nil }
        return min(latest / target, 1.5)
    }
}

/// Аналитика метрик из массива измерений (поставляется SwiftData `@Query`).
enum MetricsAnalytics {
    static func summary(for type: MetricType, from samples: [MetricSample]) -> MetricSummary {
        let calendar = Calendar.current
        let typed = samples.filter { $0.type == type }.sorted { $0.date < $1.date }

        let daily = dailyAggregated(typed, type: type)
        let series = daily.map { MetricPoint(date: $0.key, value: $0.value) }
            .sorted { $0.date < $1.date }

        let latest = series.last?.value ?? 0
        let now = Date.now

        let last7 = series.filter { calendar.dateComponents([.day], from: $0.date, to: now).day ?? 99 < 7 }
        let prev7 = series.filter {
            let d = calendar.dateComponents([.day], from: $0.date, to: now).day ?? 99
            return d >= 7 && d < 14
        }
        let avg7 = average(last7.map(\.value))
        let avgPrev = average(prev7.map(\.value))
        let trend = avgPrev > 0 ? (avg7 - avgPrev) / avgPrev : 0

        return MetricSummary(type: type, latest: latest, average7d: avg7, trend: trend, series: series)
    }

    private static func dailyAggregated(_ samples: [MetricSample], type: MetricType) -> [Date: Double] {
        let calendar = Calendar.current
        var byDay: [Date: [Double]] = [:]
        for s in samples {
            let day = calendar.startOfDay(for: s.date)
            byDay[day, default: []].append(s.value)
        }
        // Кумулятивные метрики суммируем, остальные усредняем.
        let cumulative: Set<MetricType> = [.steps, .activeEnergy, .waterIntake]
        return byDay.mapValues { values in
            cumulative.contains(type) ? values.reduce(0, +) : average(values)
        }
    }

    private static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}
