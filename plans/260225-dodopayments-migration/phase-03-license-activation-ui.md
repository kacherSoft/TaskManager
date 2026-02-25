# Phase 3: VIP License Key Activation UI

**Status:** ⬚ Not Started  
**Depends on:** Phase 2 (EntitlementService)

## Overview

Build the license key activation flow: a user purchases VIP Lifetime on the website, receives a license key via email, and pastes it into the app to unlock premium features.

## New File

### `Views/Premium/LicenseActivationView.swift`

**UI Layout:**

```
┌──────────────────────────────────────────┐
│  🔑  Activate VIP License               │
│                                          │
│  Enter your license key:                 │
│  ┌────────────────────────────────────┐  │
│  │  XXXX-XXXX-XXXX-XXXX-XXXX-XXXX   │  │
│  └────────────────────────────────────┘  │
│                                          │
│  [ Activate ]                            │
│                                          │
│  Status: ✅ License activated!           │
│                                          │
└──────────────────────────────────────────┘
```

**State management:**

```swift
struct LicenseActivationView: View {
    @Environment(EntitlementService.self) var entitlementService
    @State private var licenseKey: String = ""
    @State private var activationState: ActivationState = .idle

    enum ActivationState {
        case idle
        case activating
        case success
        case error(String)
    }
}
```

**Behavior:**

- Text field: monospaced font, `.textContentType(.none)`, paste-friendly
- "Activate" button:
  - Disabled while `licenseKey` is empty or `activationState == .activating`
  - On tap: call `entitlementService.activateLicense(key:)`
  - Show progress indicator during activation
- Success: show green checkmark + "License activated!" message
- Error: show red error message with description (e.g., "Invalid license key", "Activation limit reached")
- Dismiss view after short delay on success

## Modify: PremiumUpsellView

Add two new elements to the existing upsell view:

### "I have a license key" Button

```swift
Button("I have a license key") {
    showLicenseActivation = true
}
.sheet(isPresented: $showLicenseActivation) {
    LicenseActivationView()
}
```

- Style: secondary/text button, positioned below the main CTA
- Opens `LicenseActivationView` as a sheet

### "Buy VIP Lifetime" Button

```swift
Button("Buy VIP Lifetime — $99.99") {
    if let url = URL(string: "https://dodopayments.com/checkout/PRODUCT_ID_HERE") {
        NSWorkspace.shared.open(url)
    }
}
```

- Style: prominent button matching existing design
- Opens DodoPayments checkout URL in default browser
- Use the VIP Lifetime product ID from Phase 0

## Checkout URL Format

```
https://checkout.dodopayments.com/buy/PRODUCT_ID
```

- Replace `PRODUCT_ID` with the actual VIP Lifetime product ID
- In test mode, use the sandbox checkout URL

## User Flow

```
User taps "Buy VIP Lifetime"
  → Browser opens DodoPayments checkout
  → User completes purchase
  → DodoPayments sends license key via email
  → User returns to Strata app
  → User taps "I have a license key"
  → LicenseActivationView opens
  → User pastes license key
  → User taps "Activate"
  → App calls POST /licenses/activate
  → License key + instance ID stored in Keychain
  → EntitlementService updates → hasFullAccess = true
  → Premium features unlocked
```

## Edge Cases

- [ ] User pastes key with leading/trailing whitespace → trim before activating
- [ ] Invalid key format → show clear error
- [ ] Activation limit reached → show "This key has reached its activation limit (3 devices)"
- [ ] Network error → show "Could not connect. Check your internet and try again."
- [ ] User cancels during activation → no partial state saved

## Validation

- [ ] LicenseActivationView renders correctly
- [ ] License key text field accepts paste
- [ ] Activate button is disabled when field is empty
- [ ] Spinner shows during activation
- [ ] Success state displays correctly
- [ ] Error messages display correctly for each error type
- [ ] "I have a license key" button appears in PremiumUpsellView
- [ ] "Buy VIP Lifetime" button opens correct URL in browser
- [ ] After successful activation, premium features are immediately accessible
- [ ] Build succeeds with no warnings
