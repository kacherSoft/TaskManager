import SwiftUI
import SwiftData
import AppKit
import TaskManagerUIComponents
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    var modelContainer: ModelContainer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // Apply saved settings on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.applySettingsOnLaunch()
        }
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Don't force window to front here - let WindowManager handle it
        // This prevents fighting with moveToActiveSpace behavior
    }
    
    @MainActor
    private func applySettingsOnLaunch() {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        
        do {
            let descriptor = FetchDescriptor<SettingsModel>()
            if let settings = try context.fetch(descriptor).first {
                WindowManager.shared.setAlwaysOnTop(settings.alwaysOnTop)
            }
        } catch {
            print("Failed to load settings: \(error)")
        }
    }
}

@main
struct TaskManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let container: ModelContainer
    private let menuBarController: MenuBarController
    
    init() {
        do {
            container = try ModelContainer.configured()
            WindowManager.shared.configure(modelContainer: container)
            seedDefaultData(container: container)
        } catch {
            fatalError("Failed to configure SwiftData: \(error)")
        }
        
        // Initialize menu bar
        menuBarController = MenuBarController()
        
        // Initialize shortcut manager (registers shortcuts)
        ShortcutManager.shared.configure(modelContainer: container)
        
        // Pass container to app delegate for settings (after all inits)
        appDelegate.modelContainer = container
    }
    
    var body: some Scene {
        WindowGroup("Task Manager", id: "main-window") {
            ContentView()
        }
        .modelContainer(container)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1000, height: 700)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Query(sort: \TaskModel.createdAt, order: .reverse) private var taskModels: [TaskModel]
    @Query private var settings: [SettingsModel]
    
    @State private var selectedSidebarItem: SidebarItem? = .allTasks
    @State private var selectedTask: TaskItem?
    @State private var showNewTaskSheet = false
    @State private var searchText = ""
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var selectedTag: String?
    @State private var selectedDate: Date?
    @State private var dateFilterMode: CalendarFilterMode = .all
    @State private var selectedPriority: TaskItem.Priority?

    private var currentSettings: SettingsModel? { settings.first }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                selectedItem: $selectedSidebarItem,
                tags: allTags,
                selectedTag: $selectedTag,
                selectedDate: $selectedDate,
                dateFilterMode: $dateFilterMode,
                selectedPriority: $selectedPriority,
                tasks: taskItems
            )
            .frame(minWidth: 220, idealWidth: 260)
            .onChange(of: selectedTag) { _, newValue in
                if newValue != nil {
                    selectedSidebarItem = nil
                    selectedDate = nil
                    selectedPriority = nil
                }
            }
            .onChange(of: selectedDate) { _, newValue in
                dateFilterMode = .all
                if newValue != nil {
                    selectedSidebarItem = nil
                    selectedTag = nil
                    selectedPriority = nil
                }
            }
            .onChange(of: selectedSidebarItem) { _, newValue in
                if newValue != nil {
                    selectedTag = nil
                    selectedDate = nil
                    selectedPriority = nil
                }
            }
            .onChange(of: selectedPriority) { _, newValue in
                if newValue != nil {
                    selectedSidebarItem = nil
                    selectedTag = nil
                    selectedDate = nil
                }
            }
        } detail: {
            DetailPanelView(
                selectedSidebarItem: selectedSidebarItem,
                selectedTask: $selectedTask,
                tasks: taskItems,
                searchText: $searchText,
                showNewTaskSheet: $showNewTaskSheet,
                selectedTag: selectedTag,
                selectedDate: selectedDate,
                dateFilterMode: dateFilterMode,
                selectedPriority: selectedPriority,
                onToggleComplete: { taskItem in
                    toggleComplete(taskItem: taskItem)
                },
                onEdit: { taskItem, title, notes, dueDate, hasReminder, duration, priority, tags, photos in
                    updateTask(taskItem: taskItem, title: title, notes: notes, dueDate: dueDate, hasReminder: hasReminder, reminderDuration: duration, priority: priority, tags: tags, photos: photos)
                },
                onDelete: { taskItem in
                    deleteTask(taskItem: taskItem)
                },
                onPriorityChange: { taskItem, priority in
                    updatePriority(taskItem: taskItem, priority: priority)
                },
                onAddPhotos: { taskItem, urls in
                    addPhotos(taskItem: taskItem, urls: urls)
                },
                onPickPhotos: { completion in
                    PhotoStorageService.shared.pickPhotos(completion: completion)
                },
                onDeletePhoto: { url in
                    PhotoStorageService.shared.deletePhoto(at: url.path)
                },
                onSetReminder: { taskItem in
                    toggleReminder(taskItem: taskItem)
                }
            )
        }
        .navigationSplitViewStyle(.balanced)
        .background(WindowActivator())
        .sheet(isPresented: $showNewTaskSheet) {
            NewTaskSheet(
                isPresented: $showNewTaskSheet,
                onPickPhotos: { completion in
                    PhotoStorageService.shared.pickPhotos(completion: completion)
                }
            ) { title, notes, dueDate, hasReminder, duration, priority, tags, photos in
                createTask(
                    title: title,
                    notes: notes,
                    dueDate: dueDate,
                    hasReminder: hasReminder,
                    reminderDuration: duration,
                    priority: priority,
                    tags: tags,
                    photos: photos
                )
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .onAppear {
            WindowManager.shared.openWindowAction = openWindow
        }
        .onReceive(NotificationCenter.default.publisher(for: .showNewTaskSheet)) { _ in
            showNewTaskSheet = true
        }
    }
    
    private var taskItems: [TaskItem] {
        taskModels.map { $0.toTaskItem() }
    }
    
    private var allTags: [String] {
        Array(Set(taskModels.flatMap { $0.tags })).sorted()
    }
    
    private func createTask(
        title: String,
        notes: String,
        dueDate: Date?,
        hasReminder: Bool,
        reminderDuration: TimeInterval = 1800,
        priority: TaskItem.Priority,
        tags: [String],
        photos: [URL] = []
    ) {
        let storedPaths = photos.isEmpty ? [] : PhotoStorageService.shared.storePhotos(photos)
        let task = TaskModel(
            title: title,
            taskDescription: notes,
            dueDate: dueDate,
            reminderDuration: reminderDuration,
            priority: TaskPriority.from(priority),
            tags: tags,
            hasReminder: hasReminder,
            photos: storedPaths
        )
        modelContext.insert(task)
        try? modelContext.save()
    }
    
    private func findTaskModel(for taskItem: TaskItem) -> TaskModel? {
        taskModels.first { $0.id == taskItem.id }
    }
    
    private func toggleComplete(taskItem: TaskItem) {
        guard let task = findTaskModel(for: taskItem) else { return }
        task.cycleStatus()
        try? modelContext.save()
    }
    
    private func updateStatus(taskItem: TaskItem, status: TaskItem.Status) {
        guard let task = findTaskModel(for: taskItem) else { return }
        task.setStatus(TaskStatus.from(status))
        try? modelContext.save()
    }
    
    private func updateTask(
        taskItem: TaskItem,
        title: String,
        notes: String,
        dueDate: Date?,
        hasReminder: Bool,
        reminderDuration: TimeInterval = 1800,
        priority: TaskItem.Priority,
        tags: [String],
        photos: [URL] = []
    ) {
        guard let task = findTaskModel(for: taskItem) else { return }
        task.title = title
        task.taskDescription = notes
        task.dueDate = dueDate
        task.hasReminder = hasReminder
        task.reminderDuration = reminderDuration
        task.priority = TaskPriority.from(priority)
        task.tags = tags
        task.photos = PhotoStorageService.shared.normalizeToStoredPaths(photos)
        task.touch()
        try? modelContext.save()
    }
    
    private func deleteTask(taskItem: TaskItem) {
        guard let task = findTaskModel(for: taskItem) else { return }
        NotificationService.shared.cancelReminder(for: task.id)
        modelContext.delete(task)
        try? modelContext.save()
        selectedTask = nil
    }
    
    private func updatePriority(taskItem: TaskItem, priority: TaskItem.Priority) {
        guard let task = findTaskModel(for: taskItem) else { return }
        task.priority = TaskPriority.from(priority)
        task.touch()
        try? modelContext.save()
    }
    
    private func toggleReminder(taskItem: TaskItem) {
        guard let task = findTaskModel(for: taskItem) else { return }
        
        if let fireDate = task.reminderFireDate, fireDate > Date() {
            // Cancel active reminder
            NotificationService.shared.cancelReminder(for: task.id)
            task.reminderFireDate = nil
        } else {
            // Start reminder timer
            let soundId = currentSettings?.reminderSoundId ?? "default"
            task.reminderFireDate = Date().addingTimeInterval(task.reminderDuration)
            NotificationService.shared.scheduleTimerReminder(
                for: task.id,
                title: task.title,
                duration: task.reminderDuration,
                soundId: soundId
            )
        }
        task.touch()
        try? modelContext.save()
    }
    
    private func addPhotos(taskItem: TaskItem, urls: [URL]) {
        guard let task = findTaskModel(for: taskItem) else { return }
        
        if urls.isEmpty {
            PhotoStorageService.shared.pickPhotos { pickedURLs in
                Task { @MainActor in
                    guard !pickedURLs.isEmpty else { return }
                    let storedPaths = PhotoStorageService.shared.storePhotos(pickedURLs)
                    task.photos.append(contentsOf: storedPaths)
                    task.touch()
                    try? self.modelContext.save()
                }
            }
        } else {
            let storedPaths = PhotoStorageService.shared.storePhotos(urls)
            task.photos.append(contentsOf: storedPaths)
            task.touch()
            try? modelContext.save()
        }
    }
}

