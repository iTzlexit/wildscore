# Monetisation — how users pay, and how you get paid

> Phase 5 work. Written now because it shapes decisions earlier, and because
> getting it wrong gets an app removed rather than merely criticised.

## The rule that decides everything

**Apple and Google require their own in-app purchase systems for digital
goods.** Unlocking features inside your app is a digital good.

You may **not** take payment for it by EFT, bank transfer, PayFast, Yoco,
Stripe, PayPal, or a card form you build yourself. Apps that try are rejected at
review, or removed after launch. This is among the most consistently enforced
rules on both stores.

**Your bank account number never appears in the app.** Not on a screen, not in
the code, not in a support email. It goes once into the developer consoles.

### What *is* allowed to use another processor

Physical goods and real-world services — printed end-of-season collection cards
posted to someone, a guided drive booked through a partner operator. Those may
use a normal payment gateway, because Apple and Google only claim digital goods.
Worth remembering if physical merchandise ever becomes a revenue line.

## The user's experience

This is the Smoke Free flow, and it is effortless for one reason: **Apple and
Google already hold the user's card.** They have bought apps before.

1. User taps *Unlock the 2027 Season Pass*
2. A **native Apple / Google sheet** appears — the store's UI, not yours —
   showing the price in rands
3. Face ID, fingerprint, or store password
4. Unlocked

No card number, no form, no leaving the app. Roughly three seconds.

Your job is only the screen *before* that sheet: what the pass is, what it
costs, and why it's worth it. Everything after is the store's.

## How money reaches you

```
User pays Apple / Google
        ↓  commission withheld
Apple / Google
        ↓  monthly payout
Your bank account  ← registered once in the developer console
```

**Commission is 15%, not 30%.** Both stores run reduced-rate programmes for
small developers:

| Store | Rate | How |
|---|---|---|
| Apple | 15% under ~$1M/yr proceeds | App Store Small Business Program — **you must apply**, it is not automatic |
| Google Play | 15% on the first ~$1M/yr earnings | Automatic |

On a R249 season pass that is roughly **R212 to you**, before tax.

Payouts are monthly, subject to a minimum balance. Both pay into a South African
bank account.

## Setting it up (Phase 5, not now)

1. **Apple Developer Program** — $99/year. **Google Play** — $25 once.
2. Complete the **Paid Applications Agreement** (Apple) and the merchant profile
   (Google). Until this is done you cannot sell anything, only give it away.
3. Enter banking and tax details in each console.
4. **Tax forms.** Both need US tax documentation — as a South African
   sole trader or company that is generally a **W-8BEN** or **W-8BEN-E**. Skip
   it and they withhold up to 30% of US-sourced income. Do it before your first
   sale, not after.
5. Create the products in each console (see the asymmetry below).
6. Wire up RevenueCat.

> Tax treatment of this income in South Africa — provisional tax, and VAT
> registration once turnover passes the threshold — is a question for an
> accountant, not for this document. Ask one before your first payout, not at
> year end.

## The one real complication: the season pass

[VISION.md](VISION.md) settles that the pass is **annual and non-renewing** —
people visit Kruger once a year, and a subscription breeds cancellations and
resentment. That decision maps differently onto each store:

| Store | Product type | Notes |
|---|---|---|
| **Apple** | *Non-Renewing Subscription* | A real product type, built for exactly this — season passes. Clean fit. |
| **Google Play** | One-time product | **No non-renewing subscription type exists.** You sell a one-time product and track the year's expiry yourself, server-side. |

This asymmetry is the single best argument for **RevenueCat**: one API over both
stores, entitlements you query as "does this user have the 2027 pass?", and
receipt validation you did not write. Free until roughly $2,500/month revenue.

Doing it by hand means two SDKs, two receipt formats and two validation flows —
and receipt validation is where homegrown IAP quietly leaks money to people who
have worked out how to fake a purchase.

## What you sell

The split is **play free, pay to compete.**

| Tier | Price | Contains |
|---|---|---|
| **Free** | — | The Codex, the camera, and your own collection. Catch what you like, keep it forever, offline. |
| **Season Pass** | ~R249/year, non-renewing | The leaderboard, share cards, full stats, and submitting your day |
| **Later** | | Regional challenge packs, printed end-of-season cards, guided-operator tie-ins |

### Why the free tier includes catching

It is tempting to paywall the camera. Do not.

A free player who has caught forty animals has **forty reasons to pay** — their
collection is already real, and the pass is what lets them show it to anyone.
A free player who has caught nothing has none, and will delete the app at the
gate.

The collection is also the retention mechanism. Someone with three years of
sightings does not switch to a competitor.

### Where the paywall appears

**At "Submit today's score."**

This is the right moment and it is worth being deliberate about it. At the end
of a day in the park, a player has just found something good and wants it to
count. That is the point of maximum motivation — not a splash screen on first
launch, when they have nothing invested and no reason to care.

So: catch freely all day. When you tap *Submit today's score* and you have no
pass, you get one screen that says what a pass costs and what it unlocks. Buy
or dismiss; the sightings are saved either way and can be submitted later if
you buy the pass before the season ends.

**Never nag.** One paywall, at one moment, tied to one action the player chose
to take. No interstitials, no countdowns, no "3 free submissions remaining"
counters. The app is used in a place people go to get away from that.

### Per-submission payment: considered and rejected

Charging per submitted day was considered. It is rejected because:

- Consumable IAP means constant transaction friction at exactly the moment the
  app should feel good
- It makes the leaderboard a function of spending, not skill — which breaks
  the no-pay-to-win rule
- It punishes the best days, which is precisely backwards

The season pass gets the same "pay when you care" timing without any of that.

**Never pay-to-win.** Money buys access and cosmetics. It never buys points,
multipliers or leaderboard position. A leaderboard you can buy is not worth
appearing on — and appearing on it is the entire product.

## Things that catch people out

- **Prices come from a fixed tier list**, not free text. You pick a tier per
  territory; you cannot charge exactly R249,00 if no tier lands there.
- **Apple and Google collect VAT/sales tax** as marketplace facilitators in most
  territories, so listed prices are tax-inclusive and your reported revenue is
  net.
- **Test purchases are free** via sandbox accounts (Apple) and licence testers
  (Google). Never test with a real card.
- **Refunds are the store's decision, not yours.** A user can be refunded
  without asking you. Your entitlement check must handle a pass being revoked.
- **Do not add an external payment link** to dodge commission. There are narrow
  regulatory exceptions in some regions; none is worth the risk for a solo
  developer shipping from South Africa.
