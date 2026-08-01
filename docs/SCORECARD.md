# The day scorecard — the paper game, digitised

This is the origin story made literal: everyone in the car, one list, one day,
arguing about who called it first. It is also the single most testable feature
in the project, because it needs **no camera, no GPS and no backend** — one
phone passed around a vehicle.

Worth building before Phase 2 for that reason alone. It makes the app playable
on the next trip rather than the one after.

---

## The flow

1. **Start scorecard.** One tap on the Profile tab.
2. **Add players** — just names, everyone in the car. No accounts, no invites.
3. **Drive.** Someone shouts. Tap the tile, pick who called it.
4. **Common animals lock** once claimed. Rare ones stay open all day.
5. **End of day** — final standings, and the argument settles itself.

The scorecard is per **vehicle**, not per person. That matches how the game is
actually played and how the Vehicle Pass is priced.

---

## Who called it

Tapping a tile opens a short list of the day's players. One tap assigns it.

Two rules that stop it becoming a source of argument rather than a settler of
them:

- **The claim is timestamped** and shown in the day log. "I said it first" is
  answerable.
- **Any claim can be reassigned or undone** for five minutes, then it locks.
  Long enough to fix a mis-tap; short enough that nobody relitigates the morning
  at dinner.

---

## Scratch-off: the rule that makes it work

**Common and Frequent species can be claimed once per day, per vehicle.** After
that the tile visibly locks — greyed, marked *claimed by ___*, not tappable.

Without this, forty impala means forty shouts and the game is unplayable inside
an hour. It is also exactly how the paper version worked.

**Notable and above stay open all day**, every time. Every lion is worth
calling.

---

## The points problem, and why Common should rise

> "First one to spot an impala at the gate is always an excitement."

That is true, and the current table does not reflect it. Common is 5 points — a
rounding error — so nobody would race for it.

But raising it naively breaks the curve. The constraint is:

> **Every common animal claimed, all day, by everybody, must still be worth less
> than one genuinely rare find.**

Otherwise the winner is whoever was awake at the gate, and the pangolin stops
mattering — which inverts the whole product.

### The arithmetic

The catalogue has **13 Common and 17 Frequent** species. Each is claimable once
per day, so the day's entire common haul has a hard ceiling:

| Common | Frequent | Whole-day common ceiling | One Legendary |
|---|---|---|---|
| 5 | 15 | **320** | 400 — pangolin wins, just |
| 15 | 30 | **705** | 400 — pangolin loses badly |

At the current values it already works, and only just: sweeping every common
species in the park in one day is worth less than a single pangolin. That is
the property to protect.

**Tripling Common breaks it.** A car that has a good morning at the gate would
out-score a once-in-a-lifetime find, which inverts the product.

### What to do instead — a First Call bonus

Leave the tier values alone. Add one rule:

> **The first claim of the day — any species — is worth double.**

That is the gate excitement, precisely located. It rewards being awake and
alert at 05:30 without touching the curve, and "first call of the day" becomes
its own small trophy that turns over daily.

Optionally add a second, cheaper thrill: **the first claim of each species is
worth double for whoever calls it** — which is already how scratch-off works,
so it costs nothing to explain.

**Recommended: First Call only.** One rule, no cap to explain, no maths that
needs a chart. If it turns out commons still feel worthless in play, raise
Common to 10 and re-check the ceiling — 13 × 10 + 17 × 15 = 385, still under a
pangolin.

---

## What this is *not*

**Not verified.** A tapped claim is an honour-system claim, exactly like the
paper game. It earns no crown, no leaderboard position, and does not enter the
lifetime Codex as a verified catch.

That separation is load-bearing. When Phase 2 lands, a photographed sighting
sits alongside these and is visibly different — otherwise the whole trust model
collapses into "whoever taps fastest".

**Suggested framing in the UI:** the day scorecard is *the car game*. The Codex
is *your record*. A claim can optionally be upgraded by photographing the animal
— which is the natural on-ramp into the camera flow.

---

## Build order

1. Players for a day — add, remove, persist locally
2. Start / end a scorecard, one active at a time
3. Claim a species → assign to a player
4. Scratch-off locking for Common and Frequent
5. Live standings, sorted, on the Profile tab
6. Day log — every claim with a timestamp
7. End-of-day summary worth screenshotting

None of it needs a network. All of it works in aeroplane mode, which is the
condition it will actually be used in.
