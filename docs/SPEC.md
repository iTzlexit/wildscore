# Wild Score — Product Spec

> Working name. Check availability at CIPC and on both app stores before you print
> anything. Avoid any name containing "poke", "dex", "catch 'em" or similar —
> Nintendo enforces aggressively and you do not want that letter.

## The product in one line

A verified wildlife-spotting game for Kruger National Park: photograph an animal in
the park, earn points scaled to how hard it was to find, build a permanent
collection, and compete on a seasonal leaderboard.

## The thing that must not be lost

You played this on paper with your family and loved it. Everything below exists to
protect that feeling, not to replace it. Concretely, the app must nail:

1. **The reveal.** Logging a Pangolin cannot look like logging an Impala. The app
   stops, animates, plays a sound, flips a card, ticks the score up. This is the
   product. Build it in Phase 2, not "when there's time for polish".
2. **The showing off.** One tap from a sighting to a share card good enough to post
   without editing. This is also your entire marketing budget.
3. **The scarcity.** Points must feel earned. If everything is worth something,
   nothing is.

## Scoring

Seven rarity tiers, assigned by how hard the animal actually is to see in Kruger
— not by how famous it is. Lions are easier to find than sable.

**The authoritative table, with its behaviour, is in
[The daily scorecard](#the-daily-scorecard) below.** It is not repeated here,
because a tier table separated from its cooldown gets misread.

**Modifiers:**
- **Quiet Sighting: ×1.5** on base points — photograph an animal with no other
  vehicles present and prove it with a PanCapture. Available at every tier.
- Big Five and Big Six Birds carry a badge and a completion bonus, not extra
  base points.
- **First Find bonus** — see below.

There is no repeat penalty. Notable and above score in full, every encounter.

## The daily scorecard

**Each day is a fresh scorecard.** This is how the paper version worked and it
is the heart of the scoring system.

| Tier | Points | Behaviour |
|---|---|---|
| Common | 5 | **Scratched off** — scores once that day |
| Frequent | 15 | **Scratched off** — scores once that day |
| Notable | 30 | **Stays live** — scores again per encounter |
| Rare | 60 | Stays live |
| Very rare | 100 | Stays live |
| Exceptional | 200 | Stays live |
| Legendary | 400 | Stays live |

Your first impala of the day scores; the next forty are scenery. Same for
elephant, giraffe, hippo. Every lion, leopard, wild dog and pangolin scores
again, every time.

This gives each day a natural arc: you clear the common list in the first hour,
and after that the only thing moving your score is something worth stopping for.

**Days sum into trips. Trips sum into the season.** A ten-day trip is not ten
times as valuable as one brilliant morning.

### The cooldown — and it must never be documented apart from the table above

**"Stays live" means per encounter, never per shutter press.**

> Same species, roughly the same location, within one hour counts once.
> Enforced from the GPS trace.

- A leopard at 07:00 near Skukuza and another at 15:00 near Satara: **two
  sightings.**
- Forty photos of one leopard over two hours: **one sighting.**

Once GPS is in, the cooldown also releases on distance: **one hour, or ~2 km
moved, whichever comes first.** Kruger's limit is 50 km/h and the roads are
slow, so 2 km is several minutes of real driving — not something you can fake
sitting at one sighting.

Wherever the tier table appears without the cooldown beside it, someone reads
"stays live" as unlimited. That has already happened once. Keep them together.

### Photos inside the cooldown are never rejected

A photo taken during a cooldown **attaches to the existing encounter** as
another photo of it. You keep every picture; you are simply not paid twice for
the same animal.

Everybody takes eight photos of a leopard. Eight zero-point entries cluttering a
profile would be worse than useless.

### The Codex is lifetime; the scorecard is daily

These are different things and both matter:

- **Score** resets every day, sums into trips, sums into the season
- **The Codex never resets.** It is a record of everything you have ever seen

The profile shows a species with every encounter beneath it:

```
Leopard  ·  3 encounters
  ├─ 12 Jul 2027, 06:14   Sabie River     60 pts   ✓ verified
  ├─ 12 Jul 2027, 17:40   Nkuhlu          60 pts   ✓ verified
  └─ 14 Jul 2027, 05:52   Lower Sabie     60 pts   ✓ verified
```

Note that repeats score in full — Notable and above stay live. There is no 10%
repeat penalty; an earlier draft had one and it is gone. Breadth is rewarded by
**Codex completion and crowns**, not by devaluing a second leopard.

## "Not sure what it was"

Sometimes you photograph something and genuinely do not know what it is. A
mongoose at forty metres; an eagle against the sun. Forcing a guess produces
wrong data and an anxious player.

So identification is **skippable**. The photo is saved with its GPS and
timestamp, and sits in the profile as **Unidentified** until named. Identify it
that evening in camp, or a week later at home, with the Codex to hand.

Two rules:

1. The **timestamp and location are captured at the shutter**, not at
   identification. Naming it later must never let someone claim a sighting from
   somewhere they were not.
2. An unidentified photo **scores nothing until it is identified**, then scores
   normally against its original capture time — including for the cooldown and
   First Find checks.

This also makes the app better at the thing a field guide is for. Not knowing
is the normal condition of a person new to the bush, and an app that punishes it
teaches them nothing.

## Solo finds vs. joining a sighting

In Kruger, most people see lions because fifteen cars are already parked there.
Finding an animal yourself is a completely different achievement from driving up
to a traffic jam, and if both score the same then the leaderboard rewards
whoever passed the most crowds.

**This is detectable.** Sightings of the same species within a few hundred
metres and a couple of hours are one *sighting event*. The earliest capture
timestamp in that cluster is the finder; the rest joined.

Design rules, in order of importance:

1. **Capture the data from day one, ship the feature much later.** Every
   sighting stores a precise GPS fix and capture timestamp from Phase 3. Clusters
   can be computed retrospectively over historical data at any point; data you
   never captured is gone forever. This is the only part that must be right now.
2. **It needs density to work.** Fifty users across 20,000 km² will essentially
   never cluster. The feature improves as the app grows, which makes it a reward
   for growth rather than a launch dependency. Do not block Phase 5 on it.
3. **Bonus, never penalty.** The first finder gets a *First Find* bonus. Joiners
   are not docked — they did see the leopard, and it belongs in their collection.
   The collection records what you have seen in your life and must stay honest;
   the score records difficulty. Keeping those separate is what makes both feel
   fair.
4. **Ordering is server-assigned.** A device timestamp is a number a phone can be
   made to say anything. Capture time is recorded on device out of necessity —
   you are offline — but rank within a cluster is validated server-side at sync.

### The safety rule this creates

**Reward finding. Never reward arriving.**

A bonus for getting somewhere first is a bonus for speeding, for crowding
animals, and for cutting people off at a sighting. There must therefore be:

- No live feed of other people's sightings
- No "lion reported 4km north"
- No visible race, countdown or contested state

The bonus is computed quietly at sync. **You find out you were first when you
get home.** This is consistent with the ban on live sighting maps in
[VISION.md](VISION.md), and for the same reason: chasing animals is bad for the
park, and it would end any SANParks relationship before it started.

## Screen structure

Three tabs. The order matters: your own achievement first, the goal second,
other people third.

### 1. Profile — *your* record

Opens on **your lifetime score**, large and unmissable. That single number is
the summary of everything you have ever found, and it is what a player checks
first.

Tapping the score opens **everything you have ever caught**, newest first. A
recency sort, not alphabetical — the most recent catch is the one you want to
show someone, and the one you are still pleased about.

Tapping any entry opens **the card of the animal you caught**: your photograph,
the species, the date, your nickname for it, its rating, and a **verified
check mark**.

That check mark is doing real work. It is the visible proof that this was
photographed by you, in the park, on that date — the thing the paper scorecard
could never do. It must never appear on anything unverified.

**Lifetime, not seasonal.** The leaderboard resets each season; the profile
never does. See [VISION.md](VISION.md) — permanence is one of the three feelings
the product exists to protect.

### 2. Animal Dex — the goal

Every species in the park: photograph, dex number, short summary, points. Free,
offline, useful before you have caught anything. The hook.

### 3. Leaderboard — everyone else

Other trackers ranked on verified sightings for the current season. Phase 5.

Each row shows:

| Stat | Why it is there |
|---|---|
| **Rank** | The point of the screen |
| **Tracker name** | Who |
| **Season score** | The primary ranking |
| **Species held** | Breadth — `43 / 71`. A different achievement from raw score |
| **Trips** | Times entered the park this season |
| **Rarest catch** | The single best animal. The bragging line |
| **First Finds** | How often they found it before anyone else |

Tapping a row opens that tracker's public profile: their collection, their
rarest finds, their season. **Never their sighting locations**, and never
anything for a sensitive species beyond the fact that they have one.

#### Counting trips without extra tracking

A **trip** is derived from sightings, not from a separate check-in: a new trip
begins when more than 48 hours pass with no sighting. No GPS geofence to
maintain, no button to forget to press, and it works entirely offline.

Someone who spends a day in the park and logs nothing records no trip. That is
correct — the game only knows about you when you play.

#### Crowns, not more leaderboards

Ranking on season score alone makes this a **wealth leaderboard**: whoever can
afford ten trips a year beats whoever manages one. A family who comes once a
year could never place anywhere, and they are most of the market.

An earlier draft answered that with four boards, including a **best single
trip**. That was wrong — [MASTER-VISION.md](../MASTER-VISION.md) forbids it
explicitly:

> Never build a "most sightings today" leaderboard. It rewards racing between
> sightings, which is exactly what the Quiet Sighting bonus exists to discourage.

Best-single-trip is that mechanic with a different window. Dropped.

**The answer is Species Crowns.** Every species has a seasonal holder — the
player with the most verified sightings of it. Seventy-one species means
seventy-one separate competitions and seventy-one chances to be best at
something. A first-timer who gets lucky with a pangolin holds that crown
immediately, which is a far better story than being ranked 4,318th.

Alongside crowns:

- **Ranks** — Day Visitor → Tracker → Ranger → Field Guide → Head Ranger →
  Legend. Earned by breadth across every trip ever taken. Crowns reward one
  brilliant sighting; ranks reward persistence.
- **Codex completion** — per category, see below. Rewards years, not money.

Quick Logs never earn crowns. No photo means no proof.

Friends-and-family groups matter more than any global board for most people. The
paper scorecard was always five people in one car.

#### Completion is per category

The Codex splits into **Mammals / Birds / Reptiles with independent completion
percentages.**

Birders are the most obsessive list-keepers on earth and a large slice of
self-drive visitors, so birds and reptiles stay in — but a mammal-focused player
staring at 30% forever is demoralised by a number that is not measuring what they
are actually doing. Three bars, three achievements.

Crowns work per species regardless of category.

## Nicknames

Players can name what they catch. "Skukuza Queen" for your first leopard.

Costs almost nothing to build and does a disproportionate amount of work: a
named animal is one you are attached to, and attachment is what makes a
collection worth keeping. Optional, editable, never shown on the leaderboard
without the species name alongside it.

## The capture flow

Tap camera → **choose the species** → shoot → **review** → save.

The review step matters: after the shutter, the player sees the shot and either
keeps it or retakes. Nobody wants their pangolin recorded as a blurred smear
because the app saved the first frame automatically.

### The order, and the risk in it

There are two possible orders, and this is a genuine trade-off:

| | Flow | Cost |
|---|---|---|
| A | **Pick species, then shoot** | You are scrolling a list while the leopard walks off |
| B | Shoot, then pick species | The reveal is two taps away instead of instant |

**We do A**, as specified above — it is the clearer mental model and it is what
the app is being designed around.

**The risk, stated plainly:** animals leave. A player who misses a leopard
because the app made them scroll a menu first will be angrier than one who had
to tap twice after the shot. If field testing shows people missing sightings,
this is the first thing to revisit.

Two mitigations, both worth building in from the start:

1. **The picker must be fast enough not to matter.** A search field above a grid
   of species tiles — the *same tiles as the Codex*, so the app teaches the
   picker for free and there is one card design to maintain.

   **Search is the fallback, not the primary action.** Tiles are ordered by what
   is plausible here and now — this park region, this time of day, what has been
   logged recently, what you have caught before. Done properly, the animal you
   are looking at is in the first six tiles and no typing happens at all. If a
   player has to search on most captures, the ordering is wrong and that is the
   bug to fix.
2. **A "shoot now, name later" escape.** A prominent *Not sure / just shoot*
   option on the picker goes straight to the camera and saves the photo as
   Unidentified. That is the same mechanism as the "Not sure what it was" flow
   below, and it means nobody ever loses a sighting to a menu.

Whichever order, two things never change: the photo is written to disk with GPS
and timestamp **at the shutter**, and nothing sits between saving and the
reveal — no spinner, no network call.

## What does *not* affect points

Two things that look like they should score, and must not.

**Photo quality.** The app never grades your photograph. A blurry, badly-lit
pangolin at forty metres in the dark is worth 500. A magazine-quality impala
portrait is worth 5.

Reward photo quality and you have built a different product — a wildlife
photography contest, won by whoever owns a 600mm lens and a beanbag. This is a
*spotting* game. The skill being rewarded is **finding the animal**, which is
what people are actually competing at. The photograph's only jobs are to prove
you were there and to be worth showing someone.

**Distance travelled.** Distance is used solely to decide whether a second
sighting is a genuinely different animal — it releases the cooldown, it never
awards anything. Paying for distance would reward driving hard and fast through
a park with a 50 km/h limit and animals on the road, which is precisely the
behaviour the app must not encourage.

## Verification

v1 is deliberately not machine learning. Three signals, all cheap and all honest:

1. **Camera only.** In-app capture. No gallery import, ever. Not a setting.
2. **GPS inside park boundaries** at the moment of capture, stored with the photo.
3. **Device timestamp** at capture.

Offline is the normal case — most of Kruger has no signal. Sightings are written
locally and sync when the phone reconnects. The GPS fix and timestamp are captured
at the moment of the photo, so an offline sighting is exactly as trustworthy as an
online one.

### The hole this leaves, and how it closes

Since the player names the species themselves, someone can photograph a bush and
call it a pangolin. Worth stating plainly rather than pretending otherwise.

It matters far less than it sounds, for one reason: **the photo is the receipt.**
It sits on their profile and on every share card. A fake pangolin is a picture of
a bush that they have to show people. The whole point of the app is showing off,
and you cannot show off a lie.

Beyond that, three defences, cheapest first:

1. **Tier-gated verification.** Common and Frequent sightings count instantly —
   nobody fakes an impala. **Legendary and Very Rare sightings enter the
   collection immediately but do not hit the public leaderboard until reviewed.**
   The player gets their reveal and their card straight away; the leaderboard
   just settles a bit later. Integrity where it matters, no friction where it
   does not.
2. **Community flagging** (Phase 6). Rare sightings by top-ranked players are
   visible and flaggable. Cheating a leaderboard nobody can see is not fun;
   cheating one everybody can see is hard.
3. **ML as a sanity check, not an oracle** (Phase 6+). Not "identify this
   animal", which is a hard problem — just "this does not look like a pangolin",
   which is an easy one. Use it to route things to review, never to reject a
   sighting outright. A model that wrongly rejects a real pangolin would be
   unforgivable; one that quietly asks a human is fine.

## The species catalogue must be updatable without an app release

Tiers, sensitivity flags, descriptions and new species all change. Today the
catalogue is a JSON asset compiled into the binary, so changing a single rarity
tier means a store submission and a review queue.

That is unacceptable for one field in particular. **If a sensitivity flag needs
changing urgently — a new poaching hotspot, a wild dog den discovered — waiting
three days for app review is not an option.**

### What is needed

A **versioned catalogue** that syncs on connect and caches locally:

- The catalogue carries a monotonic `version`
- On any connection, the app asks the server for the current version and pulls a
  delta if it is behind
- The bundled JSON remains the **fallback**, so a fresh install works offline at
  the gate with no signal, which is exactly where installs happen
- The cached copy is what the app reads. Never block startup on the network.

### Why this cannot wait

Retrofitting it means migrating a live user base off a compiled asset while
their local sightings reference species ids. Building it before there are users
costs a day; building it after costs a migration.

Do it in the backend phase, alongside the first schema.

### The safety rule it enables

A sensitivity change must be able to reach a player **already in the park**, on
their next moment of signal, without an update. That is the point of the whole
mechanism.

## Sensitive species

**Sensitivity is a per-species data field, not a hardcoded list.**

The current model — a boolean `isSensitive` set on three species — is an
if-statement waiting to be wrong. Poaching pressure moves. The real list is
longer than rhino and pangolin and it changes over time: **ground hornbill,
vultures at nest sites, and any denning wild dog site** all warrant care.

Replace it with `sensitivityLevel`, updatable via the catalogue sync above
without an app release:

| Level | Behaviour |
|---|---|
| `none` | Location stored and shown normally |
| `coarse` | Stored and displayed only at a coarse grid — region-level, never a pin |
| `never` | Coordinates never rendered anywhere: not on a profile, a leaderboard, a share card, an export, or to friends. Stored encrypted; the sighting still scores. |

Rhino and pangolin are `never`. Others will be added, and some will move
between levels as circumstances change — that is the point of it being data.

**Enforce on both client and server.** This is a correctness invariant, not a
feature. If it fails, an animal dies.

## Monetisation

- **Season Pass** — one non-renewing annual purchase, ~R249. Unlocks the
  leaderboard, the full collection and share cards.
- **Free tier** — the Codex (the field guide) is free and always works. It is the
  hook and it is genuinely useful, which is what gets it recommended.
- **Later** — regional challenge packs, printed end-of-season collection cards,
  guided-operator tie-ins. Never pay-to-win on the leaderboard.

## Phases

| # | Phase | Contents |
|---|---|---|
| 0 | Validation | Post the concept in Kruger communities. Get 30 people saying they'd pay. Costs one evening. |
| 1 | **Species Codex** | Field guide: every species, rarity, points, regions, where and when to find them. No camera, no GPS, no account. ← **you are here** |
| 2 | Capture & collection | Camera capture, local storage, the reveal animation, the collection view with silhouettes for unfound species, share cards. Still offline-only, still no account. |
| 3 | Map & verification | Offline park map, GPS at capture, region tracking, night-drive multiplier. |
| 4 | Accounts & sync | Supabase auth, sighting sync, multi-device. |
| 5 | Leaderboard & Season Pass | Seasonal standings, RevenueCat, the annual reset. |
| 6 | Social | Friends, community flagging, group trips, the family scoreboard you actually played on paper. |

Phases 1–3 are a complete, sellable, offline product on their own. If the project
stops at Phase 3 it is still worth having built.

## Future: multiple reserves

Not built now. Kruger ships first, done properly. But the intent is real —
Okavango Delta, Masai Mara, Etosha, Addo — and it is the direct analogue of
Pokémon's regions, each with its own dex.

**The decision that must be made now is the data model, not the feature.**
Retrofitting a second reserve onto a schema that assumes Kruger is a rewrite;
allowing for one costs almost nothing today.

### The trap: rarity is reserve-specific

This is the part that would quietly break everything.

A cheetah is **Rare (100 points)** in Kruger — a genuine piece of luck. In the
**Masai Mara it is close to guaranteed** on a three-day trip. A sable is a
northern-Kruger prize and essentially absent from the Mara. Wildebeest are
ordinary in Kruger and the entire reason people visit the Mara in season.

So **`rarityTier` cannot live on the species.** It belongs on the pairing of
species and reserve. A single global rating would make the Mara trivially
farmable and destroy any shared leaderboard — the first person to fly to Kenya
would top a Kruger table with 40 cheetah sightings.

Same for `parkRegions`: `southern / central / northern` are Kruger's regions,
defined by its two rivers. They mean nothing in the Delta.

### What that implies

| Concept | Today | With reserves |
|---|---|---|
| Species | Rarity, points, regions on the record | Identity only: names, description, IUCN status, photo |
| Reserve | — | Kruger, Okavango, Mara… each with its own boundary, regions and dex |
| Species-in-reserve | — | Rarity, points, local regions, seasonality, dex number |
| Leaderboard | One | **Per reserve.** A global one is meaningless when points are not comparable |
| Dex number | Global | **Per reserve**, exactly like Pokémon's regional dexes |

Your collection stays global and lifetime — you caught a leopard, wherever you
were. Only *scoring* is reserve-scoped.

### When to do it

Not before Kruger is live and someone other than you has played it. But when
Phase 4 designs the backend schema, **design it with a `reserve` table from the
start**, even with exactly one row in it. That is a few hours then, and a
migration nobody wants later.

## Data accuracy

Distribution, seasonality and rarity in `species.json` are a solid first pass, not
gospel. Before launch, get a Kruger guide or an SANParks contact to review the
tier assignments and regional ranges. Getting Sable's range wrong is the kind of
error that loses you the exact users who care most.
