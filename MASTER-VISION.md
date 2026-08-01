# Wild Score — Master Design Document

**This is the canonical description of the app. Where any other document
disagrees with this one, this one wins.**

> Transcribed into the repo 2026-07-26. Two clarifications supplied alongside it
> and not in the original text:
>
> - **Quiet Sighting multiplier: ×1.5 on base points.** A valid pan is a
>   continuous ~360° sweep over 3–5 seconds, with a gyroscope trace that agrees
>   with the visual motion. No minimum frame count — that is an implementation
>   call.
> - **Codex logged → verified is automatic.** A verified capture upgrades the
>   entry on sync; there is no separate action.
> - **No full 45-species list exists anywhere.** Only the tier examples below.

## The one sentence

**Wild Score is where your Kruger sightings live, so you can visit them when you
miss the park.**

Everything below serves that. When a design decision is unclear, choose
whichever option better preserves a memory.

This is also the business model. People don't resent paying to keep a photo
album. They resent paying for leaderboards.

## What it is

A real-life Pokédex for Kruger National Park.

You drive through the park. You log what you see. Common animals are a single
tap; rare ones make you reach for the camera. Everything is verified by where
you actually were. Your sightings build a lifetime Codex, your best six become
collectible cards with your own photographs, and those six live as animated
animals in a den you can visit whenever you miss the bushveld.

It is a game, a field guide, a scorecard and a memory box — and the reason it
works is that you cannot cheat your way to a pangolin. You have to go.

## The three loops

**During the drive** — spot, log or capture, watch your daily score climb. Fast,
offline, in a moving car.

**At the end of the day** — the sync ritual. Cards resolve from pending to
verified, points confirm, crowns change hands. The day's scorecard closes.

**Between trips** — visit your den, browse your Codex, see how your crowns are
holding, look at other people's collections. This is the loop that keeps the app
alive in October when your next trip is in July.

## Core mechanics

### 1. The daily scorecard

Each day is a fresh scorecard. This is how the paper version worked and it's the
heart of the scoring system.

**Common and Frequent species are scratched off once spotted.** Your first
impala of the day scores; the next forty are scenery. Same for elephant,
giraffe, hippo.

**Notable and above stay live all day.** Every lion, leopard, wild dog and
pangolin scores again, every time.

This gives each day a natural arc: you clear the common list in the first hour,
and after that the only thing moving your score is something worth stopping for.

Days sum into trips. Trips sum into the season. A ten-day trip isn't ten times
as valuable as one brilliant morning.

### 2. Rarity tiers

| Tier | Points | Behaviour | Examples |
|---|---|---|---|
| Common | 5 | Scratched off for the day | Impala, zebra, wildebeest, kudu, warthog, baboon, vervet |
| Frequent | 15 | Scratched off for the day | Elephant, buffalo, giraffe, hippo, waterbuck, nyala, crocodile |
| Notable | 30 | Stays live | White rhino, spotted hyena, lion |
| Rare | 60 | Stays live | Leopard, cheetah |
| Very rare | 100 | Stays live | **Black rhino**, African wild dog, sable, roan, honey badger |
| Exceptional | 200 | Stays live | Serval, caracal, aardwolf, aardvark |
| Legendary | 400 | Stays live | Pangolin |

A single pangolin outweighs six leopards. That is true to how Kruger regulars
actually feel, and the scoring should reflect it.

> **Corrected 2026-07-26.** Black rhino was originally listed as Rare (60),
> below wild dog. That was an artefact of writing illustrative examples rather
> than thinking it through — black rhino are far fewer animals in much thicker
> bush and are genuinely harder to find. Moved to Very rare (100).

**Cooldown:** the same species at roughly the same location within an hour
counts once. Two hours parked at a leopard is one sighting, not forty. Enforce
from the GPS trace.

### 3. Two ways to record

**Quick Log** — one tap, no photo. Every species you see. Builds the Codex,
scores points, counts toward Wild Card objectives. Must take **under three
seconds from app open**, because the player is in a moving car.

**Capture** — camera, verified, keeps your real photograph. Eligible for the
six, the den, and Species Crowns.

The split creates the texture the game needs: a steady rhythm of small logs,
punctuated by adrenaline when something rare appears.

Up to **four photos per capture** improves verification confidence, but one is
always enough. Never punish a real sighting that couldn't be fully documented —
sometimes a leopard gives you two seconds.

### 4. The Codex — three states

| State | Appearance | Earned by |
|---|---|---|
| Undiscovered | Silhouette, locked, all data hidden | — |
| Logged | Full colour, stock reference image, complete field-guide data | Quick Log |
| Verified | Your own photograph as the card face, plus a verification tick | Camera capture |

The reveal is the emotional payoff of the entire screen. Silhouette resolving
into colour, the entry unlocking, data writing itself in. Same animation for
every species, but scaled in length and intensity by rarity — a pangolin reveal
should stop the room.

**The upgrade path matters.** A logged species shows a stock image; capture it
later and your photo permanently replaces it. This gives every common animal a
second collection layer, and completionists will chase good verified photos of
all 45 species long after they've seen them all.

**The Codex is lifetime and never resets.** Seasons reset crowns and scores.
Your Codex is forever. That is what makes it the thing you visit when you miss
the park.

### 5. Verification — trust the trip, not the photo

**Verify the session, not each individual image.**

A trip session opens when the device enters the Kruger boundary and stays valid
while the GPS trace is continuous, on known roads, at plausible speeds, within
gate hours. Everything captured inside a valid session inherits that trust.

Forging a coherent eight-hour trace along real park roads is more work than
simply driving there. That's the bar, and it's high enough.

Species verification runs server-side on sync via Claude vision, comparing the
photo against the player's claimed species.

**Flag, never reject.** AI will be wrong sometimes — a cheetah at dusk, a
distant leopard. High confidence auto-approves. Disagreement flags for review
with points held provisionally. The player can always request review. Nobody
loses a memory to a model's uncertainty.

### 6. The Quiet Sighting bonus

Photograph an animal with no other vehicles present, prove it with a 360° pan,
earn a multiplier (**×1.5 on base points**).

This does three jobs at once:

- Rewards patience and ethical safari behaviour instead of crowding a leopard
- The pan is the hardest thing in the app to fake — parallax, scene geometry and
  a gyroscope trace that must agree with the visual motion
- Gives skilled players a reason to seek quiet roads rather than radio-chasing

### 7. The Collection of Six

Six captured animals become the player's permanent, displayed collection.

Chosen originally to control storage costs, but it turns out to be good design:
scarcity forces a real choice. The pangolin or the caracal?

- Any verified capture can be promoted
- Swapping is free and unlimited — a better sighting should always displace an
  older one
- Displaced photos stay in personal history, they just leave the display
- Full-resolution server storage applies only to the six

**The card:** your real photograph as the face, in a frame whose treatment
escalates by tier — plain border for common, through to gold, animation and
holographic sheen for legendary. Species, points, date, location. Verified tick.
Quiet Sighting mark.

**The photo is the prize. The frame is the ceremony.**

### 8. The Den

A persistent space where your six exist as animated sprites, moving around. Tap
one and your real photograph opens, with where and when you took it.

The sprite makes it alive. The photo makes it yours. A cartoon-only den is
generic; a photo-only collection is a gallery. Together it's a pet you earned by
actually being there.

**Art direction:** stylised-realistic, not chibi. Animals must read as their
actual species — a caracal by its ear tufts, a pangolin by its shape. Clean,
warm, anatomically honest. Think modern nature game, not fantasy cartoon.

**Behaviour:** idle wandering, species-appropriate movement, time-of-day
awareness — resting in shade at midday, active at dawn and dusk. Reaction on tap
before the card opens.

**Explicitly never build:** hunger, decay, health, or anything that punishes
absence. Players are on holiday and then back at work. A den that guilt-trips
them turns joy into obligation.

Den-eligible species are limited to roughly **twelve** rare animals — leopard,
cheetah, lion, wild dog, caracal, serval, honey badger, pangolin, sable,
aardvark, aardwolf, black rhino. This controls art cost and makes the den a
status signal rather than a zoo.

### 9. Species Crowns and ranks

**Crowns, not a single leaderboard.** Every species has a current holder for the
season — the player with the most verified sightings of it.

> You hold the Caracal Crown for 2026.

Forty-five species means forty-five separate competitions and forty-five chances
to be the best at something. A first-timer who gets lucky with a pangolin
becomes the crown holder immediately. That's a far better story than being
ranked 4,318th.

Crowns are held, defended and lost. Past holders are preserved permanently in a
**Hall of Fame** — losing a crown shouldn't erase having held it.

**Ranks** run alongside, earned by breadth across every trip you've ever taken:

> Day Visitor → Tracker → Ranger → Field Guide → Head Ranger → Legend

Crowns reward one brilliant sighting. Ranks reward persistence. Both audiences
get something to chase.

**Quick Logs never earn crowns.** No photo means no proof.

**Never build a "most sightings today" leaderboard.** It rewards racing between
sightings, which is exactly what the Quiet Sighting bonus exists to discourage.

### 10. The Wild Card

A daily objective drawn fresh each morning alongside the new scorecard.

> Today's Wild Card: three antelope species, one raptor, and something from the
> cat family.

- Sends players looking at animals they'd otherwise drive past
- Makes a slow day — no leopard, no rhino — still feel like a win
- Gives Quick Logging purpose beyond bookkeeping
- Always achievable with normal driving. Never requires a specific rare animal.
- Generated locally at trip start so it works fully offline

### 11. Profile visiting

Browse other players: rank, crowns, Codex completion, their six, their den. Tap
an animal in someone's den and see the actual photo they took, where and when.

This is the base-visiting instinct from Clash of Clans, and it's your marketing
engine — it's the thing people screenshot.

**Never public under any setting:** precise locations for sensitive species, the
GPS trace, anything the player marked private. Region-level location only, ever.

Privacy controls from day one: full private mode, per-sighting private flag,
location granularity toggle. Default to the more private option wherever there's
doubt.

## Offline-first is a feature

Kruger has almost no data coverage. Assume zero connectivity for the entire
drive.

This is not a limitation. GPS works without cell signal — the receiver talks to
satellites directly. Photos, positions and timestamps write locally. Only
verification needs a network, and verification can wait.

**Provisional scoring is essential.** Show the score live during the drive. The
game must be fun in the moment, not after sync. Cards display a pending state;
points confirm on reconnection.

**The sync ritual** — design the reconnection moment deliberately. Back at camp,
connected, the app processes the day one card at a time, each flipping from
pending to verified, crowns announced. That's a genuinely good moment, and it
exists because of the constraint. Don't hide it behind a spinner.

**Must work with zero signal:** trip sessions, GPS logging, camera capture,
Quick Log, species selection, live scoring, Codex browsing, your own collection
and den, the end-of-trip summary.

**Can wait for signal:** AI verification, uploads, crown updates, viewing other
players.

## Non-negotiable constraints

| Constraint | Why |
|---|---|
| Camera capture only — no gallery path exists | The entire trust model depends on controlling the capture moment |
| Sensitive species locations never stored precisely | Geotagged sightings of high-value species are a poaching risk. Coarse grid or nothing. Enforce client and server side. This is a correctness invariant, not a feature — if it fails, an animal dies. **Amended 2026-07-26: this is a per-species `sensitivityLevel` field (`none` / `coarse` / `never`), updatable without an app release — not a hardcoded rhino-and-pangolin list. Poaching pressure shifts; ground hornbill, vultures at nest sites and denning wild dog sites all warrant care.** |
| The species catalogue must be updatable without an app release | Tiers, sensitivity flags and new species all change. A versioned catalogue that syncs on connect and caches locally. **Added 2026-07-26** — painful to retrofit. |
| No live public sightings map | Real-time "where is the leopard" creates crowding and poaching risk. Deliberate omission. |
| No points for off-road positions or speeding | Never incentivise breaking park rules. Detectable from the trace. |
| Nothing decays | No feeding, no guilt, no streak punishment |
| ~~Dark theme~~ | **Superseded 2026-08-02.** The app is light. The dark build read as generic; the light one does not. The underlying concerns survive as constraints — see [docs/VISION.md](docs/VISION.md) — but dark-always is no longer the rule. |
| The free tier must be genuinely good | The whole model depends on someone finishing day one proud of their score before being asked for money |
| POPIA compliance from day one | Continuous location logging is sensitive personal data |

## Monetisation

**Free forever:** camera capture, Quick Log, live scoring, daily scorecard, trip
summary, full Codex browsing.

**Season Pass — R199/year (R149 founding season), $14.99 international.**
Non-renewing, sold per season — not an auto-renewing subscription. For a
once-a-year activity, subscriptions create resentment and churn; a season pass
reads as buying into the year, and it aligns with the crown reset.

Unlocks: the Collection of Six, the Den, crown and leaderboard eligibility,
shareable scorecards, Quiet Sighting mode, badges.

**Vehicle Pass — R399 / $29.99**, up to five players on one trip. Safari is a
group activity; the paper version was always played by a whole car.

**Later:** park unlocks (Pilanesberg, Addo, Etosha), cosmetic den backdrops and
card frames, end-of-season printed poster.

**Per-territory pricing matters.** An international visitor already pays R602 per
person per day in conservation fees — $14.99 is invisible to them. A South
African family feels every rand.

## Build order

| Phase | Contents |
|---|---|
| 1 | Species Codex — browse, search, filter, three-state model, reveal animation |
| 2 | Trip sessions, GPS tracking, offline capture, Quick Log, daily scorecard, provisional scoring |
| 3 | Backend, sync queue, the sync ritual |
| 4 | Season Pass IAP, entitlements |
| 5 | Collection of Six, card rendering, tier frames, share export |
| 6 | AI verification, multi-photo confidence, review queue |
| 7 | The Den — sprites, behaviour, tap-to-photo |
| 8 | Profile visiting, privacy controls |
| 9 | Species Crowns, ranks, seasons, Hall of Fame |
| 10 | Wild Card objectives |
| 11 | Anti-fraud hardening — attestation, mock location, sun position, duplicate hashing |
| 12 | Multi-park expansion |

The Den is Phase 7, not v1. It's the most expensive thing in the project and
only makes sense once capture and verification work. It's also the most fun
part, so the temptation to build it early will be strong. **Resist.**

## Tech stack

**App:** Flutter + Dart. Riverpod for state, Drift for local database, camera,
geolocator, flutter_map with offline MBTiles, sensors_plus for the pan gyro
trace, RevenueCat for IAP.

**Backend:** ~~ASP.NET Core 9 + PostgreSQL + EF Core, Cloudflare R2, Render.~~

> **Superseded 2026-07-26 — Supabase.** Postgres, auth, object storage and
> row-level security on day one, with no server to operate. The original stack
> is five separate things to build and run before a single user sees anything.
> Backend skill goes into schema design and RLS policies, which is real backend
> work. Reversible: Supabase *is* Postgres, so ASP.NET Core can go in front of
> the same database later. Claude vision for species verification is unchanged.
> See [docs/TECH-STACK.md](docs/TECH-STACK.md).

**Why Flutter over MAUI:** the developer has never built mobile, so the C#
advantage is smaller than it looks — mobile concepts are the real learning
curve, and Dart is easy coming from C#. MAUI is weakest at exactly this app's
three hardest problems: camera control, offline maps, animation. Backend stays
.NET, where the developer's experience genuinely compounds.

## What makes this defensible

Anyone can build a wildlife checklist. What they can't build is a collection you
had to physically travel to earn.

The photo of your caracal, taken at 6:40am near Lower Sabie on the morning it
crossed the road, is unique and unfakeable. That's the moat. **Every design
decision that trades away photo prominence for game mechanics is the wrong
call.**

## The single biggest risk

Not the technology — all of it is tractable.

**Distribution.** The niche is small and the established incumbent took years to
reach roughly 9,000 Android installs. Building the app is the easy half; getting
it in front of self-drive Kruger visitors is the half that decides whether this
earns R2,000 a month or R30,000.

The share card is therefore not a nice-to-have. **It's the marketing channel.**
One tap from a sighting to something beautiful, or nobody ever hears about this.
