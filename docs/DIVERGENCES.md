# Divergences from the original plan

The original [00-START-HERE](archive/00-START-HERE-original.md) was written
before any code existed and was never saved to disk — the first two days of
building happened without it. This records where the live docs disagree with it,
so nothing was changed silently.

**Everything not listed here still holds**, including Flutter over MAUI,
RevenueCat, the non-renewing R249 season pass, the iOS/Codemagic plan, the store
account requirements, and the four Pokémon feelings.

---

## Settled — not open questions

Confirmed by Alex 2026-07-26. Do not reopen without a new reason.

- **Supabase**, not self-hosted ASP.NET Core
- **Sensitive locations never rendered**, not coarsened to a grid — an
  invariant rather than a defence
- **The reveal lands in Phase 2**, with the camera
- **Do not adopt packages before there is a problem they solve**

---

## CONFIRMED — the scoring model, and the migration it requires

Confirmed by Alex 2026-07-26. Not yet implemented — no code has been changed.

### The model

**Each day is a fresh scorecard.**

| Tier (enum name) | Points | Behaviour |
|---|---|---|
| `common` | 5 | **Scratched off** — scores once that day |
| `frequent` | 15 | **Scratched off** — scores once that day |
| `notable` | 30 | Stays live, 1h cooldown |
| `rare` | 60 | Stays live, 1h cooldown |
| `veryRare` | 100 | Stays live, 1h cooldown |
| `exceptional` | 200 | Stays live, 1h cooldown |
| `legendary` | 400 | Stays live, 1h cooldown |

Enum names are the display names, so the two can never drift apart.

### "Stays live" means per encounter, never per shutter press

**The rule:** same species, roughly the same location, within one hour counts
once. Enforced from the GPS trace.

- A leopard at 07:00 near Skukuza and another at 15:00 near Satara: **two
  sightings.**
- Forty photos of one leopard over two hours: **one sighting.**

**The tier table and the cooldown must always appear together.** Wherever they
are separated, someone reads "stays live" as unlimited — which is exactly what
happened here. Never document one without the other.

### Migration — every touchpoint

Two tiers disappear (`uncommon`, `scarce`) and two change meaning
(`rare` 100→60, `veryRare` 250→100). **Every species currently in a deleted or
revalued tier must be re-assigned by hand, not mapped mechanically** — the point
of the change is that the curve is different, not just renamed.

Current distribution, all 71 species need review:

| Current tier | Count | Likely new tier |
|---|---|---|
| `frequent` | 17 | `frequent` (10→15 pts) |
| `scarce` | 16 | **deleted** — split between `rare` and `notable` |
| `common` | 13 | `common` ✓ |
| `rare` | 10 | **revalued** 100→60, or promote to `veryRare` |
| `uncommon` | 7 | **deleted** — likely `notable` |
| `veryRare` | 5 | **revalued** 250→100, or promote to `exceptional` |
| `legendary` | 3 | `legendary` (500→400) |

Files that must change together:

- `app/lib/domain/rarity_tier.dart` — the enum and its point values
- `app/lib/shared/theme.dart` — seven `RarityStyle` cases in a switch that will
  fail to compile until all seven names match. That is a feature: the compiler
  finds them.
- `app/assets/data/species.json` — 71 `rarityTier` values
- `app/test/species_model_test.dart` — asserts all seven point values, plus a
  fixture using `legendary` and asserting 500
- `app/test/species_data_test.dart` — asserts every tier is populated
- `docs/SPEC.md` — the tier table, and the repeat-sighting section, which
  currently describes a lifetime model rather than a daily scorecard

Do the enum first and let the analyzer enumerate the rest.

### What we built instead — to be replaced

| Ours | Points | Maps to | Their points |
|---|---|---|---|
| common | 5 | Common | 5 ✓ |
| frequent | 10 | Frequent | **15** |
| uncommon | 25 | Notable | **30** |
| scarce | 50 | Rare | **60** |
| rare | 100 | Very rare | 100 |
| veryRare | 250 | Exceptional | **200** |
| legendary | 500 | Legendary | **400** |

**The dangerous part is the naming, not the numbers.** Our `rare` is 100; their
*Rare* is 60. Our `veryRare` is 250; their *Very rare* is 100. Any conversation
using tier names without numbers will produce a wrong answer until this is
fixed. Rename before anyone reviews the species data.

### The structural change is bigger than the numbers

The daily-scorecard model **replaces** what is currently specced:

| Currently in SPEC.md | Current model |
|---|---|
| First sighting full points, repeats at 10% | Common/Frequent score once per day; Notable+ score every time |
| Lifetime scoring | Fresh scorecard every day |
| One-hour per-species cooldown | *Unresolved — see below* |

The daily scorecard is closer to the paper game and I think it is right. The
lifetime **collection** still stands alongside it: score is per-day, collection
is forever.

**It also makes the leaderboard simpler** — "best single day" stops being a
special board and becomes the natural unit.

### Resolved: the farming hole

Raised as an open question, now closed. "Stays live" never meant per shutter
press — see the cooldown rule above. The ambiguity was in the document's
phrasing, not in the intent.

---

## Resolved differences

### Backend: Supabase, not ASP.NET Core + your own hosting

**Original:** ASP.NET Core 9, EF Core, ASP.NET Identity + JWT, Cloudflare R2,
Render or Azure.

**Now:** Supabase — see [TECH-STACK.md](TECH-STACK.md).

**Why:** that stack is five separate things to build and operate (API, identity,
blob storage, hosting, deployment) before a single user can see anything.
Supabase gives Postgres, auth, photo storage and row-level security on day one.
Alex's backend experience still applies — it goes into schema design and RLS
policies, which *is* backend work.

**Reversible:** Supabase is plain Postgres. If it is outgrown, put ASP.NET Core
in front of the same database. Nothing here is one-way.

### No packages in Phase 1; Riverpod and Drift deferred

**Original:** Riverpod, Drift, dio from the first commit.

**Now:** Phase 1 shipped with **zero** third-party packages.
`shared_preferences` was added only when the tracker profile needed to survive a
restart.

**Why:** two screens over a read-only JSON asset need `Navigator` and
`setState`. Every package added before it is needed is a version-resolution
problem standing between you and your first successful build.

**This was vindicated:** Riverpod is now on **3.x** with a substantially
changed API — `StateNotifier` gave way to `Notifier`, and most tutorials are
still written for 2.x. Adding it on day one would have meant writing 2.x-shaped
code against a 3.x library.

### sqflite before Drift

**Original:** Drift for local persistence.

**Now:** `sqflite` in Phase 2, with Drift only if the queries get complex.

**Why:** Drift needs build_runner code generation, which is another workflow to
learn while also learning Flutter. Plain SQL is already familiar.

### Sensitive species: never rendered, not coarsened

**Original:** coarsen sensitive locations to a ~25 km grid.

**Now:** rhino and pangolin locations are **stored encrypted and never rendered
anywhere** — not on a profile, a leaderboard, a share card or an export.

**Why:** stricter, and simpler to guarantee. A coarsening bug leaks a location;
a never-render rule has nothing to leak. There is a test enforcing the flag.

### The reveal and share card moved to Phase 2

**Original:** build both in Phase 1.

**Now:** Phase 1 was the Codex only; the reveal lands with the camera in Phase 2.

**Why:** there is nothing to reveal before capture exists. The onboarding
tracker-card animation was built as a deliberate cheap rehearsal of it.

**Still agreed:** these are product, not polish, and must not be deferred again.

---

## Ideas from the original plan that are *not* yet in the live spec

These are good and were lost when the file was not saved. Reconsider each before
Phase 3.

### PanCapture — the 360° gyroscope pan — CONFIRMED, returning

A gyroscope trace proving the phone physically swept the scene. **The only
preventive control in the whole design** — everything else (tier-gated review,
community flagging, ML checks) is reactive. It defeats the one attack
camera-only capture cannot: photographing a screen or a printed picture.

**It does double duty**, which is why it earns its complexity: anti-fraud *and*
anti-crowding.

**Rules, as amended by Alex** — my original proposal was to gate it to the top
tiers entirely, and that was wrong:

- **Optional at every tier.** Never required to log a sighting.
- **Earns the Quiet Sighting bonus at any tier.** Its primary job is
  behavioural. Rewarding someone for being alone with a herd of elephants is
  exactly as valuable as rewarding it for a leopard, and it is the mechanic that
  keeps people off the crowded roads.
- **Effectively required for crown eligibility at Very rare and above**, where
  leaderboard integrity actually matters.

Gate by tier for *fraud*; keep the bonus universal for *behaviour*. Those are
two different jobs and only one of them scales with rarity.

### Quiet Sighting bonus — CONFIRMED

Not a separate mechanic: it is what PanCapture earns. See above.

### Species Crowns

Being the top holder of a given species. A per-species leaderboard, which gives
far more people something to win than a single global table — the same reasoning
behind the four boards in [SPEC.md](SPEC.md).

Crown eligibility at Very rare and above requires PanCapture.

### Vehicle Pass — R499 for five players on one trip

Directly serves the actual use case: a family in one car. The paper scorecard was
always five people in a vehicle. Likely a better seller than the individual pass.

### The three-state Codex — needs confirming against our build

Alex describes three states per species:

1. **Undiscovered** — silhouette
2. **Logged** — stock image
3. **Verified** — the player's own photo **replaces the stock image
   permanently**, plus a verification tick

**What we built has only two states**: locked (photo desaturated to near-black
with a question mark) and unlocked (stock photo). There is no logged-vs-verified
distinction and no photo replacement.

The player-photo-replaces-stock idea was independently reached during Phase 1
and written into `assets/species/README.md` — good, it is the same conclusion.
But **the middle state is missing**, and it implies a verification pipeline
(logged → verified) that the live spec does not yet describe. What makes a
sighting move from logged to verified?

### Ranks, the Collection of Six, the Den, the Wild Card

**Named but not described anywhere I can see.** These are in
`MASTER-VISION.md` and `COLLECTION-AND-DEN.md`, which are not in the repo.
Cannot place them in the roadmap without reading them.

"Collection of Six" is presumably the Big Six Birds, which the dataset already
tags — but I am guessing, and guessing at product definitions is how features
get built wrong.

---

## What still needs a decision from Alex

Blocked on `MASTER-VISION.md`, which is still not in the repo:

1. **The logged → verified pipeline.** Three Codex states are confirmed, but not
   what moves a sighting from *logged* (stock image) to *verified* (player's
   photo replaces it permanently). Is verification automatic on capture, or does
   something have to happen first? This determines whether the middle state
   lasts seconds or days.
2. **Ranks, Collection of Six, the Den, the Wild Card.** Named, never described.
   Cannot be placed in the roadmap.
3. **The offline sync ritual** — referenced as being in MASTER-VISION.md.

Answerable now, without the document:

4. **Re-tiering all 71 species.** Two tiers are deleted and two revalued, so
   every species needs a human decision. This wants the Kruger guide's review
   doing at the same time — one pass, not two.
5. **Whether the daily scorecard replaces the lifetime score on the profile**,
   or sits alongside it. The Today/Lifetime toggle already built assumes
   alongside, which seems right: score is per-day, collection is forever.

## Missing source documents — still missing

Four documents are referenced as canonical and **none is in the repo or anywhere
on this machine** (searched the repo, `KrugerPoke`, Downloads, Desktop,
Documents):

- **`MASTER-VISION.md`** — stated to be canonical, written last, supersedes the
  others
- `SPEC.md` (the original, not ours)
- `VERIFICATION-AND-PROGRESSION.md`
- `COLLECTION-AND-DEN.md`

Everything in this file about the rarity table, the three-state Codex and
PanCapture comes from **Alex describing them in chat**, not from reading the
documents. That is enough to correct the scoring model; it is not enough to
place Ranks, the Collection of Six, the Den or the Wild Card.

Pasting the contents into chat works as well as attaching the files.
