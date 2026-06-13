import SwiftUI
import SwiftData
import Charts

struct MetricDetailView: View {
    let type: MetricType
    @Query private var samples: [MetricSample]

    private var summary: MetricSummary {
        MetricsAnalytics.summary(for: type, from: samples)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label(type.title, systemImage: type.systemImage)
                                .font(.headline).foregroundStyle(type.tint)
                            Spacer()
                            TrendBadge(trend: summary.trend, higherIsBetter: type.higherIsBetter)
                        }
                        Text(valueText(summary.latest))
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .contentTransition(.numericText())
                        if let target = type.dailyTarget {
                            Text("Цель: \(Int(target)) \(type.unit)")
                                .font(.subheadline).foregroundStyle(Theme.textSecondary)
                        }
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Динамика", subtitle: "Последние 14 дней", systemImage: "waveform.path.ecg")
                        Chart(summary.series.suffix(14)) { point in
                            AreaMark(x: .value("Дата", point.date), y: .value("Знач", point.value))
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(LinearGradient(colors: [type.tint.opacity(0.4), .clear],
                                                                startPoint: .top, endPoint: .bottom))
                            LineMark(x: .value("Дата", point.date), y: .value("Знач", point.value))
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(type.tint)
                            if let target = type.dailyTarget {
                                RuleMark(y: .value("Цель", target))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .frame(height: 220)
                        .chartReveal()
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader("Статистика", systemImage: "sum")
                        statRow("Сегодня", valueText(summary.latest))
                        statRow("Среднее за 7 дней", valueText(summary.average7d))
                        statRow("Изменение", String(format: "%+.0f%%", summary.trend * 100))
                    }
                }
            }
            .padding()
        }
        .screenBackground()
        .navigationTitle(type.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value).foregroundStyle(Theme.textPrimary).fontWeight(.semibold)
        }
        .font(.subheadline)
    }

    private func valueText(_ value: Double) -> String {
        type == .sleepHours ? String(format: "%.1f %@", value, type.unit) : "\(Int(value)) \(type.unit)"
    }
}
