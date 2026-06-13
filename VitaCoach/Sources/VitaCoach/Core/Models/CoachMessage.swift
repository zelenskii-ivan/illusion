import Foundation
import SwiftData

/// Сообщение в диалоге с ИИ-тренером. Хранится, чтобы:
/// 1) показывать историю; 2) формировать датасет для дообучения LLM.
@Model
final class CoachMessage {
    var id: UUID
    var roleRaw: String
    var content: String
    var date: Date
    /// Оценка пользователя (для RLHF-подобного сбора данных): -1, 0, +1.
    var rating: Int

    var role: LLMRole {
        get { LLMRole(rawValue: roleRaw) ?? .user }
        set { roleRaw = newValue.rawValue }
    }

    init(role: LLMRole, content: String, date: Date = .now, rating: Int = 0) {
        self.id = UUID()
        self.roleRaw = role.rawValue
        self.content = content
        self.date = date
        self.rating = rating
    }
}
