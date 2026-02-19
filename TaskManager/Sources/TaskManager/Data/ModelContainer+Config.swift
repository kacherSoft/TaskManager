import SwiftData
import Foundation

extension ModelContainer {
    static var appSchema: Schema {
        Schema([
            TaskModel.self,
            AIModeModel.self,
            SettingsModel.self,
            CustomFieldDefinitionModel.self,
            CustomFieldValueModel.self
        ])
    }

    static func configured() throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: appSchema,
            isStoredInMemoryOnly: false
        )

        return try ModelContainer(for: appSchema, configurations: [config])
    }

    static func inMemoryFallback() throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: appSchema,
            isStoredInMemoryOnly: true
        )

        return try ModelContainer(for: appSchema, configurations: [config])
    }
}

@MainActor
func seedDefaultData(container: ModelContainer) throws {
    let context = ModelContext(container)

    try seedDefaultAIModes(context: context)
    try removeDeprecatedBuiltInModesIfNeeded(context: context)
    try seedExplainModeIfNeeded(context: context)
    try seedDefaultSettings(context: context)
    try seedDefaultCustomFieldDefinitions(context: context)
    try migrateExistingCustomFieldValues(context: context)

    try context.save()
}

@MainActor
private func seedDefaultAIModes(context: ModelContext) throws {
    let descriptor = FetchDescriptor<AIModeModel>()
    guard try context.fetchCount(descriptor) == 0 else { return }

    for (index, mode) in AIModeModel.createDefaultModes().enumerated() {
        mode.sortOrder = index
        context.insert(mode)
    }
}

@MainActor
private func removeDeprecatedBuiltInModesIfNeeded(context: ModelContext) throws {
    let modesToRemove: Set<String> = ["Simplify", "Break Down"]
    let builtInModes = try context.fetch(FetchDescriptor<AIModeModel>(predicate: #Predicate { $0.isBuiltIn }))
    for mode in builtInModes where modesToRemove.contains(mode.name) {
        context.delete(mode)
    }
}

@MainActor
private func seedExplainModeIfNeeded(context: ModelContext) throws {
    let descriptor = FetchDescriptor<AIModeModel>(
        predicate: #Predicate { $0.isBuiltIn && $0.name == "Explain" }
    )
    let explainModes = try context.fetch(descriptor)

    if let explainMode = explainModes.first {
        if !explainMode.supportsAttachments {
            explainMode.supportsAttachments = true
        }
        return
    }

    let allModes = try context.fetch(FetchDescriptor<AIModeModel>())
    let maxOrder = allModes.map(\.sortOrder).max() ?? -1

    let explainMode = AIModeModel(
        name: "Explain",
        systemPrompt: "You are an expert explainer. If an image or document is attached, analyze and explain it clearly and concisely. Otherwise, analyze the provided text. Break down complex concepts into understandable language. Only output the explanation, nothing else.",
        provider: .gemini,
        isBuiltIn: true,
        supportsAttachments: true
    )
    explainMode.sortOrder = maxOrder + 1
    context.insert(explainMode)
}

@MainActor
private func seedDefaultSettings(context: ModelContext) throws {
    let descriptor = FetchDescriptor<SettingsModel>()
    guard try context.fetchCount(descriptor) == 0 else { return }

    let settings = SettingsModel()
    context.insert(settings)
}

@MainActor
private func seedDefaultCustomFieldDefinitions(context: ModelContext) throws {
    let descriptor = FetchDescriptor<CustomFieldDefinitionModel>()
    guard try context.fetchCount(descriptor) == 0 else { return }

    let defaults: [(String, CustomFieldValueType, Int)] = [
        ("Budget", .currency, 0),
        ("Client", .text, 1),
        ("Effort", .number, 2)
    ]
    for (name, valueType, order) in defaults {
        let definition = CustomFieldDefinitionModel(name: name, valueType: valueType, isActive: true, sortOrder: order)
        context.insert(definition)
    }
}

@MainActor
private func migrateExistingCustomFieldValues(context: ModelContext) throws {
    // One-time migration: convert legacy budget/client/effort to CustomFieldValueModel rows
    let definitions = try context.fetch(FetchDescriptor<CustomFieldDefinitionModel>())
    guard !definitions.isEmpty else { return }

    let budgetDef = definitions.first { $0.name == "Budget" && $0.valueType == .currency }
    let clientDef = definitions.first { $0.name == "Client" && $0.valueType == .text }
    let effortDef = definitions.first { $0.name == "Effort" && $0.valueType == .number }

    let existingValues = try context.fetch(FetchDescriptor<CustomFieldValueModel>())
    guard existingValues.isEmpty else { return } // already migrated

    let tasks = try context.fetch(FetchDescriptor<TaskModel>())
    for task in tasks {
        if let budget = task.budget, let def = budgetDef {
            let value = CustomFieldValueModel(definitionId: def.id, taskId: task.id, decimalValue: budget)
            context.insert(value)
        }
        if let client = task.client, !client.isEmpty, let def = clientDef {
            let value = CustomFieldValueModel(definitionId: def.id, taskId: task.id, stringValue: client)
            context.insert(value)
        }
        if let effort = task.effort, let def = effortDef {
            let value = CustomFieldValueModel(definitionId: def.id, taskId: task.id, numberValue: effort)
            context.insert(value)
        }
    }
}
