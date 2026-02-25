# DodoPayments Migration Plan

> **Project:** Strata — Personal AI Task Manager
> **Date:** 2026-02-25
> **Goal:** Replace StoreKit with DodoPayments for Developer ID distribution
> **Phases:** 7

---

## Overview

Migrate Strata's payment system from Apple StoreKit 2 (App Store IAP) to DodoPayments (external MoR). This enables the Developer ID-only distribution model with full control over pricing, licensing, and entitlements.

### Key Architecture Decisions

1. **VIP Lifetime** → DodoPayments one-time payment + **license key** (stored in Keychain)
2. **Pro Subscription** → DodoPayments subscription + **customer ID** (stored in Keychain)
3. **License validation is PUBLIC** — no API key needed in the app (activate/deactivate/validate endpoints are unauthenticated)
4. **Offline grace period** — cache entitlement status locally, re-validate periodically
5. **No backend required initially** — app talks directly to DodoPayments API for validation; webhooks can be added later via Cloudflare Workers

### Purchase Flow

```
User clicks "Upgrade" in app
        │
        ▼
App opens DodoPayments checkout URL in browser
        │
        ▼
User completes payment on dodopayments.com
        │
        ├─ Subscription → DodoPayments creates subscription
        │                  User enters customer email in app to link
        │
        └─ VIP Lifetime → DodoPayments issues license key
                          User pastes license key in app to activate
        │
        ▼
App validates via DodoPayments public API
        │
        ▼
Entitlement granted, cached in Keychain
```

---

## Files Affected

### Modified
| File | Changes |
|------|---------|
| `Services/SubscriptionService.swift` | Complete rewrite → `EntitlementService.swift` |
| `Views/Premium/PremiumUpsellView.swift` | Replace StoreKit purchase buttons with checkout links + license key input |
| `Views/Premium/PremiumFeatureModifier.swift` | Update to use new `EntitlementService` |
| `Views/Settings/GeneralSettingsView.swift` | Add license management section |
| `Extensions/UserDefaults+Constants.swift` | Add entitlement cache keys |

### New
| File | Purpose |
|------|---------|
| `Services/DodoPaymentsClient.swift` | HTTP client for DodoPayments public API |
| `Services/EntitlementService.swift` | New unified entitlement manager (replaces SubscriptionService) |
| `Services/KeychainHelper.swift` | Secure storage for license keys and customer IDs |
| `Views/Premium/LicenseActivationView.swift` | UI for entering/activating license keys |
| `Views/Premium/SubscriptionLinkView.swift` | UI for linking subscription via email |

### Removed
| File | Reason |
|------|--------|
| `Services/SubscriptionService.swift` | Replaced by EntitlementService |
| `Configuration.storekit` | No longer using StoreKit |

---

## Phases

| # | Phase | Description | Status |
|---|-------|-------------|--------|
| 0 | DodoPayments Account Setup | Create account, configure products | ⬚ |
| 1 | Keychain & API Client | KeychainHelper + DodoPaymentsClient | ⬚ |
| 2 | EntitlementService | Core entitlement logic replacing SubscriptionService | ⬚ |
| 3 | License Activation UI | VIP lifetime purchase + license key entry | ⬚ |
| 4 | Subscription Linking UI | Pro subscription + email-based linking | ⬚ |
| 5 | Settings & Management | License management in Settings, restore flow | ⬚ |
| 6 | Cleanup & Testing | Remove StoreKit, update docs, end-to-end testing | ⬚ |

---

## Product Configuration (DodoPayments Dashboard)

Create these products in DodoPayments:

| Product | Type | Price | License Key | Product ID |
|---------|------|-------|-------------|------------|
| **Strata Pro Monthly** | Subscription | $4.99/mo | No | `pdt_0NZEvu9tI0aecVEYkmxOH` |
| **Strata Pro Yearly** | Subscription | $39.99/yr | No | `pdt_0NZEzxFzK5RRekOJXQHpZ` |
| **Strata VIP Lifetime** | One-time | $99.99 | Yes (no expiry, 3 activations) | `pdt_0NZEzLgAEu8PcrUBqi8mt` |

---

## Entitlement Logic

```swift
// New EntitlementService.hasFullAccess
var hasFullAccess: Bool {
    isLicenseValid       // VIP lifetime (license key validated)
    || isSubscriptionActive  // Pro subscription (checked via API)
    || isVIPAdminGranted     // Debug override
}
```

### Offline Strategy
- Cache last validation result + timestamp in Keychain
- Grace period: **7 days** offline before requiring re-validation
- On app launch: check cache first, validate in background if online
- If cache expired and offline: still grant access but show "verify connection" badge

---

## API Endpoints Used (all public, no API key)

| Action | Method | Endpoint |
|--------|--------|----------|
| Activate license | POST | `/licenses/activate` |
| Validate license | POST | `/licenses/validate` |
| Deactivate license | POST | `/licenses/deactivate` |

For subscription status: use customer lookup via API key (stored server-side or embedded securely).

> **Note:** Subscription status check requires an API key. Options:
> 1. Lightweight Cloudflare Worker proxy (recommended)
> 2. Embed read-only API key in app (acceptable for read-only queries)
> 3. Use webhooks to push status to a simple DB

---

## Validation Checklist

- [ ] VIP: Purchase → receive license key → enter in app → premium unlocked
- [ ] VIP: Relaunch app → license still valid (Keychain persistence)
- [ ] VIP: Offline for <7 days → still works
- [ ] VIP: Deactivate license → premium revoked
- [ ] Pro: Subscribe → link via email → premium unlocked
- [ ] Pro: Subscription expires → premium revoked
- [ ] Pro: Renew subscription → premium restored
- [ ] Free: All premium features gated with upsell
- [ ] Debug: VIP admin grant still works
- [ ] Existing `.premiumGated()` modifier works with new service
