import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    // Global shortcuts (work system-wide)
    static let quickEntry = Self("quickEntry")
    static let enhanceMe = Self("enhanceMe")
    static let mainWindow = Self("mainWindow")
    
    // Local shortcuts (work only when app is focused)
    static let settings = Self("settings")
    static let newTask = Self("newTask")
}
