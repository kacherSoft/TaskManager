import SwiftUI

// MARK: - Sidebar View
public struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?
    let tags: [String]
    @Binding var selectedTag: String?
    @Binding var selectedDate: Date?
    @Binding var dateFilterMode: CalendarFilterMode
    let tasks: [TaskItem]

    public init(
        selectedItem: Binding<SidebarItem?>,
        tags: [String] = [],
        selectedTag: Binding<String?> = .constant(nil),
        selectedDate: Binding<Date?> = .constant(nil),
        dateFilterMode: Binding<CalendarFilterMode> = .constant(.all),
        tasks: [TaskItem] = []
    ) {
        self._selectedItem = selectedItem
        self.tags = tags
        self._selectedTag = selectedTag
        self._selectedDate = selectedDate
        self._dateFilterMode = dateFilterMode
        self.tasks = tasks
    }

    public var body: some View {
        VStack(spacing: 0) {
            List(selection: $selectedItem) {
                Section("My Work") {
                    ForEach(SidebarItem.mainItems) { item in
                        SidebarRow(item: item)
                            .tag(item)
                    }
                }

                Section("Tags") {
                    if tags.isEmpty {
                        Text("No tags yet")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 2)
                    } else {
                        ForEach(tags, id: \.self) { tagName in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(tagColor(for: tagName))
                                    .frame(width: 8, height: 8)

                                Text(tagName)
                                    .font(.system(size: 13))

                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 4)
                            .contentShape(Rectangle())
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedTag == tagName
                                        ? tagColor(for: tagName).opacity(0.2)
                                        : Color.clear)
                            )
                            .onTapGesture {
                                if selectedTag == tagName {
                                    selectedTag = nil
                                } else {
                                    selectedTag = tagName
                                    selectedItem = nil
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Calendar section
            VStack(spacing: 8) {
                CalendarGridView(
                    selectedDate: $selectedDate,
                    dateInfo: calendarDateInfo
                )
                .padding(.horizontal, 12)

                if selectedDate != nil {
                    HStack(spacing: 6) {
                        // Only show filter pills when date has both types
                        if selectedDateHasBothTypes {
                            ForEach(CalendarFilterMode.allCases, id: \.self) { mode in
                                Button(action: { dateFilterMode = mode }) {
                                    Group {
                                        switch mode {
                                        case .all:
                                            Image(systemName: "tray.2")
                                        case .deadline:
                                            Image(systemName: "clock.badge.exclamationmark")
                                                .foregroundStyle(.red, .primary)
                                        case .created:
                                            Image(systemName: "plus.circle")
                                                .foregroundStyle(.green, .primary)
                                        }
                                    }
                                    .font(.system(size: 13))
                                    .frame(width: 28, height: 28)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(dateFilterMode == mode
                                                ? Color.accentColor.opacity(0.15)
                                                : Color.clear)
                                    )
                                }
                                .buttonStyle(.plain)
                                .help(mode.rawValue)
                            }
                        }

                        Spacer()

                        Button(action: { selectedDate = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Clear date filter")
                    }
                    .padding(.horizontal, 12)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Task Manager")
    }

    private var selectedDateHasBothTypes: Bool {
        guard let date = selectedDate else { return false }
        let calendar = Calendar.current
        var hasCreated = false
        var hasDeadline = false
        for task in tasks {
            if let createdAt = task.createdAt, calendar.isDate(createdAt, inSameDayAs: date) {
                hasCreated = true
            }
            if let dueDate = task.dueDate, calendar.isDate(dueDate, inSameDayAs: date) {
                hasDeadline = true
            }
            if hasCreated && hasDeadline { return true }
        }
        return hasCreated && hasDeadline
    }

    private var calendarDateInfo: [Date: CalendarDateInfo] {
        let calendar = Calendar.current
        var info: [Date: CalendarDateInfo] = [:]

        for task in tasks {
            if let createdAt = task.createdAt {
                let day = calendar.startOfDay(for: createdAt)
                let existing = info[day] ?? CalendarDateInfo(hasCreatedTask: false, hasDeadline: false)
                info[day] = CalendarDateInfo(hasCreatedTask: true, hasDeadline: existing.hasDeadline)
            }
            if let dueDate = task.dueDate {
                let day = calendar.startOfDay(for: dueDate)
                let existing = info[day] ?? CalendarDateInfo(hasCreatedTask: false, hasDeadline: false)
                info[day] = CalendarDateInfo(hasCreatedTask: existing.hasCreatedTask, hasDeadline: true)
            }
        }

        return info
    }
}
