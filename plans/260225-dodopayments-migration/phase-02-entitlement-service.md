# Phase 2: EntitlementService (Replaces SubscriptionService)

**Status:** ⬚ Not Started  
**Depends on:** Phase 1 (KeychainHelper + DodoPaymentsClient)

## Overview

Create `EntitlementService` as the single source of truth for premium access. It replicates the same public interface as the existing `SubscriptionService` but uses DodoPayments license validation and Keychain-cached state instead of StoreKit.

## New File

### `Services/EntitlementService.swift`

**Uses `@Observable` (Observation framework) instead of `ObservableObject`** for modern SwiftUI compatibility.

```swift
@Observable
final class EntitlementService {
    // MARK: - Public State
    var isPremium: Bool { hasFullAccess }
    var isVIPPurchased: Bool { isLicenseValid }
    var hasFullAccess: Bool { isLicenseValid || isSubscriptionActive || isVIPAdminGranted }

    // MARK: - Internal State
    private(set) var isLicenseValid: Bool = false
    private(set) var isSubscriptionActive: Bool = false
    var isVIPAdminGranted: Bool = false  // debug toggle

    private(set) var validationState: ValidationState = .idle

    enum ValidationState {
        case idle, validating, valid, invalid, offline
    }

    // MARK: - Dependencies
    private let client: DodoPaymentsClient
    private let offlineGraceDays: Int = 7
}
```

## Core Logic

### License Validation Flow

```
App Launch
  → Load cached entitlement from Keychain (immediate)
  → Background: validate via DodoPayments API
    → Success: update cache + timestamp in Keychain
    → Failure (network): check offline grace period
      → Cache < 7 days old → trust cache (state = .offline)
      → Cache > 7 days old → revoke access (state = .invalid)
```

### Key Methods

```swift
extension EntitlementService {
    /// Called on app launch — loads cache, then validates in background
    func loadAndValidate() async

    /// Activate a new license key
    func activateLicense(key: String) async throws

    /// Deactivate the current license
    func deactivateLicense() async throws

    /// Link a subscription by customer email
    func linkSubscription(email: String) async throws

    /// Force re-validation
    func revalidate() async

    /// Check if a specific feature is accessible
    func canUse(_ feature: PremiumFeature) -> Bool

    /// Human-readable access label
    var accessLabel: String {
        if isLicenseValid { return "VIP Lifetime" }
        if isSubscriptionActive { return "Pro" }
        if isVIPAdminGranted { return "VIP (Admin)" }
        return "Free"
    }
}
```

### Offline Grace Period

```swift
private func isWithinGracePeriod() -> Bool {
    guard let lastValidation = KeychainHelper.read(.lastValidation),
          let date = ISO8601DateFormatter().date(from: lastValidation) else {
        return false
    }
    let daysSince = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? Int.max
    return daysSince <= offlineGraceDays
}
```

## PremiumFeature Enum

Keep existing cases, add `.inlineEnhance`:

```swift
enum PremiumFeature: String, CaseIterable {
    case unlimitedTasks
    case aiSuggestions
    case customThemes
    case inlineEnhance    // NEW
    // ... existing cases
}
```

## Update: PremiumFeatureModifier.swift

**Change `@EnvironmentObject` type from `SubscriptionService` to `EntitlementService`:**

```swift
// BEFORE
@EnvironmentObject var subscriptionService: SubscriptionService

// AFTER
@Environment(EntitlementService.self) var entitlementService
```

Update all references inside the modifier:
- `subscriptionService.canUse(feature)` → `entitlementService.canUse(feature)`
- `subscriptionService.hasFullAccess` → `entitlementService.hasFullAccess`

## Injection Point

In the app's entry point (e.g., `TaskManagerApp.swift`):

```swift
// BEFORE
.environmentObject(subscriptionService)

// AFTER
.environment(entitlementService)
```

## Debug VIP Admin Grant

Preserve the existing debug toggle:
- `isVIPAdminGranted` can be set via debug menu / Settings
- When enabled, `hasFullAccess` returns `true` regardless of license/subscription state
- Gate behind `#if DEBUG` or existing debug flag

## Validation

- [ ] `EntitlementService` compiles with `@Observable`
- [ ] `isPremium`, `isVIPPurchased`, `hasFullAccess` return correct values for all combos
- [ ] `canUse(.inlineEnhance)` is gated correctly
- [ ] Cached license loads immediately on launch (no flash of "Free")
- [ ] Background validation updates state after network call
- [ ] Offline grace period grants access for ≤ 7 days
- [ ] Offline grace period revokes access after > 7 days
- [ ] `PremiumFeatureModifier` works with `EntitlementService`
- [ ] Debug VIP admin grant overrides all checks
- [ ] `.premiumGated()` modifier still functions correctly
- [ ] Build succeeds with no warnings
