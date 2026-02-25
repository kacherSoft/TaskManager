# Phase 6: Cleanup & End-to-End Testing

**Status:** ⬚ Not Started  
**Depends on:** Phase 5 (all features implemented)

## Overview

Remove all StoreKit dependencies, update documentation, and perform comprehensive end-to-end testing of the complete DodoPayments integration.

## StoreKit Removal

### Delete Imports

Remove `import StoreKit` from all files:

```bash
grep -rn "import StoreKit" TaskManager/Sources/
```

- [ ] Remove every occurrence found

### Delete Files

- [ ] Delete `Configuration.storekit` (StoreKit configuration file)
- [ ] Delete `Services/SubscriptionService.swift` (replaced by EntitlementService)
- [ ] Delete any StoreKit-related test files

### Clean Up PremiumUpsellView

- [ ] Remove StoreKit product loading (`Product.products(for:)`)
- [ ] Remove StoreKit purchase flow (`product.purchase()`)
- [ ] Remove `Transaction.currentEntitlements` listener
- [ ] Remove StoreKit product display (price, description from Product)
- [ ] Ensure all CTAs now point to DodoPayments checkout URLs

### Clean Up Package.swift / Xcode Project

- [ ] Remove StoreKit from explicit dependencies (if listed in Package.swift)
- [ ] Remove StoreKit capability from entitlements if present
- [ ] Remove any StoreKit-related build settings

### Clean Up App Entry Point

- [ ] Remove `SubscriptionService` initialization
- [ ] Remove `.environmentObject(subscriptionService)` injection
- [ ] Confirm `EntitlementService` is properly initialized and injected via `.environment()`

### Remove Stale References

```bash
grep -rn "SubscriptionService" TaskManager/Sources/
grep -rn "StoreKit" TaskManager/Sources/
grep -rn "storekit" TaskManager/
```

- [ ] Zero results for all three searches

## Documentation Updates

### `docs/features-status.md`

- [ ] Update billing/payment section:
  - Payment provider: DodoPayments (was: StoreKit / pending migration)
  - License activation: DodoPayments license keys
  - Subscription management: DodoPayments checkout + customer portal
  - No App Store IAP dependency

### `AGENTS.md`

- [ ] Remove any "StoreKit migration pending" notes
- [ ] Update payment/distribution model description:
  - Payments via DodoPayments (external provider)
  - License keys for VIP Lifetime
  - Subscription linking via email

### `TaskManager/README.md`

- [ ] Update payment/billing information
- [ ] Document new service files:
  - `Services/KeychainHelper.swift`
  - `Services/DodoPaymentsClient.swift`
  - `Services/EntitlementService.swift`
- [ ] Document new view files:
  - `Views/Premium/LicenseActivationView.swift`

## End-to-End Testing Matrix

### Fresh Install

- [ ] App launches to free tier
- [ ] All premium features are gated (`.premiumGated()` modifier works)
- [ ] PremiumUpsellView shows DodoPayments purchase options
- [ ] No StoreKit errors in console

### VIP Purchase Flow (Test Mode)

- [ ] "Buy VIP Lifetime" opens DodoPayments sandbox checkout
- [ ] Complete test purchase → receive license key
- [ ] "I have a license key" opens LicenseActivationView
- [ ] Paste license key → activate → success
- [ ] Premium features unlock immediately
- [ ] License key persists across app restart

### Pro Subscription Flow (Test Mode)

- [ ] "Subscribe to Pro" opens DodoPayments sandbox checkout
- [ ] Complete test subscription
- [ ] "I already subscribed" opens email linking view
- [ ] Enter email → verify → subscription active
- [ ] Premium features unlock immediately
- [ ] Subscription status persists across app restart

### License Validation

- [ ] On launch: cached license validates in background
- [ ] Valid license → access granted
- [ ] Invalid/revoked license → access revoked
- [ ] Expired subscription → access revoked

### License Deactivation

- [ ] Settings → "Deactivate License" → confirmation alert
- [ ] Confirm → API call succeeds → Keychain cleared → reverts to Free
- [ ] All premium features re-gated after deactivation

### Offline Grace Period

- [ ] Disconnect from internet
- [ ] Relaunch app with valid cached license (< 7 days old)
- [ ] Access should be granted (offline grace)
- [ ] Simulate cache > 7 days old → access should be revoked

### Cache Expiry

- [ ] Validation timestamp updates on each successful validation
- [ ] Cache older than 7 days triggers re-validation requirement
- [ ] Failed re-validation after cache expiry → access revoked

### Debug VIP Admin Grant

- [ ] Debug toggle in settings/debug menu still works
- [ ] Admin grant overrides license/subscription state
- [ ] Disabling admin grant reverts to actual entitlement state

### UI Consistency

- [ ] `.premiumGated()` modifier correctly gates all premium features
- [ ] `canUse(.inlineEnhance)` works for inline enhancement
- [ ] PremiumUpsellView displays all purchase options correctly
- [ ] Settings shows correct plan status for all states

### Build & Distribution

- [ ] `./scripts/build-debug.sh` succeeds
- [ ] `./scripts/build-release.sh` succeeds
- [ ] No compiler warnings
- [ ] No StoreKit references remaining
- [ ] Sign with Developer ID
- [ ] Notarization succeeds (if applicable at this stage)

## Rollback Plan

If critical issues are found:

1. `EntitlementService` can coexist with `SubscriptionService` temporarily
2. Feature flag to switch between StoreKit and DodoPayments
3. Keychain data is independent — clearing it reverts to free safely

## Completion Criteria

- [ ] All StoreKit code removed (zero references)
- [ ] All documentation updated
- [ ] All testing matrix items pass
- [ ] App builds and signs with Developer ID
- [ ] Ready for production DodoPayments product IDs (switch from sandbox)
