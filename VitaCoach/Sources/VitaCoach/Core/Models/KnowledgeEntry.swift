import Foundation
import SwiftData

/// Запись базы знаний (техники, рекомендации, выдержки из научных источников).
/// Используется как контекст для LLM (RAG) и для формирования обучающего датасета.
/// Источники — материалы открытого доступа из образовательной среды
/// и научные данные (ВОЗ, ACSM, AHA, NSCA, рецензируемые публикации).
@Model
final class KnowledgeEntry {
    var id: UUID
    var title: String
    var body: String
    var categoryRaw: String
    var tags: [String]
    var sourceTitle: String
    var sourceURL: String
    var sourceYear: Int

    var category: KnowledgeCategory {
        get { KnowledgeCategory(rawValue: categoryRaw) ?? .technique }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        title: String,
        body: String,
        category: KnowledgeCategory,
        tags: [String] = [],
        sourceTitle: String,
        sourceURL: String,
        sourceYear: Int
    ) {
        self.id = UUID()
        self.title = title
        self.body = body
        self.categoryRaw = category.rawValue
        self.tags = tags
        self.sourceTitle = sourceTitle
        self.sourceURL = sourceURL
        self.sourceYear = sourceYear
    }
}

enum KnowledgeCategory: String, Codable, CaseIterable, Identifiable {
    case technique
    case physiology
    case nutrition
    case recovery
    case guideline

    var id: String { rawValue }
    var title: String {
        switch self {
        case .technique: return "Техника"
        case .physiology: return "Физиология"
        case .nutrition: return "Питание"
        case .recovery: return "Восстановление"
        case .guideline: return "Рекомендации"
        }
    }
}
