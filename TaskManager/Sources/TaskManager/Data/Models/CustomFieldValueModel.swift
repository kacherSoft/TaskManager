import SwiftData
import Foundation

@Model
final class CustomFieldValueModel {
    @Attribute(.unique) var id: UUID
    var definitionId: UUID
    var taskId: UUID
    var stringValue: String?
    var numberValue: Double?
    var decimalValue: Decimal?
    var dateValue: Date?
    var boolValue: Bool?
    
    init(definitionId: UUID, taskId: UUID, stringValue: String? = nil, numberValue: Double? = nil, decimalValue: Decimal? = nil, dateValue: Date? = nil, boolValue: Bool? = nil) {
        self.id = UUID()
        self.definitionId = definitionId
        self.taskId = taskId
        self.stringValue = stringValue
        self.numberValue = numberValue
        self.decimalValue = decimalValue
        self.dateValue = dateValue
        self.boolValue = boolValue
    }
}
