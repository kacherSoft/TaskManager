import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class AIService {
    static let shared = AIService()
    
    private(set) var currentMode: AIModeModel?
    private(set) var isProcessing = false
    private(set) var lastError: AIError?
    
    private let geminiProvider = GeminiProvider()
    private let zaiProvider = ZAIProvider()
    
    private init() {}
    
    func providerFor(_ type: AIProviderType) -> AIProviderProtocol {
        switch type {
        case .gemini: return geminiProvider
        case .zai: return zaiProvider
        }
    }
    
    func isConfigured(for provider: AIProviderType) -> Bool {
        providerFor(provider).isConfigured
    }
    
    var hasAnyProviderConfigured: Bool {
        geminiProvider.isConfigured || zaiProvider.isConfigured
    }
    
    func setMode(_ mode: AIModeModel) {
        currentMode = mode
    }
    
    func cycleMode(in context: ModelContext) {
        let descriptor = FetchDescriptor<AIModeModel>(sortBy: [SortDescriptor(\.sortOrder)])
        guard let modes = try? context.fetch(descriptor), !modes.isEmpty else { return }
        
        if let current = currentMode,
           let currentIndex = modes.firstIndex(where: { $0.id == current.id }) {
            let nextIndex = (currentIndex + 1) % modes.count
            currentMode = modes[nextIndex]
        } else {
            currentMode = modes.first
        }
    }
    
    func loadDefaultMode(from context: ModelContext) {
        guard currentMode == nil else { return }
        
        let descriptor = FetchDescriptor<AIModeModel>(sortBy: [SortDescriptor(\.sortOrder)])
        if let modes = try? context.fetch(descriptor), let first = modes.first {
            currentMode = first
        }
    }
    
    func enhance(text: String, mode: AIModeModel) async throws -> AIEnhancementResult {
        let modeData = AIModeData(from: mode)
        let provider = providerFor(modeData.provider)
        
        guard provider.isConfigured else {
            throw AIError.notConfigured
        }
        
        isProcessing = true
        lastError = nil
        
        defer { isProcessing = false }
        
        do {
            let result = try await provider.enhance(text: text, mode: modeData)
            return result
        } catch let error as AIError {
            lastError = error
            throw error
        } catch {
            let aiError = AIError.networkError(error.localizedDescription)
            lastError = aiError
            throw aiError
        }
    }
    
    func testProvider(_ type: AIProviderType) async throws -> Bool {
        try await providerFor(type).testConnection()
    }
}
