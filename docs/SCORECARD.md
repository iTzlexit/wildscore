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

## Chances: the rule that makes it work

Every species has a number of **chances per day** — how many times it can be
claimed before the tile locks for the rest of the day.

| Tier | Default chances |
|---|---|
| Common | 1 |
| Frequent | 1 |
| Notable | 3 |
| Rare and above | unlimited |

Without this, forty impala means forty shouts and the game is unplayable inside
an hour. It is also exactly how the paper version worked.

A locked tile shows **who claimed it** and stays visible — the record of who got
the impala at the gate is part of the fun, so it must not simply disappear.

**"Chances" rather than a boolean scratch-off** because it generalises. One is
the common case; three suits a species you see a few times a day but not
constantly; unlimited is every leopard. And it gives house rules something
meaningful to adjust.

## House rules

Set up before the day starts, per vehicle:

- **Exclude species.** Anything nobody wants to count.
- **Chances per species**, overriding the tier default.
- **Points per species**, overriding the tier default.

This is genuinely wanted — every family plays slightly differently, and a car
game that cannot be house-ruled is a worse car game.

### But it breaks the leaderboard, so there are two modes

**A score is only comparable to another score if both were earned under the
same rules.** If one vehicle excludes impala, another triples cheetah and a
third gives everything ten chances, a shared ranking is meaningless — and worse,
it is trivially gamed by whoever sets the most generous rules.

So:

| Mode | Customisable | Public leaderboard |
|---|---|---|
| **Park rules** | No | **Yes** |
| **House rules** | Everything | No — ranked within the vehicle only |

This is the casual/ranked split every game with custom rules ends up building,
and it is worth building deliberately now rather than discovering later when
there are scores to invalidate.

**Store the ruleset with the scorecard**, not just a mode flag. A day scored six
months ago must still be explicable, and "why did I get 60 for that leopard"
needs an answer that does not depend on current settings.

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

## Bonuses

- **Big Five in one day** — first player to claim all five: **+400**
- **Big Six Birds in one day** — **+400**, and much harder

Both are already tagged in the catalogue, so this is a scoring rule rather than
new data.

## The leaderboard, and why it is the last piece

Daily totals sync when signal returns and rank against other players.

**This is the only part that needs a network, and Kruger mostly has none.** So
the whole game must work offline and the submission is a separate, later act —
back at camp, or on the drive home.

That ordering matters: **the leaderboard is a consequence of the scorecard, not
a prerequisite.** Build the car game first and it is useful with zero backend.
Build the leaderboard first and you have infrastructure serving nothing.

Three things to get right when it comes:

1. **Only Park rules games submit.** House games are excluded at the source, not
   filtered later.
2. **The server recomputes the score** from the claim list. Never trust a total
   the client calculated — the first person to notice is the first person to
   edit it.
3. **Submission is idempotent.** A day resubmitted after a flaky camp Wi-Fi must
   not count twice.

## Build order

Offline-only, no backend, in order:

1. Players for a day — add, remove, persist locally
2. Start / end a scorecard, one active at a time
3. Claim a species → assign to a player
4. Chances, and tiles locking when spent
5. Live standings on the Profile tab
6. Day log — every claim, timestamped, reassignable for five minutes
7. House rules setup screen
8. Big Five / Big Six bonuses
9. End-of-day summary worth screenshotting
10. **Then** the leaderboard, once there is something to submit

Steps 1–9 need no network at all, which is the condition this will actually be
used in.
