# Roadmap

## Do next — the actual list

1. **Add `C:\src\flutter\bin` to your user PATH.** Flutter 3.44.8 is already
   installed there; only the PATH entry is missing, so `flutter` won't resolve
   in your own terminal yet. Start menu → "environment variables" → edit `Path`
   → add it → reopen the terminal.
2. **Enable the pre-commit hook** — once per clone:
   `git config core.hooksPath .githooks`
3. **Install Android Studio** — <https://developer.android.com/studio>. Needed
   for the Android SDK and an emulator. Then add the command-line tools:
   *Settings → Languages & Frameworks → Android SDK → SDK Tools → Android SDK
   Command-line Tools (latest)*.
4. **Create a Pixel emulator** — Device Manager → **+** → Pixel 8 → latest
   system image with Google Play.
5. **`flutter doctor --android-licenses`** — accept all of them.
6. **`flutter run`** from `app/`, and report whatever breaks.
7. Get the rarity tiers and regional ranges reviewed by someone who knows the
   park. This is the data most likely to be quietly wrong, and it is the data
   your best users will judge you on.
8. Artwork for the 15 rarest species — see `app/assets/species/README.md`.

In parallel, and independent of any code (see [docs/VISION.md](docs/VISION.md)):

9. Post the concept in the Kruger Facebook groups. Target: 30 people saying
   they'd pay R249.
10. Start recruiting 12 Google Play closed testers. They must stay opted in for
    14 consecutive days before you may publish publicly, and that clock cannot
    be started retroactively.
11. Check the name against CIPC and both app stores.

## Current status

**Phase 1 — Species Codex. Compiled, tested and running.**

- Flutter **3.44.8** / Dart 3.12.2 installed at `C:\src\flutter`
- `flutter analyze` — no issues
- `flutter test` — **39 passing**
- `flutter build web --release` — builds clean in ~40s
- `flutter build apk --release` — **builds**, Android toolchain green
- Verified at runtime in a browser: boots, fetches `species.json` (HTTP 200),
  parses all 71 species, renders, no console errors

The web build is a **verification and preview target only**; the product ships
to Android and iOS.

### Android build

Toolchain installed without Android Studio: JDK 21 at `C:\src\jdk-21.0.11+10`,
SDK 36 at `C:\src\android-sdk` (cmdline-tools, platform-tools, build-tools,
NDK 28, CMake). All licences accepted. `flutter config` already points at both.

| Artefact | Size | Use |
|---|---|---|
| `app-arm64-v8a-release.apk` | 15.8 MB | Any modern phone — sideload this one |
| `app-armeabi-v7a-release.apk` | 13.3 MB | Older 32-bit devices |
| `app-x86_64-release.apk` | 17.2 MB | Emulators |
| `app-release.apk` | 45.5 MB | Universal, all ABIs. Avoid — three engines in one file |

Built with `--split-per-abi`. For the Play Store you ship an **App Bundle**
(`flutter build appbundle`) instead and Google does the splitting per device.

**These are debug-signed.** Fine for sideloading, and they can never go to the
Play Store. Release signing is a Phase 5 task: you generate a keystore and guard
it, because losing it means you can never update your own app again.

**Still unverified: nobody has run this on a physical phone.** No Android device
is attached to this machine — `flutter devices` sees only Windows, Chrome and
Edge. Installing the APK and using it is the outstanding test.

### Defects found and fixed getting here

| # | Found by | Defect |
|---|---|---|
| 1 | Static audit | `ThemeData.inputDecorationTheme` took `InputDecorationTheme`, deprecated during 2025. Moved to a plain `InputDecoration` on the widget, which works on every Flutter version. |
| 2 | Static audit | Points banner set both `color` and `gradient` on one `BoxDecoration`. Flutter paints only the gradient, so the fade showed the scaffold background instead of the card surface. Split into two layers. |
| 3 | Static audit | Dead parameter on the locked-species placeholder. |
| 4 | `flutter test` | **Real layout bug**: the points banner Row used a fixed Column plus a `Spacer`, overflowing by 139px when text is wider than expected — which is exactly what happens at large accessibility font scales. Now `Expanded` with an ellipsis. |
| 5 | `flutter test` | Widget tests did real file I/O inside Flutter's fake-async zone, so they passed individually and timed out as a suite. Fixed by injecting the repository into `CodexScreen` — better design regardless. |
| 6 | `flutter test` | `flutter create` left a template `widget_test.dart` referencing a non-existent `MyApp`; its compile failure took down the shared test compiler and cascaded into 14 unrelated failures. Deleted. |

---

## Phase 0 — Validation

- [ ] Post the concept in Kruger Facebook groups and the Latest Sightings community
- [ ] Get 30 people to say they would pay R249/season
- [ ] Start recruiting 12 closed-test users for Google Play (14-day requirement)
- [ ] Check the name against CIPC and both app stores

## Phase 1 — Species Codex ← current

- [x] Domain model: species, rarity tiers, park regions, IUCN status, tags
- [x] 71-species seed dataset as a JSON asset
- [x] Repository loading the catalogue at startup
- [x] Codex list: search across English, Afrikaans and scientific names
- [x] Filters: category, park region, rarity tier
- [x] Per-tier visual identity — rail, border, wash and glow escalate with rarity
- [x] Species detail screen with field notes and a regional distribution strip
- [x] Placeholder artwork that looks deliberate, so the app demos without photos
- [x] Locked/silhouette rendering path wired up for Phase 2
- [x] Compiles, analyzes clean, 39 tests passing
- [x] Regression suite + `scripts/check.ps1` + pre-commit hook
- [ ] Run it on Android — needs the Android SDK
- [ ] Review rarity tiers and regional ranges with someone who knows the park
- [ ] Artwork for the 15 rarest species

## Phase 2 — Capture & collection

**This phase is the product.** Everything before it is setup and everything
after it is amplification. See the core loop in [docs/VISION.md](docs/VISION.md).

Build order matters here — see [docs/TESTING.md](docs/TESTING.md). Define the
hardware interfaces and their fakes **first**, so the interesting parts stay
testable from a desk. Camera last.

- [ ] `CaptureSource` and `LocationSource` interfaces + fakes + debug simulator
- [ ] Scoring engine, exhaustively unit-tested before anything can score:
      first-sighting full points, repeats at 10%, one-hour per-species cooldown,
      photos inside the cooldown attaching to the existing encounter
- [ ] Unidentified sightings — skip identification, name it later, score
      against the original capture time
- [ ] `sqflite` sightings table, photos on disk via `path_provider`
- [ ] **Downscale photos on capture** and generate thumbnails — full-res camera
      images are 3–12 MB each and will fill a phone in a weekend
- [ ] Collection screen: silhouettes until caught, then **the player's own
      photo** becomes the card art
- [ ] `camera` package, in-app capture only — no gallery import, ever
- [ ] Camera reachable in **one tap from anywhere** — it is the primary action
- [ ] Shoot-first flow: photo saved with GPS and timestamp before identification
- [ ] Fast species picker — large thumbnails, searchable, ordered by plausibility
- [ ] **The reveal.** Card flip, sound, score counting up, scaled to rarity. This
      is the product, not polish — a pangolin must feel different from an impala
- [ ] Nothing between shutter and reveal — no spinner, no network call
- [ ] Profile screen: total score, collection, personal bests
- [ ] Collection view: found species in colour, unfound as silhouettes
- [ ] One-tap share card, good enough to post without editing
- [ ] Riverpod, once sightings are needed on more than one screen
- [ ] `go_router` + bottom navigation

## Phase 3 — Map & verification

- [ ] Offline park map (`flutter_map` + bundled mbtiles)
- [ ] GPS fix captured with every photo (`geolocator`)
- [ ] Park-boundary check at capture time
- [ ] **Sensitive species: location stored but never rendered.** Rhino, pangolin
- [ ] Night-drive ×1.5 multiplier for nocturnal species
- [ ] Repeat sightings at 10% value

## Phase 4 — Accounts & sync

- [ ] **Schema carries a `reserve` table from day one**, with exactly one row
      (Kruger). Rarity and dex numbers hang off species-in-reserve, not species.
      A few hours now; a migration nobody wants later — see
      [docs/SPEC.md](docs/SPEC.md#future-multiple-reserves)
- [ ] Supabase project, schema, row-level security
- [ ] Auth, offline-first sync queue
- [ ] Server-side score calculation — never trust a client total

## Phase 5 — Leaderboard & Season Pass

- [ ] Seasonal standings with an annual reset
- [ ] RevenueCat, non-renewing annual pass
- [ ] Store listings, screenshots, privacy policy
- [ ] Google Play closed test (12 testers × 14 days)

## Phase 6 — Social

- [ ] Friends and family groups — the paper scoreboard, properly
- [ ] Community flagging of implausible rare sightings
- [ ] End-of-season summary worth sharing

---

## Decisions log

| Date | Decision | Why |
|---|---|---|
| 2026-07-26 | Flutter, not .NET MAUI | Mobile is new either way; the language is the small part. Flutter is far stronger at camera, offline maps, ML and animation — which is all this app is. |
| 2026-07-26 | Project lives in `C:\dev\wildscore`, not OneDrive | Flutter build output churns thousands of files; OneDrive sync locks them mid-build. |
| 2026-07-26 | Zero third-party packages in Phase 1 | Two screens over a read-only JSON asset need `Navigator` and `setState`. Riverpod, Drift and go_router arrive when there is state and persistence to justify them. |
| 2026-07-26 | Supabase, not a hand-rolled ASP.NET Core backend | Postgres, auth, photo storage and RLS on day one. Backend skill goes into schema and policies instead of hosting and identity. It is still Postgres if it needs to be replaced. |
| 2026-07-26 | RevenueCat for payments | Two store billing APIs and two receipt-validation flows is where homegrown IAP leaks money. Free below ~$2.5k/month. |
| 2026-07-26 | Non-renewing season pass, not a subscription | People visit Kruger once a year. A subscription breeds cancellations; a season pass matches the annual leaderboard reset. |
| 2026-07-26 | Rarity by difficulty of sighting, not by fame | Lions are easier to find than sable. Scoring only feels earned if it tracks reality. |
| 2026-07-26 | Player is a "Tracker", not a "Trainer" | A tracker is the person who finds the animals in SA safari culture — authentic, descriptive, and not borrowed from Pokémon's own vocabulary. |
| 2026-07-26 | Onboarding asks for a name and nothing else | A family at the gate must be playing in twenty seconds. A password field here loses half of them. Real accounts arrive in Phase 4 when sightings need to survive a lost phone. |
| 2026-07-26 | `shared_preferences` added — first third-party package | A handful of bytes that must survive a restart is exactly what it is for. Sightings still go to sqflite in Phase 2; they grow without limit and need querying. |
| 2026-07-26 | First Find bonus via spatio-temporal clustering; capture data now, ship feature later | Finding an animal yourself differs entirely from joining a traffic jam. Clusters can be recomputed retrospectively; ungathered GPS and timestamps are gone forever. Needs user density, so it cannot block launch. |
| 2026-07-26 | Reward finding, never reward arriving | A first-to-arrive bonus is a bonus for speeding and crowding animals. No live sighting feed, no race UI; the bonus is computed quietly at sync. |
| 2026-07-26 | Shoot first, identify second | Animals do not wait. Missing the photograph is far worse than a two-second delay before the reveal. The catch is at the shutter; the ceremony is at identification. |
| 2026-07-26 | Tier-gated verification | Common sightings count instantly — nobody fakes an impala. Legendary ones enter the collection immediately but reach the public leaderboard only after review. Integrity where it matters, no friction where it does not. |
| 2026-07-26 | ML routes to review, never rejects | Wrongly rejecting a real pangolin would be unforgivable. "This does not look like a pangolin" is an easy problem; "identify this animal" is a hard one. |
| 2026-07-26 | Codex is a grid with permanent dex numbers | Reads as a guidebook rather than a database. Numbers assigned once (mammals, birds, reptiles; alphabetical within) and never reshuffled — a dex number is an identity, and collection screenshots would go stale. |
| 2026-07-26 | Three tabs: Profile, Dex, Leaderboard | Your own achievement first, the goal second, other people third. Profile opens on lifetime score; tapping it lists catches newest-first. |
| 2026-07-26 | Profile is lifetime; leaderboard is seasonal | Seasons reset so newcomers always have a reason to start. The collection never resets — permanence is one of the three feelings the product protects. |
| 2026-07-26 | Nicknames on caught animals | Nearly free to build; a named animal is one you are attached to, and attachment is what makes a collection worth keeping. |
| 2026-07-26 | One sighting = one encounter, not one shutter press | Everyone takes eight photos of a leopard. Photos inside the cooldown attach to the existing sighting rather than creating eight zero-point entries. |
| 2026-07-26 | A species scores once per hour, per player | One leopard in a tree for twenty minutes would otherwise be a hundred scoring photographs. Photos inside the cooldown are **never rejected** — you keep every picture, you are just not paid twice. |
| 2026-07-26 | Identification is skippable | Not knowing is the normal condition of someone new to the bush. Photo saves as Unidentified with capture-time GPS and timestamp; scores nothing until named, then scores against the original capture time. |
| 2026-07-26 | **Rarity belongs to species-in-reserve, not to species** | A cheetah is Rare in Kruger and near-guaranteed in the Masai Mara. A global rating would let one trip to Kenya top a Kruger leaderboard. Schema must carry a `reserve` table from Phase 4 with one row in it; the feature waits. |
| 2026-07-26 | v1 verification is camera + GPS + timestamp, no ML | A trustworthy species classifier is its own project. This is already far stronger than paper. |
| 2026-07-26 | Rhino and pangolin locations never rendered anywhere | Poaching risk. Not a setting, not a later feature request. |
| 2026-07-26 | Rarity styling uses baked-in ARGB values | `withOpacity` / `withValues` churned across Flutter releases; literal colours compile everywhere and are inspectable. |
