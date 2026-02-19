import SwiftUI

// MARK: - Focus Field Enum
public enum TaskFormField: Hashable {
    case title
    case tag
    case customField(UUID)
}

// MARK: - Task Form Content (Reusable)
public struct TaskFormContent: View {
    @Binding var taskTitle: String
    @Binding var taskNotes: String
    @Binding var selectedDate: Date
    @Binding var hasDate: Bool
    @Binding var hasReminder: Bool
    @Binding var reminderDuration: TimeInterval
    @Binding var selectedPriority: TaskItem.Priority
    @Binding var tags: [String]
    @Binding var showValidationError: Bool
    @Binding var photos: [URL]
    @Binding var isRecurring: Bool
    @Binding var recurrenceRule: RecurrenceRule
    @Binding var recurrenceInterval: Int
    @Binding var customFieldValues: [UUID: CustomFieldEditValue]
    let activeCustomFieldDefinitions: [CustomFieldDefinition]
    let recurringFeatureEnabled: Bool
    let availableTags: [String]

    let onPickPhotos: ((@escaping ([URL]) -> Void) -> Void)?
    let onDeletePhoto: ((URL) -> Void)?

    @State private var newTag = ""
    @State private var showTagConfirmation = false
    @State private var pendingTag = ""
    @FocusState private var focusedField: TaskFormField?
    
    public init(
        taskTitle: Binding<String>,
        taskNotes: Binding<String>,
        selectedDate: Binding<Date>,
        hasDate: Binding<Bool>,
        hasReminder: Binding<Bool>,
        reminderDuration: Binding<TimeInterval>,
        selectedPriority: Binding<TaskItem.Priority>,
        tags: Binding<[String]>,
        showValidationError: Binding<Bool>,
        photos: Binding<[URL]> = .constant([]),
        isRecurring: Binding<Bool> = .constant(false),
        recurrenceRule: Binding<RecurrenceRule> = .constant(.weekly),
        recurrenceInterval: Binding<Int> = .constant(1),
        customFieldValues: Binding<[UUID: CustomFieldEditValue]> = .constant([:]),
        activeCustomFieldDefinitions: [CustomFieldDefinition] = [],
        recurringFeatureEnabled: Bool = false,
        availableTags: [String] = [],
        onPickPhotos: ((@escaping ([URL]) -> Void) -> Void)? = nil,
        onDeletePhoto: ((URL) -> Void)? = nil
    ) {
        self._taskTitle = taskTitle
        self._taskNotes = taskNotes
        self._selectedDate = selectedDate
        self._hasDate = hasDate
        self._hasReminder = hasReminder
        self._reminderDuration = reminderDuration
        self._selectedPriority = selectedPriority
        self._tags = tags
        self._showValidationError = showValidationError
        self._photos = photos
        self._isRecurring = isRecurring
        self._recurrenceRule = recurrenceRule
        self._recurrenceInterval = recurrenceInterval
        self._customFieldValues = customFieldValues
        self.activeCustomFieldDefinitions = activeCustomFieldDefinitions
        self.recurringFeatureEnabled = recurringFeatureEnabled
        self.availableTags = availableTags
        self.onPickPhotos = onPickPhotos
        self.onDeletePhoto = onDeletePhoto
    }
    
    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    private func requestAddTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else {
            newTag = ""
            return
        }

        if tags.contains(trimmed) {
            newTag = ""
            return
        }

        if availableTags.contains(trimmed) {
            tags.append(trimmed)
            newTag = ""
            return
        }

        pendingTag = trimmed
        showTagConfirmation = true
    }

    private func confirmAddTag() {
        tags.append(pendingTag)
        newTag = ""
        pendingTag = ""
    }

    private func toggleTag(_ tag: String) {
        if tags.contains(tag) {
            tags.removeAll { $0 == tag }
        } else {
            tags.append(tag)
        }
    }

    // MARK: - Custom Field Bindings

    private func textBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: {
                if case .text(let value) = customFieldValues[id] { return value }
                return ""
            },
            set: { customFieldValues[id] = .text($0) }
        )
    }

    private func numberBinding(for id: UUID) -> Binding<Double?> {
        Binding(
            get: {
                if case .number(let value) = customFieldValues[id] { return value }
                return nil
            },
            set: { customFieldValues[id] = .number($0) }
        )
    }

    private func currencyBinding(for id: UUID) -> Binding<Decimal?> {
        Binding(
            get: {
                if case .currency(let value) = customFieldValues[id] { return value }
                return nil
            },
            set: { customFieldValues[id] = .currency($0) }
        )
    }

    private func dateBinding(for id: UUID) -> Binding<Date> {
        Binding(
            get: {
                if case .date(let value) = customFieldValues[id], let value { return value }
                return Date()
            },
            set: { customFieldValues[id] = .date($0) }
        )
    }

    private func hasDateBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: {
                if case .date(let value) = customFieldValues[id] { return value != nil }
                return false
            },
            set: { newValue in
                if newValue {
                    customFieldValues[id] = .date(Date())
                } else {
                    customFieldValues[id] = .date(nil)
                }
            }
        )
    }

    private func toggleBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: {
                if case .toggle(let value) = customFieldValues[id] { return value }
                return false
            },
            set: { customFieldValues[id] = .toggle($0) }
        )
    }

    @ViewBuilder
    private func customFieldRow(for definition: CustomFieldDefinition) -> some View {
        HStack(spacing: 12) {
            Text(definition.name)
                .foregroundStyle(.primary)

            Spacer()

            switch definition.valueType {
            case .text:
                TextField("", text: textBinding(for: definition.id))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 180)
                    .focused($focusedField, equals: .customField(definition.id))
            case .number:
                TextField("", value: numberBinding(for: definition.id), format: .number)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 140)
                    .focused($focusedField, equals: .customField(definition.id))
            case .currency:
                TextField("", value: currencyBinding(for: definition.id), format: .currency(code: currencyCode))
                    .multilineTextAlignment(.trailing)
                    .frame(width: 140)
                    .focused($focusedField, equals: .customField(definition.id))
            case .toggle:
                Toggle("", isOn: toggleBinding(for: definition.id))
                    .controlSize(.small)
                    .labelsHidden()
                    .accessibilityLabel("\(definition.name) toggle")
            case .date:
                Toggle("", isOn: hasDateBinding(for: definition.id))
                    .controlSize(.small)
                    .labelsHidden()
                    .accessibilityLabel("\(definition.name) date")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if definition.valueType != .toggle && definition.valueType != .date {
                focusedField = .customField(definition.id)
            }
        }
    }

    @ViewBuilder
    private func customFieldDatePicker(for definition: CustomFieldDefinition) -> some View {
        if definition.valueType == .date && hasDateBinding(for: definition.id).wrappedValue {
            DatePicker(
                "",
                selection: dateBinding(for: definition.id),
                displayedComponents: [.date]
            )
            .labelsHidden()
        }
    }

    public var body: some View {
        Form {
            Section("Task Details") {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        TextField("Task title", text: $taskTitle)
                            .textFieldStyle(.plain)
                            .focused($focusedField, equals: .title)
                        Text("*")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusedField = .title
                    }
                    .onChange(of: taskTitle) { _, _ in
                        showValidationError = false
                    }

                    if showValidationError {
                        Label("Title is required", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                TextareaField(
                    text: $taskNotes,
                    placeholder: "Add notes...",
                    height: 80
                )
            }

            Section("Dates & Reminders") {
                Toggle("Set Due Date", isOn: $hasDate)
                    .controlSize(.small)

                if hasDate {
                    DatePicker(
                        "Due Date",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                }

                Toggle("Set Reminder", isOn: $hasReminder)
                    .controlSize(.small)

                if hasReminder {
                    ReminderDurationPicker(duration: $reminderDuration)
                }

                if hasReminder && hasDate {
                    DatePicker(
                        "Reminder Time",
                        selection: $selectedDate,
                        displayedComponents: [.hourAndMinute]
                    )
                }
            }

            Section("Priority") {
                PriorityPicker(selectedPriority: $selectedPriority)
            }

            Section("Tags") {
                HStack {
                    TextField("Add tag (press Enter)", text: $newTag)
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .tag)
                        .onSubmit {
                            requestAddTag()
                        }

                    Button("Add") {
                        requestAddTag()
                    }
                    .buttonStyle(.borderless)
                    .disabled(newTag.isEmpty)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    focusedField = .tag
                }

                if !availableTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(availableTags, id: \.self) { tag in
                                Button {
                                    toggleTag(tag)
                                } label: {
                                    TagChip(text: tag)
                                        .opacity(tags.contains(tag) ? 1 : 0.45)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if !tags.isEmpty {
                    TagCloud(tags: tags, onRemove: { tag in
                        tags.removeAll { $0 == tag }
                    })
                }
            }

            Section("Recurrence") {
                Toggle("Recurring Task", isOn: $isRecurring)
                    .controlSize(.small)
                    .disabled(!recurringFeatureEnabled)

                if !recurringFeatureEnabled {
                    Text("Premium feature")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if isRecurring {
                    if recurringFeatureEnabled {
                        Picker("Repeats", selection: $recurrenceRule) {
                            ForEach(RecurrenceRule.allCases, id: \.self) { rule in
                                Text(rule.displayName).tag(rule)
                            }
                        }

                        let unit = recurrenceRule == .daily ? "day(s)" :
                            recurrenceRule == .weekly ? "week(s)" :
                            recurrenceRule == .monthly ? "month(s)" :
                            recurrenceRule == .yearly ? "year(s)" : "weekday(s)"

                        Stepper("Every \(recurrenceInterval) \(unit)", value: $recurrenceInterval, in: 1...52)
                    } else {
                        Text("Upgrade to edit recurrence settings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !activeCustomFieldDefinitions.isEmpty {
                Section("Custom Fields") {
                    ForEach(activeCustomFieldDefinitions) { definition in
                        customFieldRow(for: definition)
                        customFieldDatePicker(for: definition)
                    }
                }
            }

            Section("Attachments") {
                HStack {
                    Button {
                        onPickPhotos? { urls in
                            photos.append(contentsOf: urls)
                        }
                    } label: {
                        Label("Add Photos", systemImage: "photo.on.rectangle.angled")
                    }
                    .buttonStyle(.borderless)
                    
                    Spacer()
                    
                    if !photos.isEmpty {
                        Text("\(photos.count) photo\(photos.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !photos.isEmpty {
                    PhotoThumbnailStrip(
                        photos: photos,
                        onRemove: { url in
                            photos.removeAll { $0 == url }
                            onDeletePhoto?(url)
                        }
                    )
                }
            }
        }
        .formStyle(.grouped)
        .confirmationDialog(
            "Create Tag?",
            isPresented: $showTagConfirmation,
            titleVisibility: .visible
        ) {
            Button("Create \"\(pendingTag)\"") {
                confirmAddTag()
            }
            Button("Cancel", role: .cancel) {
                pendingTag = ""
            }
        } message: {
            Text("Create new tag \"\(pendingTag)\" and add it to this task?")
        }

    }
}
