import SwiftUI
import SwiftData

struct LogSessionView: View {
    let suggested: PlannedWorkout?
    var onSaved: () -> Void = {}
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var duration: Int = 40
    @State private var rpe: Int = 6
    @State private var calories: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Тренировка") {
                    TextField("Название", text: $title)
                    Stepper("Длительность: \(duration) мин", value: $duration, in: 5...240, step: 5)
                }
                Section("Нагрузка") {
                    VStack(alignment: .leading) {
                        Text("Воспринимаемое усилие (RPE): \(rpe)")
                        Slider(value: Binding(get: { Double(rpe) }, set: { rpe = Int($0) }), in: 1...10, step: 1)
                        Text("Шкала Борга CR10: 1 — очень легко, 10 — максимум.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    HStack {
                        TextField("Калории (необязательно)", text: $calories)
                            .keyboardType(.numberPad)
                        Text("ккал").foregroundStyle(.secondary)
                    }
                }
                Section("Заметки") {
                    TextField("Как прошло?", text: $notes, axis: .vertical).lineLimit(2...5)
                }
            }
            .navigationTitle("Записать тренировку")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { save() }.disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let suggested {
                    title = suggested.title
                    duration = suggested.estimatedMinutes
                }
            }
        }
    }

    private func save() {
        let session = WorkoutSession(
            title: title,
            durationMinutes: duration,
            perceivedExertion: rpe,
            notes: notes,
            caloriesBurned: Double(calories) ?? 0
        )
        if let suggested {
            session.exercises = suggested.exercises.map {
                LoggedExercise(name: $0.name, exerciseKey: $0.exerciseKey, sets: $0.sets, reps: $0.reps, weightKg: 0, order: $0.order)
            }
        }
        context.insert(session)
        if let cal = Double(calories), cal > 0 {
            context.insert(MetricSample(type: .activeEnergy, value: cal, date: .now, source: .manual))
        }
        try? context.save()
        onSaved()
        dismiss()
    }
}
