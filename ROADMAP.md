# Roadmap

Phases follow [MASTER-VISION.md](MASTER-VISION.md), which is canonical.

## Resuming work — read this first

**Where everything is**

| | |
|---|---|
| Repo | `C:\dev\wildscore` — **not** the KrugerPoke folder |
| Remote | `github.com/iTzlexit/wildscore` (private), branch `main` |
| Flutter app | `app/` — Dart code in `app/lib/` |
| Flutter 3.44.8 | `C:\src\flutter` — **not on PATH** |
| JDK 21 | `C:\src\jdk-21.0.11+10` |
| Android SDK 36 | `C:\src\android-sdk` — licences accepted, no Android Studio |

**Commands** (from `C:\dev\wildscore\app`, Flutter on PATH):

```bash
flutter run
```

```bash
pwsh scripts/check.ps1
```

**Read before building:** [MASTER-VISION.md](MASTER-VISION.md), then
[docs/DIVERGENCES.md](docs/DIVERGENCES.md) for what the code does not yet match,
then [docs/SPEC.md](docs/SPEC.md) for the phase you are on.

---

## Current status

**Phase 1 partially complete.** Built, tested, running on Android and web.

Working: onboarding, three-tab navigation, profile with Today/Lifetime toggle
and a 71-slot collection grid, Codex grid with permanent dex numbers and real
photographs, search across English/Afrikaans/scientific names, filters, species
detail, full-screen photo viewer, 71 CC0/CC-BY photos with enforced attribution.

`flutter analyze` clean · **66 tests passing** · APK builds at 23.1 MB (arm64).

**Phase 1 is not finished.** Missing: the three-state Codex model, the reveal
animation, and the design direction below.

**Known to be wrong** — see [docs/DIVERGENCES.md](docs/DIVERGENCES.md):
rarity tiers and values, the player noun ("Tracker" is a rank), the
repeat-sighting model, `isSensitive` as a boolean.

---

## Phase 1 — Species Codex

- [x] Browse, search, filter
- [x] Permanent dex numbers, real photographs, attribution
- [x] Per-tier visual identity
- [x] Species detail and photo viewer
- [ ] **Correct rarity tiers** — 7 tiers, new names and values
- [ ] **Three-state model** — undiscovered / logged / verified
- [ ] **The reveal animation**, scaled by rarity
- [ ] **Design direction applied** — see docs/DESIGN-DIRECTION.md
- [ ] Per-category completion: Mammals / Birds / Reptiles
- [ ] Rename Tracker → **Spotter**
- [ ] **Licences screen** — photo credits are currently only an overlay on the
      full-screen viewer. CC-BY needs a reachable credits list. Do not ship
      without it
- [ ] Silhouette assets via build-time ML background removal — see
      [docs/IMAGE-ASSETS.md](docs/IMAGE-ASSETS.md)
- [ ] Re-run the photo pipeline at 1200px WebP — the detail hero is
      under-resolved at 800px, and WebP absorbs the size increase

## Phase 1.5 — The day scorecard ← **next, and the current focus**

Decided 2026-08-02: build the car game before the camera. It needs **no camera,
no GPS and no backend**, so it is playable on the next trip rather than the one
after — and it is the origin story of the whole product.

Everything else is parked until this works. Full spec:
[docs/SCORECARD.md](docs/SCORECARD.md), player-facing copy:
[docs/HOW-TO-PLAY.md](docs/HOW-TO-PLAY.md).

- [ ] Players for a day — add, remove, persist locally
- [ ] Start / end a scorecard, one active at a time
- [ ] Claim a species → assign to a player
- [ ] **Chances per species**, tiles locking when spent, showing who claimed it
- [ ] Live standings on the Profile tab
- [ ] Day log — timestamped, reassignable for five minutes then locked
- [ ] **House rules** — exclude species, override chances, override points
- [ ] **Park rules vs House rules.** Only Park rules games can ever reach the
      public leaderboard. Store the ruleset *with* the scorecard, so an old day
      stays explicable
- [ ] Big Five / Big Six in a day: +400 each
- [ ] First call of the day worth double
- [ ] End-of-day summary worth screenshotting
- [ ] **How to play** screen, generated from HOW-TO-PLAY.md

## Phase 2 — Trips, capture, scoring

The product. Everything before is setup; everything after is amplification.

- [ ] `CaptureSource` / `LocationSource` interfaces + fakes + debug simulator
      (build first — see [docs/TESTING.md](docs/TESTING.md))
- [ ] Scoring engine, exhaustively tested: daily scorecard, scratch-off for
      Common and Frequent, per-encounter cooldown for Notable and above
- [ ] **Quick Log — under three seconds from app open.** One tap, no photo
- [ ] Trip sessions: open on park entry, validity from a continuous GPS trace
- [ ] Camera capture, up to four photos, review before save
- [ ] `sqflite` sightings store, photos downscaled on capture
- [ ] Provisional scoring — live during the drive
- [ ] Unidentified sightings, named later
- [ ] No points for off-road positions or speeding

## Phase 3 — Backend, sync, the ritual

- [ ] Supabase project, schema, row-level security
- [ ] **`reserve` table from day one**, one row. Rarity hangs off
      species-in-reserve
- [ ] **Versioned species catalogue** — syncs on connect, caches locally,
      bundled JSON as fallback. Blocks nothing else, but retrofitting is a
      migration
- [ ] `sensitivityLevel` enforced server-side
- [ ] Offline sync queue, idempotent upload
- [ ] **The sync ritual** — cards flipping pending → verified, one at a time.
      Never a spinner
- [ ] Photos to Cloudflare R2, not Supabase Storage — R2 has no egress fees and
      den/profile photos are viewed constantly
- [ ] **Enforce six full-resolution photos per player in the schema.** Everything
      else is a thumbnail. This is the reason the Collection is capped at six —
      it must be a constraint, not a convention, or the storage bill discovers it
      for us

## Phase 4 — Season Pass

- [ ] RevenueCat, entitlements, restore
- [ ] Season Pass R199 (R149 founding) / $14.99. Non-renewing
- [ ] Vehicle Pass R399 / $29.99, five players
- [ ] Paywall on promoting to the Six — never on submitting a score

## Phase 5 — Collection of Six and share cards

- [ ] Promote and swap, freely
- [ ] Card rendering, tier frames, verified tick, Quiet mark
- [ ] **One-tap share export.** This is the marketing channel, not a feature

## Phase 6 — AI verification

- [ ] Claude vision on sync, species vs claim
- [ ] Multi-photo confidence
- [ ] **Flag, never reject.** Provisional points, review queue, player appeal

## Phase 7 — The Den

The most expensive thing in the project and the most tempting to build early.
**Resist.**

- [ ] ~12 eligible species as animated sprites
- [ ] Idle behaviour, time-of-day awareness, tap reaction
- [ ] Tap opens the real photograph, with where and when
- [ ] Never: hunger, decay, health, streaks

## Phase 8 — Profiles and privacy

- [ ] Visit other Spotters: rank, crowns, completion, their six, their den
- [ ] Full private mode, per-sighting private flag, location granularity
- [ ] Region-level location only, ever

## Phase 9 — Crowns, ranks, seasons

- [ ] Species Crowns — per-species seasonal holder
- [ ] Hall of Fame for past holders
- [ ] Ranks: Day Visitor → Tracker → Ranger → Field Guide → Head Ranger → Legend
- [ ] Season reset. Codex never resets
- [ ] Quick Logs never earn crowns

## Phase 10 — Wild Card

- [ ] Daily objective, generated locally at trip start
- [ ] Always achievable with normal driving

## Phase 11 — Anti-fraud hardening

- [ ] **PanCapture** — ~360° sweep over 3–5s, gyro trace agreeing with visual
      motion. Optional everywhere; earns Quiet Sighting ×1.5 at any tier;
      effectively required for crown eligibility at Very rare and above
- [ ] Play Integrity / App Attest, mock location detection
- [ ] Sun position vs timestamp, duplicate image hashing

## Phase 12 — Multi-park

- [ ] Pilanesberg, Addo, Etosha
- [ ] Rarity is per species-in-reserve — a cheetah is a prize in Kruger and
      routine in the Mara

---

## Phase 0 — Validation, running in parallel

- [ ] Post the concept in Kruger Facebook groups. Target 30 people saying they
      would pay R199
- [ ] Recruit 12 Google Play closed testers — 14 consecutive days, cannot be
      backdated
- [ ] Final name. `Krugermon` / `Krugerdex` rejected; `Spoor` recommended
- [ ] Kruger guide reviews the whole rarity table
- [ ] Run the APK on a physical phone

---

## Decisions log

| Date | Decision | Why |
|---|---|---|
| 2026-07-26 | Flutter, not .NET MAUI | Mobile is new either way; the language is the small part. MAUI is weakest at camera, offline maps and animation — this app's three hardest problems. |
| 2026-07-26 | `C:\dev\wildscore`, not OneDrive | Build output churns thousands of files; OneDrive locks them mid-build. |
| 2026-07-26 | Zero third-party packages in Phase 1 | Vindicated — Riverpod moved to 3.x with a changed API. Adding it early meant writing 2.x code against a 3.x library. |
| 2026-07-26 | **Supabase**, not self-hosted ASP.NET Core | Postgres, auth, storage and RLS on day one with no server to operate. Reversible — it is Postgres. Supersedes MASTER-VISION.md's stack section. |
| 2026-07-26 | Photos in **Cloudflare R2**, not Supabase Storage | R2 has no egress fees. Den and profile photos are viewed constantly; S3-style egress billing is the difference between a rounding error and a real bill. |
| 2026-07-26 | RevenueCat for payments | Two store billing APIs and two receipt flows is where homegrown IAP leaks money. |
| 2026-07-26 | Non-renewing season pass | People visit once a year. Subscriptions breed cancellations; a pass matches the rhythm and the crown reset. |
| 2026-07-26 | **Paywall on the Six and the Den, not on submitting a score** | Charging to submit a score is charging for a leaderboard — the one thing the positioning says people resent. People pay to keep a photo album. |
| 2026-07-26 | Rarity by difficulty of sighting, not fame | Lions are easier to find than sable. |
| 2026-07-26 | Photo quality never affects points | A blurry pangolin is 400; a perfect impala is 5. Rewarding quality builds a photography contest won by the longest lens. |
| 2026-07-26 | Distance never awards points | It only releases the cooldown. Paying for distance rewards driving fast in a 50 km/h park with animals on the road. |
| 2026-07-26 | Reward finding, never reward arriving | No live sighting feed, no race UI. The First Find bonus is computed quietly at sync. |
| 2026-07-26 | **Sensitive locations never rendered** | Master says "coarse grid or nothing" — this is the "or nothing" branch, and stricter. A coarsening bug leaks a location; a never-render rule has nothing to leak. |
| 2026-07-26 | **`sensitivityLevel` as data, not a hardcoded list** | Poaching pressure shifts. Ground hornbill, vultures at nest sites, denning wild dog sites all warrant care. A boolean on three species is an if-statement waiting to be wrong. |
| 2026-07-26 | **Versioned catalogue syncing on connect** | A sensitivity change must reach a player already in the park without a store review. Retrofitting means migrating a live user base off a compiled asset. |
| 2026-07-26 | One sighting = one encounter, not one shutter press | Everyone takes eight photos of a leopard. Photos inside the cooldown attach to the existing encounter. |
| 2026-07-26 | Identification is skippable | Not knowing is the normal condition of someone new to the bush. |
| 2026-07-26 | Shoot-first vs pick-first resolved by **Quick Log** | Pick-species-then-shoot is fine for Capture precisely because Quick Log exists for everything else. |
| 2026-07-26 | Dex numbers permanent | Mammals, birds, reptiles; alphabetical within. Never reshuffled — a dex number is an identity and collection screenshots would go stale. |
| 2026-07-26 | **71 species, not 45** | Birders are the most obsessive list-keepers on earth and a large slice of self-drive visitors. |
| 2026-07-26 | **Per-category completion** | Mammals / Birds / Reptiles with independent percentages, so a mammal-focused player is not stuck at 30% forever. |
| 2026-07-26 | **Player noun is "Spotter"** | "Tracker" is rank two of six. Using it as the player noun promotes everyone on signup. |
| 2026-07-26 | **Crowns, not more leaderboards** | Best-single-trip dropped — it is "most sightings today" with a different window, which rewards racing. 71 species is 71 chances to be best at something. |
| 2026-07-26 | **Black rhino is Very rare (100)** | Fewer animals in thicker bush; genuinely harder than wild dog. The original Rare (60) was an artefact of illustrative examples. |
| 2026-08-02 | **Day scorecard before the camera** | No camera, GPS or backend needed, so it is playable on the next trip rather than the one after. It is also the paper game the product came from. |
| 2026-08-02 | **Chances per species, not a boolean scratch-off** | Generalises: one for impala, three for something seen a few times a day, unlimited for leopard. Also gives house rules something meaningful to adjust. |
| 2026-08-02 | **Park rules vs House rules** | House rules are genuinely wanted, but a score is only comparable if both were earned under the same rules — and a shared board is trivially gamed by whoever sets the most generous ones. Only Park rules submits. |
| 2026-08-02 | Ruleset stored with the scorecard, not just a mode flag | A day scored six months ago must stay explicable; "why did I get 60 for that leopard" cannot depend on current settings. |
| 2026-08-02 | First Call bonus rather than raising Common points | 13 Common + 17 Frequent means the whole day's common ceiling is 320 against a pangolin's 400 — it works, but only just. Tripling Common takes it to 705 and a good morning at the gate beats a once-in-a-lifetime find. |
| 2026-08-02 | Samango monkey removed | Not a Kruger species. Sourced from marginal Pafuri records. Renumbered 1–70 while renumbering is still free. |
| 2026-08-02 | Light theme supersedes dark | The dark build read as generic. Original reasoning survives as constraints — auto dark mode if dawn brightness hurts, and photographs still lead. |
| 2026-07-26 | PanCapture: gate by tier for fraud, universal for behaviour | Being alone with a herd of elephants deserves the same reward as with a leopard. Crowding matters at every tier. |
