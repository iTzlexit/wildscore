# Divergences from the original plan

The original [00-START-HERE](archive/00-START-HERE-original.md) was written
before any code existed and was never saved to disk — the first two days of
building happened without it. This records where the live docs disagree with it,
so nothing was changed silently.

**Everything not listed here still holds**, including Flutter over MAUI,
RevenueCat, the non-renewing R249 season pass, the iOS/Codemagic plan, the store
account requirements, and the four Pokémon feelings.

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

### PanCapture — the 360° gyroscope pan

A gyroscope trace proving the phone physically swept the scene. **This is the
strongest anti-fraud idea in the original document and the live spec has no
equivalent.** It defeats the one attack camera-only capture cannot: photographing
a screen or a printed picture.

Worth building as an *optional* step for Legendary and Very Rare sightings,
where leaderboard integrity actually matters — not on every impala.

### Quiet Sighting bonus

A multiplier tied to not crowding an animal. Fits the safety-and-ethics thread
running through the live spec (reward finding, never reward arriving; no live
sighting feed). Needs a definition of "quiet" that cannot be gamed.

### Species Crowns

Being the top holder of a given species. A per-species leaderboard, which gives
far more people something to win than a single global table — the same reasoning
behind the four boards in [SPEC.md](SPEC.md).

### Vehicle Pass — R499 for five players on one trip

Directly serves the actual use case: a family in one car. The paper scorecard was
always five people in a vehicle. Likely a better seller than the individual pass.

### Ranks

Progression titles beyond raw score. Not described in the surviving text.

---

## Missing source documents

The original references **`SPEC.md`** and **`VERIFICATION-AND-PROGRESSION.md`**
from that session. Neither has ever been seen. They contained the original rarity
table, the trust model, Species Crowns and the rank system.

If they still exist, they are worth recovering — the current rarity table was
rebuilt from scratch and has never been reconciled against the original.
