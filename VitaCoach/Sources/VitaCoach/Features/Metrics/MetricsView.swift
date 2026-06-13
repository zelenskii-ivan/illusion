import SwiftUI
import SwiftData
import Charts

struct MetricsView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var context
    @Query private var samples: [MetricSample]
    @State private var showAdd = false
    @State private var isImporting = false

    private var summaries: [MetricSummary] {
        MetricType.allCases.map { MetricsAnalytics.summary(for: $0, from: samples) }
            .filter { !$0.series.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(summaries) { summary in
                        NavigationLink {
                            MetricDetailView(type: summary.type)
                        } label: {
                            MetricRow(summary: summary)
                        }
                        .buttonStyle(.plain)
                    }
                    if summaries.isEmpty {
                        EmptyStateView(systemImage: "chart.xyaxis.line",
                                       title: "Пока нет данных",
                                       message: "Добавьте измерение вручную или импортируйте из Здоровья.")
                    }
                }
                .padding()
            }
            .screenBackground()
            .navigationTitle("Метрики")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task { await importHealth() }
                    } label: {
                        if isImporting { ProgressView() }
                        else { Image(systemName: "heart.text.square") }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddMetricView()
            }
        }
    }

    private func importHealth() async {
        isImporting = true
        defer { isImporting = false }
        let granted = await container.healthKit.requestAuthorization()
        guard granted else { return }
        let imported = await container.healthKit.importDailyMetrics(days: 14)
        for sample in imported { context.insert(sample) }
        try? context.save()
    }
}

struct MetricRow: View {
    let summary: MetricSummary

    var body: some View {
        Card {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(summary.type.tint.opacity(0.18)).frame(width: 44, height: 44)
                    Image(systemName: summary.type.systemImage).foregroundStyle(summary.type.tint)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.type.title).font(.headline).foregroundStyle(Theme.textPrimary)
                    Text("7д: \(Int(summary.average7d)) \(summary.type.unit)")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(valueText).font(.title3.bold()).foregroundStyle(Theme.textPrimary)
                    TrendBadge(trend: summary.trend, higherIsBetter: summary.type.higherIsBetter)
                }
                miniChart.frame(width: 64, height: 36)
            }
        }
    }

    private var valueText: String {
        summary.type == .sleepHours
            ? String(format: "%.1f", summary.latest)
            : "\(Int(summary.latest))"
    }

    private var miniChart: some View {
        Chart(summary.series.suffix(14)) { point in
            LineMark(x: .value("Дата", point.date), y: .value("Знач", point.value))
                .interpolationMethod(.catmullRom)
                .foregroundStyle(summary.type.tint)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

struct TrendBadge: View {
    let trend: Double
    let higherIsBetter: Bool

    var body: some View {
        let positive = higherIsBetter ? trend >= 0 : trend <= 0
        let color: Color = abs(trend) < 0.01 ? Theme.textSecondary : (positive ? .green : .orange)
        Label(String(format: "%.0f%%", abs(trend) * 100), systemImage: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
    }
}
