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
    @State private var connection: ConnectionStatus = .idle

    enum ConnectionStatus: Equatable {
        case idle, testing
        case ok(String)
        case failed(String)
    }

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
            Picker("Провайдер", selection: providerBinding) {
                ForEach(LLMProvider.allCases) { Text($0.title).tag($0) }
            }

            let provider = container.settings.llmProvider

            if provider.isCustomEndpoint {
                TextField("Base URL", text: settingBinding(\.llmBaseURL))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            if provider != .mock {
                TextField("Модель", text: settingBinding(\.llmModel))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("API-ключ", text: settingBinding(\.llmAPIKey))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if let url = provider.apiKeyURL {
                    Link(destination: url) {
                        Label("Получить бесплатный ключ", systemImage: "key.fill")
                    }
                }

                Button { testConnection() } label: {
                    HStack {
                        Label("Проверить подключение", systemImage: "bolt.horizontal.circle")
                        Spacer()
                        connectionIndicator
                    }
                }
                .disabled(connection == .testing)

                if case let .failed(message) = connection {
                    Text(message).font(.caption).foregroundStyle(.red)
                } else if case let .ok(reply) = connection {
                    Text("Ответ модели: \(reply)").font(.caption).foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("ИИ-модель")
        } footer: {
            Text("Демо-модель работает офлайн. **Groq** — бесплатный и быстрый (нужен бесплатный ключ, без карты). **OpenRouter** даёт доступ к бесплатным моделям. Можно указать и свой OpenAI-совместимый эндпоинт — туда же направить дообученную модель.")
        }
    }

    @ViewBuilder
    private var connectionIndicator: some View {
        switch connection {
        case .idle: EmptyView()
        case .testing: ProgressView()
        case .ok: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed: Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
        }
    }

    /// Биндинг к произвольному строковому полю настроек.
    private func settingBinding(_ keyPath: WritableKeyPath<AppSettings, String>) -> Binding<String> {
        Binding(
            get: { container.settings[keyPath: keyPath] },
            set: { container.settings[keyPath: keyPath] = $0 }
        )
    }

    /// Биндинг провайдера: при выборе пресета сразу подставляет его базовый URL и модель.
    private var providerBinding: Binding<LLMProvider> {
        Binding(
            get: { container.settings.llmProvider },
            set: { newValue in
                container.settings.llmProvider = newValue
                if let url = newValue.defaultBaseURL { container.settings.llmBaseURL = url }
                if let model = newValue.defaultModel { container.settings.llmModel = model }
                connection = .idle
            }
        )
    }

    private func testConnection() {
        container.updateLLMProvider()      // пересобрать сервис из текущих настроек
        connection = .testing
        let llm = container.llm
        Task {
            do {
                let reply = try await llm.complete(messages: [
                    LLMMessage(role: .system, content: "Ты — проверка связи. Ответь одним коротким словом."),
                    LLMMessage(role: .user, content: "Ответь: готово")
                ])
                let trimmed = reply.trimmingCharacters(in: .whitespacesAndNewlines)
                connection = .ok(String(trimmed.prefix(60)))
            } catch {
                connection = .failed(error.localizedDescription)
            }
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
