# The day scorecard — the paper game, digitised

This is the origin story made literal: everyone in the car, one list, one day,
arguing about who called it first. It is also the single most testable feature
in the project, because it needs **no camera, no GPS and no backend** — one
phone passed around a vehicle.

Worth building before Phase 2 for that reason alone. It makes the app playable
on the next trip rather than the one after.

---

## The flow

1. **Start a drive.** One tap on the **Wild Score** tab. You are in it already.
2. **Add players** — just names, everyone else in the car. Optional: solo is a
   first-class way to play, not a fallback.
3. **Drive.** Someone shouts. Tap the tile, pick who called it.
4. **Common animals lock** once claimed. Rare ones stay open all day.
5. **End the day** — final standings, saved to history, and the argument settles
   itself.

The game has **its own tab**, separate from the Profile. A drive belongs to the
vehicle; a profile belongs to one person. Sharing a screen meant a carful of
five with a good morning between them had more standings than the card could
hold, and the profile's own numbers were squeezed to make room.

The scorecard is per **vehicle**, not per person. That matches how the game is
actually played and how the Vehicle Pass is priced.

---

## You are in the car

One player is the phone's account holder. They are added automatically, they
cannot be removed, and they are flagged `isOwner` on the scorecard.

That flag is load-bearing. **Whatever the owner claims is also written to their
permanent record** — the species joins their collection, and the points join
their lifetime total. Everyone else in the car is a guest on this phone: their
claims count for the day and then they are gone.

Crediting a guest's leopard to the owner's collection would make the collection
untrustworthy, which is the one thing it cannot be — the whole product rests on
"your sightings live here".

### Banked once, when the day ends

Crediting per claim was the obvious design and it was wrong. It meant undo had
to reverse itself, restart had to reverse a whole day, and every future edit
would need its own reversal — each one a way for a lifetime total to drift with
nothing to check it against.

Instead:

- A drive is **persisted continuously**, so nothing is at risk if the phone dies
  at the gate
- **Ending the day** writes it to the visit history, and the owner's species
  enter their collection
- **The lifetime total is derived** by summing `ownerPoints` across visits — it
  is never stored, so it cannot be wrong
- **Restart and undo reverse nothing**, because nothing was banked

The one cost: a drive that is never ended is never counted. That is the right
trade — ending is a deliberate act and the day sits there until you make it.

Guests' scores are saved **with the day**, not to anyone's record. That is what
makes the history worth opening: "who was in the car at Satara in July, and did
Sam really get the wild dog" is what people actually want back.

### Points and the collection are different questions

This was got wrong first time round, and the fix is worth stating plainly:

| | Answers | Who gets it |
|---|---|---|
| **Points** | Who called it first? | Only the claimer |
| **The collection** | What have you seen? | Everyone in the car |

If Sam shouts "pangolin" and you look up and see a pangolin, **you have seen a
pangolin.** Keeping it out of your life list to protect a scoring rule makes the
life list the thing that is wrong — and the life list is the part of this app
that is supposed to last for years.

So at the end of a day, every species *anyone* claimed joins the owner's
collection, while the points stay exactly where they were earned. The end-of-day
confirmation says how many are new, so it is never a surprise.

The one exception: if the owner was not a player — the phone was handed to a
friend — nothing is collected. A collection should not grow while its owner is
at home.

### Nothing is aged out of the history

The question came up of whether to cap it — only keep the last forty drives, or
only this season. **No.** A two-year-old drive is worth *more* than last week's,
not less; it is the thing someone opens when they miss the park, and it is a
large part of what a season pass is being renewed for. Capping it would delete
the product's own retention.

Long histories are handled three ways instead:

- **Filter by year and month.** Only periods that contain a drive are offered.
- **Twelve at a time**, with a "show older" button. These cards are tall and a
  season of them built at once is a visibly slow screen.
- **Delete is the player's call**, per drive, never the app's.

Because the lifetime total is derived, deleting a drive removes its points too.
The confirmation says so — a total that outlived the deletion of its own
evidence would be worse than losing the points. Species already spotted stay in
the collection, since they may well predate that day.

Storage moves to sqflite in Phase 2. `shared_preferences` rewrites the whole
list on every append, which is fine for the tens of records a trip produces and
is not fine for a few hundred.

## Restart vs End day

Two different intentions, so two different controls, both confirmed:

| | Players | Today's claims | Saved to history | Lifetime total |
|---|---|---|---|---|
| **Restart** | kept | wiped | no | untouched |
| **End day** | cleared | cleared | **yes** | **grows** |

Restarting is "we mis-scored the first hour" and happens mid-morning. Ending is
"we are done and it counts" and happens once. Making a family retype four names
to fix a scoring mistake is how you lose them back to paper.

## Avatars

Every player gets an animal face, and the rule differs by who they are:

- **The account holder's avatar is derived from their name** and never changes.
  It survives a reinstall, and it is how other players will recognise them on
  the leaderboard later.
- **Guests are dealt a random face per game**, distinct within the car. A new
  scorecard dealing new animals is part of the ritual of starting a day.

Stored as an **index**, never as an image, so the artwork can be redrawn later
without migrating a single saved profile.

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

## The points scale

Points are **fixed**. House rules may not change them — see below — so the scale
has to be one most players would agree with on sight.

### The principle

**Points should track how unlikely a sighting actually is**, and sighting
probability in Kruger is wildly non-linear. Rough odds for a self-drive visitor
on a four-day trip:

| Animal | Odds of seeing one |
|---|---|
| Impala | Certain |
| Elephant, giraffe | ~90% |
| Lion | ~60% |
| Leopard | ~25% |
| Cheetah, wild dog | ~10% |
| Serval, honey badger | ~2% |
| Caracal, aardvark | under 1% |
| Pangolin | a handful of sightings a year, park-wide |

That is a range of roughly **1 : 1000**, not 1 : 80. The old scale
(5 → 400) badly under-rewarded the top end: a pangolin was worth 80 impala,
when in truth thousands of people see impala for every one who sees a pangolin.

### The scale

A clean geometric progression, each tier ~2.5–3× the one below:

| Tier | Points | Step |
|---|---|---|
| Common | 5 | — |
| Frequent | 15 | 3× |
| Notable | 40 | 2.7× |
| Rare | 100 | 2.5× |
| Very rare | 250 | 2.5× |
| Exceptional | 750 | 3× |
| **Legendary** | **2,500** | 3.3× |

**Sense check:** claiming every Common and Frequent species in the park in a
single day is worth **320**. One pangolin is **2,500** — nearly eight times a
perfect morning.

That is the right shape. A pangolin *should* end the competition, because in
real life it does. A caracal at 750 is worth more than an entire good day of
ordinary game viewing, which is exactly how it feels at the time.

### What this depends on

**The numbers only work if the tier assignments are right.** Getting caracal
into Exceptional matters more than whether Exceptional is 700 or 800 — and the
tier review with a Kruger guide is still outstanding. Do that before treating
these as settled.

## The old points problem, kept for the record

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

1. ✅ Players for a day — add, remove, persist locally
2. ✅ Start / restart / end a scorecard, one active at a time
3. ✅ Claim a species → assign to a player
4. ✅ Chances, and tiles locking when spent
5. ✅ Live standings on the Profile tab, with per-player hauls
6. ✅ The owner's claims reaching their permanent collection
7. Day log — every claim, timestamped, reassignable for five minutes
8. House rules setup screen
9. Big Five / Big Six bonuses, First Call double
10. End-of-day summary worth screenshotting
11. **Then** the leaderboard, once there is something to submit

Steps 1–10 need no network at all, which is the condition this will actually be
used in.
