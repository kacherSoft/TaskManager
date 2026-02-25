# Phase 4: Pro Subscription Linking UI

**Status:** ⬚ Not Started  
**Depends on:** Phase 2 (EntitlementService)

## Overview

Add subscription purchase and linking flow to PremiumUpsellView. Users purchase a Pro subscription on the DodoPayments website, then link it in-app by entering their email address.

## Architecture Decision Needed

**How to look up subscription status by customer email:**

| Option | Approach | Pros | Cons |
|--------|----------|------|------|
| A | Embed read-only API key in app | Simple, no infra | Key extractable from binary |
| B | Cloudflare Worker proxy | Secure, key stays server-side | Requires Cloudflare setup |
| C | DodoPayments webhook → own backend | Most robust | Most complex |

**Recommended: Option B (Cloudflare Worker proxy)**

- Minimal infra (Cloudflare free tier)
- API key never leaves server
- Single endpoint: `GET /api/subscription-status?email=...`
- Worker forwards to DodoPayments API with auth header
- Can add rate limiting at Cloudflare level

### If Option B is chosen, create:

**`workers/subscription-status/index.js`** (separate repo or subfolder)

```javascript
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const email = url.searchParams.get("email");
    if (!email) return new Response("Missing email", { status: 400 });

    const response = await fetch(`https://live.dodopayments.com/subscriptions?customer_email=${email}`, {
      headers: { "Authorization": `Bearer ${env.DODO_API_KEY}` }
    });

    const data = await response.json();
    // Return only necessary fields
    return new Response(JSON.stringify({
      active: data.some(s => s.status === "active"),
      plan: data.find(s => s.status === "active")?.product_name ?? null
    }));
  }
};
```

## Modify: PremiumUpsellView

### "Subscribe to Pro" Buttons

```swift
VStack(spacing: 12) {
    Button("Pro Monthly — $4.99/mo") {
        NSWorkspace.shared.open(URL(string: "https://checkout.dodopayments.com/buy/MONTHLY_PRODUCT_ID")!)
    }

    Button("Pro Yearly — $39.99/yr (save 33%)") {
        NSWorkspace.shared.open(URL(string: "https://checkout.dodopayments.com/buy/YEARLY_PRODUCT_ID")!)
    }
}
```

### "I already subscribed" Button

```swift
Button("I already subscribed") {
    showEmailLinking = true
}
.sheet(isPresented: $showEmailLinking) {
    SubscriptionLinkingView()
}
```

## New View: SubscriptionLinkingView

**UI Layout:**

```
┌──────────────────────────────────────────┐
│  📧  Link Your Subscription             │
│                                          │
│  Enter the email you used to subscribe:  │
│  ┌────────────────────────────────────┐  │
│  │  user@example.com                 │  │
│  └────────────────────────────────────┘  │
│                                          │
│  [ Verify Subscription ]                 │
│                                          │
│  Status: ✅ Pro subscription active!     │
│                                          │
└──────────────────────────────────────────┘
```

**State:**

```swift
struct SubscriptionLinkingView: View {
    @Environment(EntitlementService.self) var entitlementService
    @State private var email: String = ""
    @State private var linkingState: LinkingState = .idle

    enum LinkingState {
        case idle
        case verifying
        case active(plan: String)
        case notFound
        case error(String)
    }
}
```

**Flow:**

```
User taps "Subscribe to Pro"
  → Browser opens DodoPayments checkout
  → User completes subscription purchase
  → User returns to Strata app
  → User taps "I already subscribed"
  → SubscriptionLinkingView opens
  → User enters purchase email
  → App calls proxy/API to check subscription status
  → If active: store email + status in Keychain → premium unlocked
  → If not found: show "No active subscription found for this email"
```

## EntitlementService Addition

```swift
extension EntitlementService {
    func linkSubscription(email: String) async throws {
        // Call proxy endpoint or DodoPayments API
        // If active subscription found:
        //   - Store email in Keychain
        //   - Store subscription status in Keychain
        //   - Update isSubscriptionActive = true
        //   - Update lastValidation timestamp
    }

    func refreshSubscription() async {
        // Re-check subscription status for stored email
        // Update cached status
    }
}
```

## Edge Cases

- [ ] Email not found → "No active subscription found. Make sure you used the same email."
- [ ] Subscription expired/cancelled → "Your subscription is no longer active."
- [ ] Network error → "Could not verify. Check your connection and try again."
- [ ] Email format validation before sending request
- [ ] Rate limiting on verification requests (prevent brute force)

## Validation

- [ ] "Subscribe to Pro" buttons open correct checkout URLs
- [ ] Monthly and yearly options both work
- [ ] "I already subscribed" button shows email linking sheet
- [ ] Email verification succeeds for active subscription
- [ ] Email verification shows appropriate error for inactive/missing subscription
- [ ] After successful linking, `isSubscriptionActive` is `true`
- [ ] Premium features unlock immediately after linking
- [ ] Subscription status persists across app restarts (cached in Keychain)
- [ ] If using Cloudflare Worker: proxy endpoint works correctly
- [ ] Build succeeds with no warnings
