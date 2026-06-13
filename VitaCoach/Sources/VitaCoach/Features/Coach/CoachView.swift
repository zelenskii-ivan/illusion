import SwiftUI
import SwiftData

struct CoachView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var context
    @Query(sort: \CoachMessage.date) private var messages: [CoachMessage]
    @Query private var profiles: [UserProfile]
    @Query private var samples: [MetricSample]

    @State private var input: String = ""
    @State private var isSending = false

    private let suggestions = [
        "Составь план на неделю",
        "Как улучшить технику приседа?",
        "Сколько мне нужно спать?",
        "Что съесть после тренировки?"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if messages.isEmpty { welcome }
                            ForEach(messages) { message in
                                MessageBubble(message: message) { rating in
                                    message.rating = rating
                                    try? context.save()
                                }
                                .id(message.id)
                            }
                            if isSending {
                                HStack { ProgressView().tint(Theme.accent); Spacer() }
                                    .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                    }
                }

                if messages.isEmpty {
                    suggestionChips
                }
                inputBar
            }
            .screenBackground()
            .navigationTitle("ИИ-тренер")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(container.llm.displayName)
                        .font(.caption2).foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private var welcome: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader("Привет! Я VitaCoach", systemImage: "sparkles")
                Text("Я учитываю ваш профиль и метрики и опираюсь на доказательные источники (ВОЗ, ACSM, NSCA). Спросите про тренировки, технику, питание, сон или восстановление.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var suggestionChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        input = suggestion
                        send()
                    } label: { Tag(text: suggestion, tint: Theme.accentSecondary) }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Сообщение тренеру…", text: $input, axis: .vertical)
                .lineLimit(1...4)
                .padding(12)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
            Button {
                send()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? Theme.accent : Theme.textSecondary)
            }
            .disabled(!canSend)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        input = ""

        let userMessage = CoachMessage(role: .user, content: text)
        context.insert(userMessage)
        try? context.save()

        let history = (messages + [userMessage]).sorted { $0.date < $1.date }
        Task { await respond(to: text, history: history) }
    }

    private func respond(to query: String, history: [CoachMessage]) async {
        isSending = true
        defer { isSending = false }

        let builder = LLMPromptBuilder(knowledgeBase: container.knowledgeBase)
        let summaries = [MetricType.steps, .sleepHours, .restingHeartRate, .activeEnergy]
            .map { MetricsAnalytics.summary(for: $0, from: samples) }
        let system = builder.systemPrompt(profile: profiles.first, summaries: summaries, query: query)

        var llmMessages = [LLMMessage(role: .system, content: system)]
        llmMessages += history.suffix(10).map { LLMMessage(role: $0.role, content: $0.content) }

        do {
            let reply = try await container.llm.complete(messages: llmMessages)
            context.insert(CoachMessage(role: .assistant, content: reply))
        } catch {
            context.insert(CoachMessage(role: .assistant, content: "Не удалось получить ответ: \(error.localizedDescription)"))
        }
        try? context.save()
    }
}

struct MessageBubble: View {
    let message: CoachMessage
    var onRate: (Int) -> Void

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                Text(message.content)
                    .font(.subheadline)
                    .foregroundStyle(isUser ? Color.black : Theme.textPrimary)
                    .padding(12)
                    .background(
                        isUser ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Theme.surface),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                if !isUser {
                    HStack(spacing: 16) {
                        Button { onRate(message.rating == 1 ? 0 : 1) } label: {
                            Image(systemName: message.rating == 1 ? "hand.thumbsup.fill" : "hand.thumbsup")
                        }
                        Button { onRate(message.rating == -1 ? 0 : -1) } label: {
                            Image(systemName: message.rating == -1 ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                }
            }
            if !isUser { Spacer(minLength: 40) }
        }
    }
}
