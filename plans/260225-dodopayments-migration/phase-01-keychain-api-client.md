# Phase 1: Keychain Helper & DodoPayments API Client

**Status:** ✅ Done  
**Depends on:** Phase 0 (product IDs and API key ready)

## Overview

Build the two foundational service files: a generic Keychain helper for secure local storage and a lightweight HTTP client for the DodoPayments license API.

## New Files

### 1. `Services/KeychainHelper.swift`

**Purpose:** Generic Keychain read/write/delete using the Security framework.

**Stored values:**

| Key                        | Type   | Description                              |
|----------------------------|--------|------------------------------------------|
| `strata.licenseKey`        | String | VIP lifetime license key                 |
| `strata.licenseInstanceId` | String | Instance ID returned from /activate      |
| `strata.customerEmail`     | String | Customer email for subscription lookup   |
| `strata.entitlementStatus` | String | Cached entitlement status (JSON)         |
| `strata.lastValidation`    | String | ISO 8601 timestamp of last validation    |

**Interface:**

```swift
struct KeychainHelper {
    enum Key: String {
        case licenseKey = "strata.licenseKey"
        case licenseInstanceId = "strata.licenseInstanceId"
        case customerEmail = "strata.customerEmail"
        case entitlementStatus = "strata.entitlementStatus"
        case lastValidation = "strata.lastValidation"
    }

    static func save(_ value: String, for key: Key) throws
    static func read(_ key: Key) -> String?
    static func delete(_ key: Key) throws
}
```

**Implementation notes:**

- Use `SecItemAdd`, `SecItemCopyMatching`, `SecItemUpdate`, `SecItemDelete`
- Service name: `"com.kachersoft.strata"`
- Use `kSecClassGenericPassword`
- Handle `errSecDuplicateItem` by updating instead of failing
- No third-party dependencies — Security framework only

---

### 2. `Services/DodoPaymentsClient.swift`

**Purpose:** Simple HTTP client for DodoPayments license endpoints using URLSession.

**Base URLs:**

| Environment | URL                             |
|-------------|---------------------------------|
| Test        | `https://test.dodopayments.com` |
| Live        | `https://live.dodopayments.com` |

**Endpoints (all PUBLIC — no API key needed):**

#### POST `/licenses/activate`

```swift
struct ActivateRequest: Codable {
    let license_key: String
    let name: String  // device identifier, e.g. hostname
}

struct ActivateResponse: Codable {
    let license_key_instance_id: String
    // additional fields as returned
}
```

#### POST `/licenses/validate`

```swift
struct ValidateRequest: Codable {
    let license_key: String
    let license_key_instance_id: String
}

struct ValidateResponse: Codable {
    let valid: Bool
    // additional fields as returned
}
```

#### POST `/licenses/deactivate`

```swift
struct DeactivateRequest: Codable {
    let license_key: String
    let license_key_instance_id: String
}

struct DeactivateResponse: Codable {
    let message: String
    // additional fields as returned
}
```

**Client interface:**

```swift
struct DodoPaymentsClient {
    enum Environment {
        case test, live

        var baseURL: URL { ... }
    }

    let environment: Environment

    func activateLicense(key: String, deviceName: String) async throws -> ActivateResponse
    func validateLicense(key: String, instanceId: String) async throws -> ValidateResponse
    func deactivateLicense(key: String, instanceId: String) async throws -> DeactivateResponse
}
```

**Implementation notes:**

- Use `URLSession.shared.data(for:)` (async/await)
- Set `Content-Type: application/json`
- Use `JSONEncoder`/`JSONDecoder` for serialization
- Throw typed errors for HTTP failures and decoding failures
- Environment toggled via compile flag or config (e.g., `#if DEBUG` → `.test`, else `.live`)
- No API key header for these license endpoints

## Error Handling

```swift
enum DodoPaymentsError: LocalizedError {
    case httpError(statusCode: Int, body: String)
    case decodingError(Error)
    case networkError(Error)
}
```

## No UI Changes

This phase is backend-only. No views are modified or created.

## Validation

- [ ] `KeychainHelper.save` + `KeychainHelper.read` roundtrip works
- [ ] `KeychainHelper.delete` clears value
- [ ] `DodoPaymentsClient.activateLicense` returns instance ID in sandbox
- [ ] `DodoPaymentsClient.validateLicense` returns `valid: true` for active license
- [ ] `DodoPaymentsClient.deactivateLicense` succeeds in sandbox
- [ ] Build succeeds with no warnings
- [ ] No third-party dependencies introduced
