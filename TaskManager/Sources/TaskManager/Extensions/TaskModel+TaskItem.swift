import Foundation
import TaskManagerUIComponents

extension TaskModel {
    func toTaskItem(customFieldEntries: [TaskManagerUIComponents.CustomFieldEntry] = []) -> TaskItem {
        TaskItem(
            id: id,
            title: title,
            notes: taskDescription,
            status: status.toUIComponentStatus(),
            isToday: isToday,
            priority: priority.toUIComponentPriority(),
            hasReminder: hasReminder,
            reminderDuration: reminderDuration,
            reminderFireDate: reminderFireDate,
            dueDate: dueDate,
            tags: tags,
            photos: photos.map { URL(fileURLWithPath: $0) },
            createdAt: createdAt,
            isRecurring: isRecurring,
            recurrenceRule: recurrenceRule.flatMap { TaskManagerUIComponents.RecurrenceRule(rawValue: $0.rawValue) },
            recurrenceInterval: recurrenceInterval,
            customFieldEntries: customFieldEntries
        )
    }
}

extension CustomFieldDefinitionModel {
    func toDefinition() -> TaskManagerUIComponents.CustomFieldDefinition {
        TaskManagerUIComponents.CustomFieldDefinition(
            id: id,
            name: name,
            valueType: valueType.toUIComponentValueType(),
            isActive: isActive,
            sortOrder: sortOrder
        )
    }
}

extension CustomFieldValueModel {
    func toEntry(definition: CustomFieldDefinitionModel) -> TaskManagerUIComponents.CustomFieldEntry {
        TaskManagerUIComponents.CustomFieldEntry(
            definitionId: definitionId,
            name: definition.name,
            valueType: definition.valueType.toUIComponentValueType(),
            stringValue: stringValue,
            numberValue: numberValue,
            decimalValue: decimalValue,
            dateValue: dateValue,
            boolValue: boolValue
        )
    }
}

extension CustomFieldValueType {
    func toUIComponentValueType() -> TaskManagerUIComponents.CustomFieldValueType {
        switch self {
        case .text: return .text
        case .number: return .number
        case .currency: return .currency
        case .date: return .date
        case .toggle: return .toggle
        }
    }
    
    static func from(_ type: TaskManagerUIComponents.CustomFieldValueType) -> CustomFieldValueType {
        switch type {
        case .text: return .text
        case .number: return .number
        case .currency: return .currency
        case .date: return .date
        case .toggle: return .toggle
        }
    }
}

extension TaskStatus {
    func toUIComponentStatus() -> TaskItem.Status {
        switch self {
        case .todo: return .todo
        case .inProgress: return .inProgress
        case .completed: return .completed
        }
    }
    
    static func from(_ status: TaskItem.Status) -> TaskStatus {
        switch status {
        case .todo: return .todo
        case .inProgress: return .inProgress
        case .completed: return .completed
        }
    }
}

extension TaskPriority {
    func toUIComponentPriority() -> TaskItem.Priority {
        switch self {
        case .critical, .high: return .high
        case .medium: return .medium
        case .low: return .low
        case .none: return .none
        }
    }
    
    static func from(_ priority: TaskItem.Priority) -> TaskPriority {
        switch priority {
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        case .none: return .none
        }
    }
}
