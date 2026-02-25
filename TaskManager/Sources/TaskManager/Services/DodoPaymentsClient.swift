import Foundation

struct DodoPaymentsClient {
    
    enum Environment {
        case test
        case live
        
        var baseURL: URL {
            switch self {
            case .test: URL(string: "https://test.dodopayments.com")!
            case .live: URL(string: "https://live.dodopayments.com")!
            }
        }
    }
    
    static let shared = DodoPaymentsClient()
    
    let environment: Environment
    
    init(environment: Environment? = nil) {
        #if DEBUG
        self.environment = environment ?? .test
        #else
        self.environment = environment ?? .live
        #endif
    }
    
    // MARK: - License Activation
    
    func activateLicense(key: String, deviceName: String) async throws -> ActivateResponse {
        let body = ActivateRequest(license_key: key, name: deviceName)
        return try await post("/licenses/activate", body: body)
    }
    
    // MARK: - License Validation
    
    func validateLicense(key: String, instanceId: String? = nil) async throws -> ValidateResponse {
        let body = ValidateRequest(license_key: key, license_key_instance_id: instanceId)
        return try await post("/licenses/validate", body: body)
    }
    
    // MARK: - License Deactivation
    
    func deactivateLicense(key: String, instanceId: String) async throws -> DeactivateResponse {
        let body = DeactivateRequest(license_key: key, license_key_instance_id: instanceId)
        return try await post("/licenses/deactivate", body: body)
    }
    
    // MARK: - Private
    
    private func post<T: Encodable, R: Decodable>(_ path: String, body: T) async throws -> R {
        let url = environment.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DodoPaymentsError.networkError(
                URLError(.badServerResponse)
            )
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw DodoPaymentsError.httpError(
                statusCode: httpResponse.statusCode,
                body: body
            )
        }
        
        do {
            return try JSONDecoder().decode(R.self, from: data)
        } catch {
            throw DodoPaymentsError.decodingError(error)
        }
    }
}

// MARK: - Request / Response Types

struct ActivateRequest: Encodable {
    let license_key: String
    let name: String
}

struct ActivateResponse: Decodable {
    let license_key_instance_id: String
}

struct ValidateRequest: Encodable {
    let license_key: String
    let license_key_instance_id: String?
}

struct ValidateResponse: Decodable {
    let valid: Bool
}

struct DeactivateRequest: Encodable {
    let license_key: String
    let license_key_instance_id: String
}

struct DeactivateResponse: Decodable {
    // DodoPayments returns 200 on success; body may vary
}

// MARK: - Errors

enum DodoPaymentsError: LocalizedError {
    case httpError(statusCode: Int, body: String)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .httpError(let code, let body):
            return "HTTP \(code): \(body)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
