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
- Verified at runtime in a browser: boots, fetches `species.json` (HTTP 200),
  parses all 71 species, renders, no console errors

Not yet run on Android or iOS — that needs the Android SDK (item 3 below).
The web build is a **verification and preview target only**; the product ships
to Android and iOS.

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

- [ ] `camera` package, in-app capture only — no gallery import, ever
- [ ] `sqflite` sightings table, photos on disk via `path_provider`
- [ ] **The reveal.** Card flip, sound, score counting up, scaled to rarity. This
      is the product, not polish — a pangolin must feel different from an impala
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
| 2026-07-26 | v1 verification is camera + GPS + timestamp, no ML | A trustworthy species classifier is its own project. This is already far stronger than paper. |
| 2026-07-26 | Rhino and pangolin locations never rendered anywhere | Poaching risk. Not a setting, not a later feature request. |
| 2026-07-26 | Rarity styling uses baked-in ARGB values | `withOpacity` / `withValues` churned across Flutter releases; literal colours compile everywhere and are inspectable. |
