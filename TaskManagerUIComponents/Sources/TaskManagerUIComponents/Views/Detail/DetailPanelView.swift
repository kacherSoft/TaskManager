import SwiftUI

// MARK: - Detail Panel View
public struct DetailPanelView: View {
    let selectedSidebarItem: SidebarItem?
    @Binding var selectedTask: TaskItem?
    let tasks: [TaskItem]
    @Binding var searchText: String
    @Binding var showNewTaskSheet: Bool
    let selectedTag: String?
    let selectedDate: Date?
    let dateFilterMode: CalendarFilterMode
    
    let onToggleComplete: ((TaskItem) -> Void)?
    let onEdit: ((TaskItem, String, String, Date?, Bool, TaskItem.Priority, [String], [URL]) -> Void)?
    let onDelete: ((TaskItem) -> Void)?
    let onPriorityChange: ((TaskItem, TaskItem.Priority) -> Void)?
    let onAddPhotos: ((TaskItem, [URL]) -> Void)?
    let onPickPhotos: ((@escaping ([URL]) -> Void) -> Void)?
    let onDeletePhoto: ((URL) -> Void)?

    public init(
        selectedSidebarItem: SidebarItem?,
        selectedTask: Binding<TaskItem?>,
        tasks: [TaskItem],
        searchText: Binding<String>,
        showNewTaskSheet: Binding<Bool>,
        selectedTag: String? = nil,
        selectedDate: Date? = nil,
        dateFilterMode: CalendarFilterMode = .all
    ) {
        self.selectedSidebarItem = selectedSidebarItem
        self._selectedTask = selectedTask
        self.tasks = tasks
        self._searchText = searchText
        self._showNewTaskSheet = showNewTaskSheet
        self.selectedTag = selectedTag
        self.selectedDate = selectedDate
        self.dateFilterMode = dateFilterMode
        self.onToggleComplete = nil
        self.onEdit = nil
        self.onDelete = nil
        self.onPriorityChange = nil
        self.onAddPhotos = nil
        self.onPickPhotos = nil
        self.onDeletePhoto = nil
    }
    
    public init(
        selectedSidebarItem: SidebarItem?,
        selectedTask: Binding<TaskItem?>,
        tasks: [TaskItem],
        searchText: Binding<String>,
        showNewTaskSheet: Binding<Bool>,
        selectedTag: String? = nil,
        selectedDate: Date? = nil,
        dateFilterMode: CalendarFilterMode = .all,
        onToggleComplete: @escaping (TaskItem) -> Void,
        onEdit: @escaping (TaskItem, String, String, Date?, Bool, TaskItem.Priority, [String], [URL]) -> Void,
        onDelete: @escaping (TaskItem) -> Void,
        onPriorityChange: @escaping (TaskItem, TaskItem.Priority) -> Void,
        onAddPhotos: @escaping (TaskItem, [URL]) -> Void = { _, _ in },
        onPickPhotos: ((@escaping ([URL]) -> Void) -> Void)? = nil,
        onDeletePhoto: ((URL) -> Void)? = nil
    ) {
        self.selectedSidebarItem = selectedSidebarItem
        self._selectedTask = selectedTask
        self.tasks = tasks
        self._searchText = searchText
        self._showNewTaskSheet = showNewTaskSheet
        self.selectedTag = selectedTag
        self.selectedDate = selectedDate
        self.dateFilterMode = dateFilterMode
        self.onToggleComplete = onToggleComplete
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onPriorityChange = onPriorityChange
        self.onAddPhotos = onAddPhotos
        self.onPickPhotos = onPickPhotos
        self.onDeletePhoto = onDeletePhoto
    }

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Header with Search
                HeaderView(
                    title: headerTitle,
                    searchText: $searchText
                )

                // Task List
                if let onToggleComplete, let onEdit, let onDelete, let onPriorityChange, let onAddPhotos {
                    TaskListView(
                        tasks: filteredTasks,
                        selectedTask: $selectedTask,
                        calendarFilterDate: selectedDate,
                        calendarFilterMode: dateFilterMode,
                        onToggleComplete: onToggleComplete,
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onPriorityChange: onPriorityChange,
                        onAddPhotos: onAddPhotos,
                        onPickPhotos: onPickPhotos,
                        onDeletePhoto: onDeletePhoto
                    )
                } else {
                    TaskListView(
                        tasks: filteredTasks,
                        selectedTask: $selectedTask,
                        calendarFilterDate: selectedDate,
                        calendarFilterMode: dateFilterMode
                    )
                }
            }
            .frame(minWidth: 600, minHeight: 400)
            .overlay {
                if filteredTasks.isEmpty && !searchText.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No results found",
                        message: "Try a different search term"
                    )
                } else if filteredTasks.isEmpty {
                    EmptyStateView(
                        icon: "tray",
                        title: "No tasks yet",
                        message: "Create your first task to get started"
                    )
                }
            }

            // Floating Action Button
            FloatingActionButton(icon: "plus") {
                showNewTaskSheet = true
            }
            .padding(24)
        }
    }

    private var headerTitle: String {
        if let tag = selectedTag {
            return "#\(tag)"
        }
        if let date = selectedDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let prefix = dateFilterMode == .all ? "" : "\(dateFilterMode.rawValue): "
            return "\(prefix)\(formatter.string(from: date))"
        }
        return selectedSidebarItem?.title ?? "All Tasks"
    }

    private var filteredTasks: [TaskItem] {
        var result = tasks

        // Filter by tag
        if let tag = selectedTag {
            result = result.filter { $0.tags.contains(tag) }
        }
        // Filter by date
        else if let date = selectedDate {
            let calendar = Calendar.current
            switch dateFilterMode {
            case .all:
                result = result.filter {
                    let matchesDue = $0.dueDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                    let matchesCreated = $0.createdAt.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                    return matchesDue || matchesCreated
                }
            case .deadline:
                result = result.filter {
                    guard let dueDate = $0.dueDate else { return false }
                    return calendar.isDate(dueDate, inSameDayAs: date)
                }
            case .created:
                result = result.filter {
                    guard let createdAt = $0.createdAt else { return false }
                    return calendar.isDate(createdAt, inSameDayAs: date)
                }
            }
        }
        // Filter by sidebar selection
        else if let selectedItem = selectedSidebarItem {
            switch selectedItem {
            case .allTasks: break
            case .today: result = result.filter { $0.isToday }
            case .upcoming: result = result.filter { !$0.isToday && !$0.isCompleted }
            case .inProgress: result = result.filter { $0.isInProgress }
            case .completed: result = result.filter { $0.isCompleted }
            default: break
            }
        }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        return result
    }
}
