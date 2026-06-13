import SwiftUI

struct WorkoutDetailView: View {
    let workout: PlannedWorkout
    @State private var showLog = false
    @State private var celebrate = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(workout.focus).font(.headline).foregroundStyle(Theme.accent)
                        Text("Примерно \(workout.estimatedMinutes) минут · \(workout.exercises.count) упражнений")
                            .font(.subheadline).foregroundStyle(Theme.textSecondary)
                    }
                }
                .appearCascade(0, reduceMotion: reduceMotion)

                ForEach(Array(workout.exercises.sorted { $0.order < $1.order }.enumerated()),
                        id: \.element.id) { index, exercise in
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(exercise.name).font(.headline).foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Tag(text: setsRepsText(exercise))
                            }
                            HStack(spacing: 14) {
                                Label("\(exercise.restSeconds)с отдых", systemImage: "timer")
                                Label("темп \(exercise.tempo)", systemImage: "metronome")
                            }
                            .font(.caption).foregroundStyle(Theme.textSecondary)
                            if !exercise.notes.isEmpty {
                                Text(exercise.notes).font(.caption).foregroundStyle(Theme.textSecondary)
                            }
                        }
                    }
                    .appearCascade(index + 1, reduceMotion: reduceMotion)
                }

                Button {
                    showLog = true
                } label: {
                    Label("Записать как выполненную", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
        .screenBackground()
        .navigationTitle(workout.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLog) {
            LogSessionView(suggested: workout, onSaved: { celebrate = true })
        }
        .overlay {
            if celebrate {
                CelebrationView { withAnimation(.easeInOut(duration: 0.3)) { celebrate = false } }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: celebrate)
    }

    private func setsRepsText(_ e: PlannedExercise) -> String {
        e.reps > 0 ? "\(e.sets)×\(e.reps)" : "\(e.sets) подх."
    }
}
