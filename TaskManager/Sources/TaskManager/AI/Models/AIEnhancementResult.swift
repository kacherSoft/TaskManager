import Foundation

struct AIEnhancementResult: Sendable {
    let originalText: String
    let enhancedText: String
    let modeName: String
    let provider: String
    let tokensUsed: Int?
    let processingTime: TimeInterval
}

struct AIModeData: Sendable {
    let name: String
    let systemPrompt: String
    let provider: AIProviderType
    let modelName: String
    
    init(from mode: AIModeModel) {
        self.name = mode.name
        self.systemPrompt = mode.systemPrompt
        self.provider = mode.provider
        self.modelName = mode.modelName
    }
}
