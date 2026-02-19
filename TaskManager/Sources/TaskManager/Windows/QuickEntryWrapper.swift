import SwiftUI
import TaskManagerUIComponents

struct QuickEntryWrapper: View {
    var onDismiss: () -> Void
    var onCreate: (String, String, Date?, Bool, TimeInterval, TaskItem.Priority, [String], [URL], Bool, TaskManagerUIComponents.RecurrenceRule, Int, [UUID: TaskManagerUIComponents.CustomFieldEditValue]) -> Void
    var activeCustomFieldDefinitions: [TaskManagerUIComponents.CustomFieldDefinition]
    var availableTags: [String]
    var onPickPhotos: ((@escaping ([URL]) -> Void) -> Void)?
    var onDeletePhoto: ((URL) -> Void)?
    
    var body: some View {
        QuickEntryContent(
            onCancel: onDismiss,
            onCreate: { title, notes, dueDate, hasReminder, duration, priority, tags, photos, isRecurring, recurrenceRule, recurrenceInterval, customFieldValues in
                onCreate(title, notes, dueDate, hasReminder, duration, priority, tags, photos, isRecurring, recurrenceRule, recurrenceInterval, customFieldValues)
                onDismiss()
            },
            activeCustomFieldDefinitions: activeCustomFieldDefinitions,
            availableTags: availableTags,
            onPickPhotos: onPickPhotos,
            onDeletePhoto: onDeletePhoto
        )
    }
}
