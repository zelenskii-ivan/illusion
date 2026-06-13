import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct TechniqueView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var context
    @Query(sort: \TechniqueAnalysis.date, order: .reverse) private var history: [TechniqueAnalysis]
    @Query private var profiles: [UserProfile]

    @State private var selectedExercise: String = "bodyweight_squat"
    @State private var pickerItem: PhotosPickerItem?
    @State private var state: AnalysisState = .idle
    @State private var lastResult: TechniqueAnalysis?

    enum AnalysisState: Equatable {
        case idle, loading, analyzing, done, failed(String)
    }

    private var techniques: [ExerciseTechnique] { container.knowledgeBase.techniques }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    intro
                    exercisePicker
                    pickerButton
                    statusView
                    if let result = lastResult {
                        TechniqueResultCard(analysis: result)
                    }
                    historySection
                }
                .padding()
            }
            .screenBackground()
            .navigationTitle("Техника")
            .onChange(of: pickerItem) { _, newValue in
                guard let newValue else { return }
                Task { await analyze(item: newValue) }
            }
        }
    }

    private var intro: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader("Анализ техники по видео", systemImage: "figure.strengthtraining.traditional")
                Text("Снимите подход сбоку, в полный рост. ИИ распознает позу (Vision), измерит углы в суставах и сравнит с эталоном из научных источников.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var exercisePicker: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Упражнение").font(.subheadline).foregroundStyle(Theme.textSecondary)
                Picker("Упражнение", selection: $selectedExercise) {
                    ForEach(techniques) { tech in
                        Text(tech.name).tag(tech.key)
                    }
                }
                .pickerStyle(.segmented)
                if let tech = container.knowledgeBase.technique(for: selectedExercise) {
                    ForEach(tech.cues.prefix(3), id: \.self) { cue in
                        Label(cue, systemImage: "checkmark.seal")
                            .font(.caption).foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
    }

    private var pickerButton: some View {
        PhotosPicker(selection: $pickerItem, matching: .videos) {
            Label("Выбрать видео", systemImage: "video.badge.plus")
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(state == .loading || state == .analyzing)
    }

    @ViewBuilder
    private var statusView: some View {
        switch state {
        case .loading:
            ProgressView("Загрузка видео…").tint(Theme.accent)
        case .analyzing:
            ProgressView("Анализ позы и углов…").tint(Theme.accent)
        case .failed(let message):
            Card {
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.subheadline).foregroundStyle(.orange)
            }
        default:
            EmptyView()
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("История разборов", systemImage: "clock.arrow.circlepath")
            if history.isEmpty {
                Text("Здесь появятся ваши прошлые анализы.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
            } else {
                ForEach(history.prefix(8)) { item in
                    Card(padding: 12) {
                        HStack {
                            ZStack {
                                ProgressRing(progress: item.overallScore / 100,
                                             tint: scoreColor(item.overallScore), lineWidth: 4)
                                    .frame(width: 40, height: 40)
                                Text("\(Int(item.overallScore))").font(.caption.bold())
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.exerciseName).font(.subheadline.bold()).foregroundStyle(Theme.textPrimary)
                                Text("\(item.repsDetected) повт. · \(item.date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption).foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private func analyze(item: PhotosPickerItem) async {
        state = .loading
        lastResult = nil
        do {
            guard let movie = try await item.loadTransferable(type: Movie.self) else {
                state = .failed("Не удалось загрузить видео.")
                return
            }
            state = .analyzing
            let frames = try await container.poseEstimator.analyzeVideo(url: movie.url)
            let analysis = container.techniqueEvaluator.evaluate(exerciseKey: selectedExercise, frames: frames)

            // Дополняем разбор комментарием LLM (если настроен реальный провайдер — реальным, иначе демо).
            let comment = await coachComment(for: analysis)
            analysis.coachComment = comment

            context.insert(analysis)
            try? context.save()
            lastResult = analysis
            state = .done
        } catch {
            state = .failed(error.localizedDescription)
        }
        pickerItem = nil
    }

    private func coachComment(for analysis: TechniqueAnalysis) async -> String {
        let builder = LLMPromptBuilder(knowledgeBase: container.knowledgeBase)
        let system = builder.systemPrompt(profile: profiles.first, summaries: [], query: analysis.exerciseName + " техника")
        let angles = analysis.jointAngleSummary
            .map { "\($0.jointName): \(Int($0.minAngle))–\(Int($0.maxAngle))°" }
            .joined(separator: ", ")
        let user = "Разбор техники «\(analysis.exerciseName)». Оценка \(Int(analysis.overallScore))/100. Углы: \(angles). Дай 1–2 фразы фокуса на следующий подход."
        let messages = [LLMMessage(role: .system, content: system), LLMMessage(role: .user, content: user)]
        return (try? await container.llm.complete(messages: messages)) ?? ""
    }

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .orange
        }
    }
}

/// Загружаемое видео из библиотеки фото во временный файл.
struct Movie: Transferable {
    let url: URL
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension)
            try? FileManager.default.removeItem(at: copy)
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Movie(url: copy)
        }
    }
}
