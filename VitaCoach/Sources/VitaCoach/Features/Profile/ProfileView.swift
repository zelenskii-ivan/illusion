import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var profiles: [UserProfile]
    @Query private var coachMessages: [CoachMessage]
    @Query private var analyses: [TechniqueAnalysis]

    @State private var exportURL: URL?
    @State private var exportCount: Int = 0

    var body: some View {
        NavigationStack {
            Form {
                if let profile = profiles.first {
                    profileSection(profile)
                    goalsSection(profile)
                }
                llmSection
                trainingSection
                sourcesSection
                aboutSection
            }
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { save(); dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func profileSection(_ profile: UserProfile) -> some View {
        @Bindable var profile = profile
        Section("Профиль") {
            TextField("Имя", text: $profile.name)
            DatePicker("Дата рождения", selection: $profile.birthDate, displayedComponents: .date)
            Picker("Пол", selection: $profile.biologicalSex) {
                ForEach(BiologicalSex.allCases) { Text($0.title).tag($0) }
            }
            Stepper("Рост: \(Int(profile.heightCm)) см", value: $profile.heightCm, in: 120...230)
            Stepper("Вес: \(Int(profile.weightKg)) кг", value: $profile.weightKg, in: 35...250)
        }
    }

    @ViewBuilder
    private func goalsSection(_ profile: UserProfile) -> some View {
        @Bindable var profile = profile
        Section("Цели и уровень") {
            Picker("Уровень", selection: $profile.fitnessLevel) {
                ForEach(FitnessLevel.allCases) { Text($0.title).tag($0) }
            }
            Picker("Цель", selection: $profile.goal) {
                ForEach(FitnessGoal.allCases) { Text($0.title).tag($0) }
            }
            Stepper("Тренировок в неделю: \(profile.weeklyWorkoutTarget)",
                    value: $profile.weeklyWorkoutTarget, in: 2...6)
        }
    }

    private var llmSection: some View {
        Section {
            Picker("Провайдер", selection: Binding(
                get: { container.settings.llmProvider },
                set: { container.settings.llmProvider = $0 }
            )) {
                ForEach(LLMProvider.allCases) { Text($0.title).tag($0) }
            }
            if container.settings.llmProvider == .openAICompatible {
                TextField("Base URL", text: Binding(
                    get: { container.settings.llmBaseURL },
                    set: { container.settings.llmBaseURL = $0 }
                ))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                TextField("Модель", text: Binding(
                    get: { container.settings.llmModel },
                    set: { container.settings.llmModel = $0 }
                ))
                .autocorrectionDisabled()
                SecureField("API-ключ", text: Binding(
                    get: { container.settings.llmAPIKey },
                    set: { container.settings.llmAPIKey = $0 }
                ))
            }
        } header: {
            Text("ИИ-модель")
        } footer: {
            Text("Демо-модель работает офлайн. Для реальных ответов укажите OpenAI-совместимый эндпоинт — туда же можно направить вашу дообученную модель.")
        }
    }

    private var trainingSection: some View {
        Section {
            Toggle("Собирать данные для обучения", isOn: Binding(
                get: { container.settings.allowDatasetCollection },
                set: { container.settings.allowDatasetCollection = $0 }
            ))
            Button {
                exportDataset()
            } label: {
                Label("Экспортировать датасет (JSONL)", systemImage: "square.and.arrow.up")
            }
            .disabled(!container.settings.allowDatasetCollection)

            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Поделиться: \(exportCount) примеров", systemImage: "doc.text")
                }
            }
        } header: {
            Text("Дообучение модели")
        } footer: {
            Text("Из ваших диалогов с тренером (с оценками 👍/👎) и разборов техники формируется датасет в формате чат-сообщений для fine-tuning. Данные обезличены.")
        }
    }

    private var sourcesSection: some View {
        Section("Научная база") {
            ForEach(container.knowledgeBase.sources) { source in
                VStack(alignment: .leading, spacing: 2) {
                    Text(source.title).font(.subheadline)
                    Text("\(source.organization), \(String(source.year))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private var aboutSection: some View {
        Section {
            LabeledContent("Версия", value: "1.0.0")
            LabeledContent("Записей в базе знаний", value: "\(container.knowledgeBase.techniques.count + container.knowledgeBase.sources.count)")
        } footer: {
            Text("VitaCoach — образовательный проект. Не заменяет консультацию врача.")
        }
    }

    private func exportDataset() {
        let examples = container.datasetBuilder.examples(from: coachMessages)
            + container.datasetBuilder.examples(from: analyses)
        guard let result = try? container.datasetBuilder.exportJSONL(examples: examples) else { return }
        exportURL = result.url
        exportCount = result.exampleCount
    }

    private func save() {
        container.updateLLMProvider()
        try? context.save()
    }
}
