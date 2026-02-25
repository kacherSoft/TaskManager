# Phase 5: License Management in Settings

**Status:** ⬚ Not Started  
**Depends on:** Phase 3 (License Activation), Phase 4 (Subscription Linking)

## Overview

Add license and subscription management UI to GeneralSettingsView, allowing users to view their current plan, deactivate licenses, manage subscriptions, and re-validate entitlements.

## Modify: GeneralSettingsView

Add a **"Subscription & License"** section to the existing settings view.

### UI Layout

```
┌──────────────────────────────────────────────┐
│  Subscription & License                      │
│                                              │
│  Current Plan:    VIP Lifetime  ✅           │
│  License Key:     XXXX-XXXX-...-3f43         │
│  Last Validated:  Feb 25, 2026, 10:32 AM     │
│                                              │
│  [ Deactivate License ]  [ Re-validate ]     │
│                                              │
│  [ Manage Subscription ↗ ]                   │
│                                              │
└──────────────────────────────────────────────┘
```

### Conditional Display

| State | Shows |
|-------|-------|
| **Free** | Current Plan: Free. "Upgrade to Pro" button |
| **Pro (subscription)** | Current Plan: Pro. Email used. "Manage Subscription" link. "Re-validate" button |
| **VIP (license)** | Current Plan: VIP Lifetime. Masked license key. "Deactivate" + "Re-validate" buttons |
| **VIP (admin grant)** | Current Plan: VIP (Admin). Debug indicator |

### Section Implementation

```swift
Section("Subscription & License") {
    // Current plan
    LabeledContent("Current Plan") {
        HStack {
            Text(entitlementService.accessLabel)
            if entitlementService.hasFullAccess {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }

    // License key (VIP only)
    if entitlementService.isLicenseValid,
       let key = KeychainHelper.read(.licenseKey) {
        LabeledContent("License Key") {
            Text(maskedKey(key))
                .font(.system(.body, design: .monospaced))
        }
    }

    // Linked email (subscription only)
    if entitlementService.isSubscriptionActive,
       let email = KeychainHelper.read(.customerEmail) {
        LabeledContent("Linked Email") {
            Text(email)
        }
    }

    // Last validated
    if let timestamp = KeychainHelper.read(.lastValidation) {
        LabeledContent("Last Validated") {
            Text(formattedDate(timestamp))
        }
    }

    // Actions
    if entitlementService.isLicenseValid {
        Button("Deactivate License", role: .destructive) {
            showDeactivateConfirmation = true
        }
    }

    if entitlementService.isSubscriptionActive {
        Button("Manage Subscription") {
            NSWorkspace.shared.open(customerPortalURL)
        }
    }

    Button("Re-validate") {
        Task { await entitlementService.revalidate() }
    }
    .disabled(entitlementService.validationState == .validating)
}
```

### License Key Masking

```swift
func maskedKey(_ key: String) -> String {
    guard key.count > 4 else { return key }
    let suffix = String(key.suffix(4))
    return "XXXX-XXXX-...-\(suffix)"
}
```

## Deactivation Flow

```
User taps "Deactivate License"
  → Confirmation alert: "Are you sure? This will free up one activation slot."
  → User confirms
  → App calls POST /licenses/deactivate
    → license_key from Keychain
    → license_key_instance_id from Keychain
  → On success:
    → Clear licenseKey from Keychain
    → Clear licenseInstanceId from Keychain
    → Clear entitlementStatus from Keychain
    → Clear lastValidation from Keychain
    → EntitlementService updates: isLicenseValid = false
    → UI reverts to Free tier
  → On failure:
    → Show error alert
    → Do NOT clear local state (keep license active locally)
```

### Confirmation Alert

```swift
.alert("Deactivate License?", isPresented: $showDeactivateConfirmation) {
    Button("Cancel", role: .cancel) {}
    Button("Deactivate", role: .destructive) {
        Task {
            do {
                try await entitlementService.deactivateLicense()
            } catch {
                deactivationError = error.localizedDescription
                showDeactivationError = true
            }
        }
    }
} message: {
    Text("This will deactivate your license on this device. You can reactivate later if activation slots are available.")
}
```

## Customer Portal URL

```swift
// DodoPayments customer portal for subscription management
let customerPortalURL = URL(string: "https://dodopayments.com/portal")!
```

- Opens in default browser via `NSWorkspace.shared.open()`
- User can cancel/change subscription through DodoPayments portal

## Edge Cases

- [ ] Deactivation fails (network) → show error, keep local state intact
- [ ] Re-validate while offline → show "Offline — using cached status"
- [ ] No license and no subscription → show "Free" with upgrade prompt
- [ ] Admin grant active → show "VIP (Admin)" with debug indicator
- [ ] License key in Keychain but validation fails → show warning, offer re-activation

## Validation

- [ ] Settings section shows correct plan for Free, Pro, VIP, Admin states
- [ ] License key is masked correctly (only last 4 chars visible)
- [ ] "Deactivate License" shows confirmation alert
- [ ] Successful deactivation clears Keychain and reverts to Free
- [ ] Failed deactivation shows error and preserves local state
- [ ] "Manage Subscription" opens correct URL in browser
- [ ] "Re-validate" triggers background validation and updates UI
- [ ] Last validated timestamp displays correctly
- [ ] Build succeeds with no warnings
