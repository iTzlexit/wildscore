# Vision — what we are actually building

> This is the working north star. [MASTER-VISION.md](../MASTER-VISION.md) is
> canonical and wins any disagreement; this document expands it with the
> reasoning behind decisions made since.
>
> Re-read before starting any phase.

---

## The one sentence

> **Wild Score is where your Kruger sightings live, so you can visit them when
> you miss the park.**

Everything serves that. When a design decision is unclear, choose whichever
option better preserves a memory.

**This is a memory box first and a game second.** The competition exists to make
the collection worth building — not the other way round. That ordering is easy
to lose, and losing it produces a worse product *and* a worse business.

### Why the ordering is commercial, not sentimental

> People don't resent paying to keep a photo album. They resent paying for
> leaderboards.

That sentence decides the monetisation. An earlier draft of this project put the
paywall on **submitting your day's score** — which felt clever, because it lands
at the moment of peak motivation. It was wrong. Charging to submit a score *is*
charging for a leaderboard.

What people will pay for is **keeping their photographs, beautifully**: the
Collection of Six and the Den. See [MONETISATION.md](MONETISATION.md).

If this document ever drifts back toward "competitive game", that error comes
back with it.

---

## The moat

Anyone can build a wildlife checklist. Nobody can build **a collection you had
to physically travel to earn**.

The photo of your caracal, taken at 6:40am near Lower Sabie on the morning it
crossed the road, is unique and unfakeable.

> **Every design decision that trades away photo prominence for game mechanics
> is the wrong call.**

---

## The three loops

**During the drive.** Spot, log or capture, watch the daily score climb. Fast,
offline, in a moving car. **Quick Log must take under three seconds from app
open** — an app that takes eight seconds per sighting does not get used at all,
and every other mechanic depends on people actually logging things.

**At the end of the day.** The sync ritual: cards flip from pending to verified,
points confirm, crowns change hands. Designed deliberately, never hidden behind
a spinner.

**Between trips.** The den, the Codex, your crowns, other people's collections.
**This is the loop that keeps the app alive in October when the next trip is in
July** — and it is the loop the "competitive game" framing forgets entirely.

---

## Where it came from

A family trip to Kruger, and a scorecard on paper. Everyone in the car keeping
their own tally, arguing about whether a glimpse of a tail counts, comparing
totals at the gate. The game was better than the drive.

The paper version has three problems, and the app exists to solve exactly these:

1. **Nothing is verified.** Whoever argues hardest wins.
2. **Nothing survives the trip.** The scorecard gets thrown away at the gate.
3. **Nobody outside the car ever sees it.**

Problem 2 is the one that matters most. It is the whole product.

---

## The feelings we are protecting

**1. The reveal.** A silhouette resolving into colour, the entry unlocking, data
writing itself in. Same animation for every species, scaled in length and
intensity by rarity. A pangolin reveal should stop the room.

**2. Permanence.** The Codex is lifetime and never resets. Seasons reset crowns
and scores; your collection is forever. That is what makes it worth visiting.

**3. The showing off.** One tap from a sighting to something worth posting. This
is not a nice-to-have — **it is the marketing channel.** The niche is small and
the incumbent took years to reach ~9,000 installs. Building the app is the easy
half.

> **A discipline note.** Pokémon is the internal design reference and nothing
> more. No public-facing name, icon, tagline or store listing may evoke it — not
> "poke", not "dex", not "mon". The inspiration is private; the product is its
> own thing.

---

## Language

The player is a **Spotter**.

Not a "Tracker" — that is rank two of six in the progression (Day Visitor →
Tracker → Ranger → Field Guide → Head Ranger → Legend), and using it as the
player noun would promote everyone on signup. *Spotter* is neutral, matches the
game's language, and reads correctly in both English and Afrikaans contexts.

---

## Non-negotiables

Settled. Not open to being traded away later under deadline pressure.

**Camera capture only.** No gallery path exists, for Capture. Quick Log needs no
photo at all — but a photo, once claimed, must have been taken in the app.

**The app is light, not dark.** MASTER-VISION.md originally specified a dark
theme on the reasoning that dark makes photographs glow and a white screen at
5am in a game vehicle is antisocial. Overruled by Alex on 2026-08-02 after
seeing both: the dark build read as generic, and the light one does not.

The reasoning behind the original call was not wrong, so it survives as two
constraints rather than a theme:

- **Screen brightness at dawn and dusk matters.** If field testing shows the
  light theme is painful before sunrise, the answer is an automatic dark mode
  tied to time of day or system setting — not a return to dark-always.
- **Photographs still lead.** The interface is a warm near-white ground with
  colour reserved almost entirely for rarity, precisely so the animals remain
  the only saturated thing on screen.

**Species-level location privacy is data, not code.** Every species carries a
`sensitivityLevel` — `none` / `coarse` / `never` — that can be changed **without
an app release**. The obvious cases are rhino and pangolin, but the real list is
longer and it moves: ground hornbill, vultures at nest sites, any denning wild
dog site. A hardcoded list is an if-statement waiting to be wrong, and when it
is wrong an animal dies. This is a correctness invariant.

**Offline is the normal case.** Most of Kruger has no signal. GPS works without
it. Everything except verification, uploads and viewing other players must work
with the phone in aeroplane mode for days.

**Provisional scoring.** The score shows live during the drive. The game must be
fun in the moment, not after sync.

**Rarity tracks reality.** Points reflect how hard an animal actually is to find.
If the scoring does not match what experienced visitors know, we lose exactly the
users who care most.

**No pay-to-win.** Money buys access and cosmetics. Never points, multipliers or
position.

**Nothing decays.** No hunger, no streaks, no guilt. Players are on holiday and
then back at work.

**No live public sightings map.** Real-time "where is the leopard" creates
crowding and poaching risk. A deliberate omission.

**No points for off-road positions or speeding.** Never incentivise breaking park
rules.

**The free tier must be genuinely good.** The model depends on someone finishing
day one proud of their score before being asked for money.

**POPIA compliance from day one.** Continuous location logging is sensitive
personal data.

---

## What this is not

- **Not a social network.** Sharing points outward, to WhatsApp and Facebook.
- **Not a conservation-data platform.** iNaturalist exists and is better at it.
- **Not a safari-booking app.** Scope creep dressed as business model.
- **Not AR, and not a live map of other people's sightings.**
- **Not multi-reserve at launch** — though it is coming, and the schema must
  allow for it from the backend phase. Rarity is reserve-specific: a cheetah is a
  prize in Kruger and routine in the Masai Mara, so a global rating would break
  every leaderboard. See [SPEC.md](SPEC.md#future-multiple-reserves).

---

## The test

Before building anything:

> **Does this help someone keep a memory, or make it easier to show someone?**

If neither, ask why it is in this release.
