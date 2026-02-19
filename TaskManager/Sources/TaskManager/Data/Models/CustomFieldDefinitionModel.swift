import SwiftData
import Foundation

@Model
final class CustomFieldDefinitionModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var valueTypeRaw: String
    var isActive: Bool
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
    
    var valueType: CustomFieldValueType {
        get { CustomFieldValueType(rawValue: valueTypeRaw) ?? .text }
        set { valueTypeRaw = newValue.rawValue }
    }
    
    init(name: String, valueType: CustomFieldValueType = .text, isActive: Bool = true, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.valueTypeRaw = valueType.rawValue
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func touch() {
        updatedAt = Date()
    }
}

enum CustomFieldValueType: String, Codable, CaseIterable, Sendable {
    case text = "text"
    case number = "number"
    case currency = "currency"
    case date = "date"
    case toggle = "toggle"
}
