# Where this project is — read this first

> **Written for a fresh conversation with no history.** Read this file and you
> should be able to pick up work without anyone re-explaining anything.
>
> Last updated: 5 August 2026.

## The machine

| | |
|---|---|
| Repo | `C:\dev\wildscore` — **not** the KrugerPoke folder |
| Remote | `github.com/iTzlexit/wildscore` — **private**, branch `main` |
| Flutter 3.44.8 | `C:\src\flutter` — **not on PATH**, call `C:\src\flutter\bin\flutter.bat` |
| JDK 21 | `C:\src\jdk-21.0.11+10` |
| Android SDK 36 | `C:\src\android-sdk` — licences accepted, no Android Studio |

APK builds need these set first:

```bash
ANDROID_HOME=C:\src\android-sdk ANDROID_SDK_ROOT=C:\src\android-sdk JAVA_HOME=C:\src\jdk-21.0.11+10
```

There is **no Python** on this machine — `python` is a Windows Store stub. To
serve the web build: `dart run tool/serve_web.dart 8080` from `app/`.

## What the app is

A field guide to 74 Kruger species, a lifetime collection, and **a scorecard
game played by a car full of people on a game drive**. The game is the
differentiator; the collection is the reason anyone still has it in March.

**Everything is local.** No server, no accounts, no network calls anywhere in
the app. One runtime dependency: `shared_preferences`.

## What is built

Four tabs — **Profile, Wild Score, Animal Dex, Sightings**.

- **Onboarding** — a three-slide picture tour of the game (car scene, scoring
  with the live rarity table, the Ultimate Spotter), then a name. No account.
  Replayable from How to play.
- **Animal Dex** — 74 species, search, filters, rarity sort, detail cards.
  Photos are CC0/CC-BY from iNaturalist; caracal and African wildcat fall back
  to silhouettes because the photos could not be trusted.
- **Wild Score** — start a drive, add the car, tap the eye by a player's name to
  claim an animal for them, standings with per-player hauls, restart, end day.
- **Latest Sightings** — every find from Rare upwards, plus the Big Five,
  newest first, grouped by trip, with the road it happened on. Very rare and
  Legendary are marked "on your word" until photo verification exists. Replaced
  the Records tab (best day / rarest / head-to-head), which the user found
  weak; it is in git history if any of it is wanted back.
- **Profile** — lifetime points, collections (Big Five, Small Five, Under
  threat, Antelope, Predators, Snakes, Night shift), drive history with
  year/month filters and delete, backup/restore, credits.
- **Backup** — a pasteable code. No server; see `docs/RISKS.md` for why it
  matters more than it looks.

216 tests. `flutter analyze` is clean and must stay clean.

## Decisions already made — do not relitigate

| Decision | Where |
|---|---|
| No server, no accounts, no ads | `docs/MONETISATION.md` |
| Once-off purchase, R300, no subscription | user, 2 Aug 2026 |
| Ship free first, price later | `docs/MONETISATION.md` |
| Points ≠ collection: points to the caller, collection to everyone in the car | `docs/SCORECARD.md` |
| Banked once, at end of day — never per claim | `docs/SCORECARD.md` |
| Rhino and pangolin never get a location, ever | `docs/MAPS.md`, `docs/SIGHTINGS-FEED.md` |
| Light theme, single typeface, colour reserved for rarity | `docs/DESIGN-DIRECTION.md` |
| No leaderboard — the rivalry is with people in your own car | `docs/MONETISATION.md` |
| A community sightings map is a different product, not the next commit | `docs/MAPS.md` |

## Which doc to read for what

| | |
|---|---|
| **`docs/RISKS.md`** | What could kill this, ordered by damage. Read before planning a launch |
| `docs/MONETISATION.md` | Pricing, and why the offline constraint decides it |
| `docs/SCORECARD.md` | How the game works and why |
| `docs/HOW-TO-PLAY.md` | Player-facing rules — source for the in-app screen |
| `docs/MAPS.md` | The map question, researched. Competitors, and the rhino rule |
| `docs/ACCOUNTS.md` | Sign-in, if it ever happens |
| `docs/IMAGE-ASSETS.md` | Photo sourcing and the non-commercial licence trap |
| `docs/DESIGN-DIRECTION.md` | Palette, type, rarity treatments |
| `MASTER-VISION.md` | The original brief. Partly superseded — check `docs/DIVERGENCES.md` |

## Tools

| | |
|---|---|
| `tools/ranker.html` | Head-to-head comparisons to settle rarity tiers. **Outstanding** |
| `tools/photo-picker.html` | Pick species photographs from CC candidates |
| `app/tool/generate_icon.dart` | Launcher icons at every density |
| `app/tool/serve_web.dart` | Static server for the web build |
| `app/tool/prepare_species_photos.dart` | Downscale sourced photos into assets |

## What is outstanding

**Blocking a store launch**

1. **Rarity tiers unreviewed** — `tools/ranker.html`. The scoring rests on this.
2. **Privacy policy URL** — required by both stores even collecting nothing.
3. **Name check** — "Wild Score" against both stores. `applicationId` is
   `com.wildscore.wildscore` and is permanent after first publish.
4. **Store listing** — description, screenshots, 1024×500 feature graphic.
5. **Google Play: 12 testers × 14 consecutive days.** Calendar time, cannot be
   compressed. Start as early as possible.

**Wanted, not blocking**

- Big Five / Big Six bonuses, First Call double (designed in `docs/SCORECARD.md`)
- House rules screen
- Better caracal and African wildcat photographs
- A drawn Kruger map — `docs/MAPS.md` step 1 first

## House style

Terse, factual comments that explain **why**, never what. Match the surrounding
code. Every behavioural change gets a test. Run before committing:

```bash
C:\src\flutter\bin\flutter.bat analyze && C:\src\flutter\bin\flutter.bat test
```
