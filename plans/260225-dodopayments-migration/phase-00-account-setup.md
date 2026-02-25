# Phase 0: DodoPayments Account & Product Setup

**Status:** ✅ Done

## Overview

Create and configure the DodoPayments account with all Strata product offerings before any code changes begin.

## Prerequisites

- [ ] Create DodoPayments account at [dodopayments.com](https://dodopayments.com)
- [ ] Have access to a valid email for account verification
- [ ] Decide on final pricing (confirmed below)

## Steps

### 1. Sign Up & Verify Account

- [ ] Register at dodopayments.com
- [ ] Verify email address
- [ ] Complete any required KYC/business verification
- [ ] Enable test/sandbox mode for initial development

### 2. Create Product: Strata Pro Monthly

- [ ] Type: **Subscription**
- [ ] Name: `Strata Pro Monthly`
- [ ] Price: **$4.99/mo**
- [ ] Billing interval: Monthly
- [ ] Note the **Product ID** → `________________`

### 3. Create Product: Strata Pro Yearly

- [ ] Type: **Subscription**
- [ ] Name: `Strata Pro Yearly`
- [ ] Price: **$39.99/yr**
- [ ] Billing interval: Yearly
- [ ] Note the **Product ID** → `________________`

### 4. Create Product: Strata VIP Lifetime

- [ ] Type: **One-time payment**
- [ ] Name: `Strata VIP Lifetime`
- [ ] Price: **$99.99**
- [ ] License key: **Enabled**
  - Expiry: **None** (lifetime)
  - Activation limit: **3 devices**
- [ ] Note the **Product ID** → `________________`

### 5. Get API Key

- [ ] Navigate to **Developer → API Keys**
- [ ] Generate a **read-only** API key
- [ ] Store securely (do NOT commit to repo)
- [ ] API Key: `________________`

### 6. Record Product IDs

| Product              | Type         | Price     | Product ID | License Key |
|----------------------|--------------|-----------|------------|-------------|
| Strata Pro Monthly   | Subscription | $4.99/mo  | `pdt_0NZEvu9tI0aecVEYkmxOH` | N/A         |
| Strata Pro Yearly    | Subscription | $39.99/yr | `pdt_0NZEzxFzK5RRekOJXQHpZ` | N/A         |
| Strata VIP Lifetime  | One-time     | $99.99    | `pdt_0NZEzLgAEu8PcrUBqi8mt` | Enabled     |

### 7. Test in Sandbox Mode

- [ ] Verify each product appears in dashboard
- [ ] Perform a test checkout for each product
- [ ] Confirm license key generation for VIP Lifetime
- [ ] Confirm subscription lifecycle events (create, renew, cancel) in test mode
- [ ] Test API endpoints with sandbox base URL: `test.dodopayments.com`

## Output

- [ ] All 3 products created and configured
- [ ] Product IDs documented
- [ ] Read-only API key generated and stored securely
- [ ] Sandbox checkout flows verified

## Notes

- All sandbox testing uses `test.dodopayments.com`
- Production uses `live.dodopayments.com`
- API key is only needed for subscription lookup (Phase 4); license activation/validation/deactivation endpoints are public
