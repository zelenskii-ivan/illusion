import SwiftUI
import SwiftData

struct AddMetricView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var type: MetricType = .steps
    @State private var valueText: String = ""
    @State private var date: Date = .now

    var body: some View {
        NavigationStack {
            Form {
                Section("Метрика") {
                    Picker("Тип", selection: $type) {
                        ForEach(MetricType.allCases) { type in
                            Label(type.title, systemImage: type.systemImage).tag(type)
                        }
                    }
                    HStack {
                        TextField("Значение", text: $valueText)
                            .keyboardType(.decimalPad)
                        Text(type.unit).foregroundStyle(.secondary)
                    }
                    DatePicker("Дата", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
            }
            .navigationTitle("Новое измерение")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { save() }.disabled(parsedValue == nil)
                }
            }
        }
    }

    private var parsedValue: Double? {
        Double(valueText.replacingOccurrences(of: ",", with: "."))
    }

    private func save() {
        guard let value = parsedValue else { return }
        context.insert(MetricSample(type: type, value: value, date: date, source: .manual))
        try? context.save()
        dismiss()
    }
}
