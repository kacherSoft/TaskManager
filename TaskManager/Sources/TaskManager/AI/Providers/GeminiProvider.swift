import Foundation
import GoogleGenerativeAI

final class GeminiProvider: AIProviderProtocol, @unchecked Sendable {
    var name: String { "Google Gemini" }
    
    private let keychain = KeychainService.shared
    private let defaultModel = "gemini-flash-lite-latest"
    
    var isConfigured: Bool {
        keychain.hasKey(.geminiAPIKey)
    }
    
    func enhance(text: String, mode: AIModeData) async throws -> AIEnhancementResult {
        guard let apiKey = keychain.get(.geminiAPIKey) else {
            throw AIError.notConfigured
        }
        
        let startTime = Date()
        let modelName = mode.modelName.isEmpty ? defaultModel : mode.modelName
        let model = GenerativeModel(name: modelName, apiKey: apiKey)
        
        let prompt = """
        \(mode.systemPrompt)
        
        Text to process:
        \(text)
        """
        
        do {
            let response = try await model.generateContent(prompt)
            
            guard let enhancedText = response.text else {
                throw AIError.invalidResponse
            }
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            return AIEnhancementResult(
                originalText: text,
                enhancedText: enhancedText.trimmingCharacters(in: .whitespacesAndNewlines),
                modeName: mode.name,
                provider: "\(name) (\(modelName))",
                tokensUsed: nil,
                processingTime: processingTime
            )
        } catch let error as GenerateContentError {
            throw mapGeminiError(error)
        } catch {
            throw AIError.networkError(error.localizedDescription)
        }
    }
    
    func testConnection() async throws -> Bool {
        guard let apiKey = keychain.get(.geminiAPIKey) else {
            throw AIError.notConfigured
        }
        
        let model = GenerativeModel(name: defaultModel, apiKey: apiKey)
        
        do {
            _ = try await model.generateContent("Say hello")
            return true
        } catch let error as GenerateContentError {
            throw mapGeminiError(error)
        } catch {
            throw AIError.networkError(error.localizedDescription)
        }
    }
    
    private func mapGeminiError(_ error: GenerateContentError) -> AIError {
        switch error {
        case .promptBlocked(let response):
            if let feedback = response.promptFeedback {
                return AIError.providerError("Content blocked: \(feedback.blockReason?.rawValue ?? "safety")")
            }
            return AIError.providerError("Content was blocked by safety filters")
        case .responseStoppedEarly(let reason, _):
            return AIError.providerError("Response stopped: \(reason.rawValue)")
        case .invalidAPIKey:
            return AIError.invalidAPIKey
        case .unsupportedUserLocation:
            return AIError.providerError("Gemini is not available in your region")
        default:
            return AIError.providerError("Gemini error: \(error.localizedDescription)")
        }
    }
}
