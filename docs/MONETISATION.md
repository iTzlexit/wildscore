# Monetisation — how users pay, and how you get paid

> Phase 5 work. Written now because it shapes decisions earlier, and because
> getting it wrong gets an app removed rather than merely criticised.

## Where the data is today

**All of it is on the phone. There is no server, and the app makes no network
calls at all.** One runtime dependency, `shared_preferences`, holding four keys:

| Key | What |
|---|---|
| `tracker_profile_v1` | Name, avatar, season |
| `spotted_species_v1` | The collection — species ids only |
| `active_scorecard_v1` | The drive in play |
| `visit_history_v1` | Every finished drive |

The species catalogue and photographs are bundled read-only assets.

**Which means: lose the phone, lose everything.** Android's auto-backup may
quietly save these to a Google account, but it is off for some users, silent
when it fails, and not something to promise anyone. Until Phase 4 there is no
recovery, and the app should not pretend otherwise.

`shared_preferences` also rewrites the whole visit list on every append. Fine
for the tens of records a season produces; it moves to sqflite when photographs
arrive.

## When a server actually becomes necessary

Not for anything currently built. It is needed for exactly six things, and every
one of them is on the paid side of the line:

1. **Backup and restore** — the lost phone
2. **Sync** — a second device
3. **The leaderboard** — comparing against strangers
4. **The sightings feed** — sharing with them
5. **Photo storage** — Phase 2, and the only genuinely expensive one
6. Anything social that follows

**Build backup first, not the leaderboard.** Backup is what people pay for;
leaderboards are what developers assume people pay for. The trigger to start is
the first email from someone who lost their phone and their collection with it —
that email is the business case, and it will arrive.

Rough running cost when it lands: Supabase Pro at $25/month, Cloudflare R2 at
about $0.015 per GB with no egress charge. Call it $30–50/month for a few
thousand users with photographs, which the Cloud Pass covers at around **forty
subscribers**. Worth knowing that number before building anything.

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

> **Amended 2 August 2026.** The tier table below was written against features
> that do not exist yet — the Six, the Den, Quiet Sighting. The line has moved
> to something simpler and easier to defend, and the old split is kept at the
> bottom of this file for the reasoning, which still holds.

### Two products, priced by what each costs to run

> **Revised 2 August 2026.** An earlier draft here put everything behind one
> annual pass. That was wrong in one specific way: it treated the game as free
> and the server as the product, when **the game is the only thing here nobody
> else has.** A species checklist exists a hundred times over. A scorecard your
> family argues over does not.

| | What it is | Price | Needs a server? |
|---|---|---|---|
| **The Wild Score game** | Drives, scoring, players, standings, history | **R99 once** | **No** |
| **Cloud Pass** | Backup, sync, leaderboard, feed, photo storage | **R99/year** | Yes |

The pricing follows the cost. The game costs nothing to run once it is written,
so it is bought once. The cloud costs money every month, so it recurs. That is
easy to explain and impossible to resent.

**The field guide and the collection are free forever, and always will be.**
Browse all 74 species, mark what you find, fill the Collections, keep it for
twenty years. That is the top of the funnel and the reason anyone still has the
app in March.

### One free drive, and the ask comes at camp that evening

> **Your first day is free** — the whole day, solo or with the entire car. After
> that, R99 once and every drive you ever take is yours.

An earlier draft said three drives. That was wrong, and the reason is the shape
of a South African Kruger trip: **most of them are a long weekend.** Three free
drives means the average family finishes the whole trip without ever being
asked, drives home, and forgets the app exists by Wednesday. The free tier ate
the entire customer.

One day is still plenty to feel it. A morning drive produces a dozen sightings
and at least one argument, which is the product working.

### The moment matters more than the price

**Ask at the end of day one, back at camp. Not at the gate on day two.**

Two reasons, and the second one is not obvious:

1. They have just been shown their score. The day is fresh, somebody won, and
   the app is the reason there is anything to argue about.
2. **In-app purchase requires a network connection, and Kruger has none.**

That second point is a hard constraint, not a preference. Google Play Billing
and StoreKit both have to reach the store to complete a purchase. A paywall that
appears at Satara gate at 05:30 cannot be paid even by someone reaching for
their phone to do it — and that is a worse outcome than not asking, because the
answer was yes and the app said no.

Main camps have signal or Wi-Fi. The evening at camp is where the transaction
can actually happen.

Two rules that follow:

- **Never block a drive already in progress.** Entitlement is checked when a
  drive *starts*, never mid-day.
- **Cache the entitlement locally.** RevenueCat does this by default. A paid
  player must work for a week with no signal, which is the entire point of the
  app.

Nothing earned in the free day is ever taken away. It stays in the history, the
points stay in the lifetime total, the species stay in the collection.

### Once, not yearly

Where the two could go either way, take once-off:

- The decision is made **in a car, possibly at a gate, with a family waiting.**
  "R99, yours forever" survives that. "R99 a year" invites a conversation.
- An annual product aimed at holidays runs straight into *"am I even going next
  year"*, which is unanswerable at the moment of asking.
- No renewals to manage, no churn, no refunds of unused months, no support.

The recurring revenue arrives later as the Cloud Pass, which recurs for a reason
a user can see: it pays a server bill that exists every month whether they open
the app or not.

### Why R99 once, and not R199 a year

- **R99 is an impulse. R199/year is a decision.** Different parts of the brain,
  and only one of them is available to an unknown app at a park gate.
- A once-off has no "will I even go to Kruger this year" anxiety attached to it,
  which is the objection that kills annual products aimed at holidays.
- It can ship **with no backend at all** — which means revenue in month one with
  zero running costs, instead of revenue in month nine after a server bill.

The Cloud Pass arrives later, and by then it sells itself: someone with three
seasons of sightings on one phone is *afraid*, and backup is the answer to a
fear rather than a feature on a list.

### It never takes anything away

When a pass lapses:

- **Nothing is deleted.** Not a sighting, not a drive, not a point.
- **Nothing already earned is locked.** The collection, the history and the
  scores stay open and fully usable, forever.
- What stops is **new server work** — no further backup, no sync, no posting.

A lapsed player is exactly a free player who has been around longer. That is the
difference between a subscription and a hostage situation, and it is the
difference people write reviews about.

### Price sanity check

A South African conservation fee is around R120 per person per day, and an
international one is roughly five times that. A family trip runs to thousands
before anyone has eaten.

Nobody who paid to get through that gate is deciding against R99 on price. They
are deciding on **whether they trust the app** — which is an argument for a
generous free tier and a long runway before asking, not for a lower number.

$6.99 for the game internationally, $6.99/year for the pass. Price the
territories separately; see below.

### Advertising: considered and rejected

Not "later" — rejected, for a reason specific to this app.

**Ads need a network, and Kruger has none.** The app's whole purpose is to be
useful in a place with no signal, which means an ad-supported build shows
adverts precisely when the app is *not* being used and none when it is. The
inventory is worthless because it never loads at the moment of use.

Beyond that: a few thousand South African users generating a handful of
impressions each is worth a rounding error against a few hundred passes, and it
would be paid for in exactly the currency this product is trading on — a
calm screen, used in a place people drove six hours to get to.

The only advertising-shaped thing worth revisiting is a **partner listing** for
camps and operators, and that is a different business with a sales team in it.

### Per-territory pricing matters

An international visitor already pays around **R602 per person per day** in
conservation fees — $14.99 is invisible to them. A South African family feels
every rand. Price them separately.

### The paywall is on the Six and the Den — not on submitting a score

An earlier draft put the paywall on **"Submit today's score"**, on the reasoning
that it lands at the moment of peak motivation. That was wrong, and it is worth
recording why.

> People don't resent paying to keep a photo album. They resent paying for
> leaderboards.

Charging to submit a score **is** charging for a leaderboard. It is the one
thing the positioning says not to sell. The error came from treating the app as
a competitive game rather than a memory box — see [VISION.md](VISION.md).

What people will pay for is **keeping their photographs, beautifully**: six
cards they chose, and a den where those animals live. That is an album, and
albums are what people renew.

### Why the free tier is this generous

It is tempting to paywall the camera. Do not. **The free tier must be genuinely
good** — the whole model depends on someone finishing day one proud of their
score before being asked for money.

A free player who has captured forty animals has **forty reasons to pay**: their
collection is already real, and the pass is what turns it into something they can
keep and display. A free player who has captured nothing has none, and deletes
the app at the gate.

The collection is also the retention mechanism. Someone with three years of
sightings does not switch to a competitor.

### When to ask

The natural moment is **the first time a player wants to promote a capture to
their Six** — they have just taken a photograph they are proud of and want it
kept. That is asking them to buy an album for a photo they already love, which
is a completely different transaction from asking them to buy a ranking.

**Never nag.** One paywall, tied to one action the player chose to take. No
interstitials, no countdowns, no "3 free promotions remaining" counters. The app
is used in a place people go to get away from that.

### Per-submission payment: considered and rejected

Charging per submitted day was considered and rejected:

- Consumable IAP means transaction friction at exactly the moment the app should
  feel good
- It makes standing a function of spending, which breaks the no-pay-to-win rule
- It punishes the best days, which is precisely backwards

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
