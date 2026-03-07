import Foundation

nonisolated struct ContentCalendarEntry: Identifiable, Codable, Sendable {
    let id: String
    let dayOfWeek: Int
    var category: PostCategory
    var subcategory: String
    var promptTemplate: String
    var imageStyle: String
    var isActive: Bool

    var dayName: String {
        switch dayOfWeek {
        case 0: return "Domingo"
        case 1: return "Segunda"
        case 2: return "Terça"
        case 3: return "Quarta"
        case 4: return "Quinta"
        case 5: return "Sexta"
        case 6: return "Sábado"
        default: return ""
        }
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        dayOfWeek = try container.decode(Int.self, forKey: .dayOfWeek)
        category = try container.decode(PostCategory.self, forKey: .category)
        subcategory = try container.decodeIfPresent(String.self, forKey: .subcategory) ?? ""
        promptTemplate = try container.decodeIfPresent(String.self, forKey: .promptTemplate) ?? ""
        imageStyle = try container.decodeIfPresent(String.self, forKey: .imageStyle) ?? ""
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive) ?? true
    }

    init(id: String, dayOfWeek: Int, category: PostCategory, subcategory: String, promptTemplate: String, imageStyle: String, isActive: Bool) {
        self.id = id
        self.dayOfWeek = dayOfWeek
        self.category = category
        self.subcategory = subcategory
        self.promptTemplate = promptTemplate
        self.imageStyle = imageStyle
        self.isActive = isActive
    }
}
