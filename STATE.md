# Where this project is — read this first

> **Written for a fresh conversation with no history.** Read this file and you
> should be able to pick up work without anyone re-explaining anything.
>
> Last updated: 9 August 2026.

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

A field guide to 194 Kruger species, a lifetime collection, and **a scorecard
game played by a car full of people on a game drive**. The game is the
differentiator; the collection is the reason anyone still has it in March.

**Everything is local.** No server, no accounts, no network calls anywhere in
the app. One runtime dependency: `shared_preferences`.

## What is built

Three tabs — **Profile, Wild Score, Animals**. The Sightings feed is gone: it was the first half of a community map, and that is a different product.

- **Onboarding** — a three-slide picture tour of the game (car scene, scoring
  with the live rarity table, the Ultimate Spotter), then a name. No account.
  Replayable from How to play.
- **Animal Dex** — 194 species (59 mammals, 124 birds, 8 reptiles, 2
  invertebrates, and the baobab), **grouped into Animals then Birds**, search,
  filters, rarity sort, detail cards.
  Around 30 of the mammals carry a **park population figure** on the card —
  aerial-survey ranges where SANParks flies them, published estimates where
  nobody does, and "Not published" for rhino and pangolin. Sources are on the
  credits screen.
  Photos are CC0/CC-BY from iNaturalist; caracal and African wildcat fall back
  to silhouettes because the photos could not be trusted.
- **Wild Score** — start a drive, add the car, tap the eye by a player's name to
  claim an animal for them, standings with per-player hauls, restart, end day.
  Claims on notable animals ask who else was there (alone doubles, a jam halves)
  and whether a lion was male (+60).
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

355 tests. `flutter analyze` is clean and must stay clean.

## Decisions already made — do not relitigate

| Decision | Where |
|---|---|
| No server, no accounts, no ads | `docs/MONETISATION.md` |
| Once-off purchase, R300, no subscription | user, 2 Aug 2026 |
| Ship free first, price later | `docs/MONETISATION.md` |
| Points ≠ collection: points to the caller, collection to everyone in the car | `docs/SCORECARD.md` |
| Banked once, at end of day — never per claim | `docs/SCORECARD.md` |
| Crowd: spotting it yourself pays the card value, a jam pays 20% less | `docs/HOW-TO-PLAY.md` |
| **Points are per species, not per tier** — a tier is a band. 5–1000 | `tools/rank-list.html`, Alex 10 Aug 2026 |
| Every score is a rung on one shared ladder — 190 species, 24 scores, ties on purpose | `RarityTier.rungs` |
| **Players can revalue any animal** in the Dex, on the same rungs | `docs/HOUSE-RULES.md` |
| Players set their own caps, and their own jam tax (0–50%) | `docs/HOUSE-RULES.md` |
| The Dex has two views: grid to browse, ranked list to compare | `docs/HOUSE-RULES.md` |
| Caps only on impala and vervet monkey; elephant and buffalo taper instead | Alex, 10 Aug 2026 |
| Lion, leopard, white rhino are wild cards: first of the day pays big | Alex, 10 Aug 2026 |
| A night animal seen in daylight pays 2.5x | Alex, 10 Aug 2026 |
| Daily caps: common and frequent 4, notable 3, impala 2, rare+ unlimited | `docs/HOW-TO-PLAY.md` |
| Rhino and pangolin never get a location, ever | `docs/MAPS.md`, `docs/SIGHTINGS-FEED.md` |
| Rhino and pangolin never get a population number either | `test/population_test.dart` |
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
| **`docs/WRITING-STYLE.md`** | **How every word that ships is written.** Read before touching any copy |
| `MASTER-VISION.md` | The original brief. Partly superseded — check `docs/DIVERGENCES.md` |
| **`CHECKLIST.md`** | Done / blocking launch / to decide. The plan, as opposed to the code |
| `docs/PROMOTION.md` | The YouTube approach, and what a creator deal should look like |
| `docs/EXTERNAL-REVIEW-PROMPT.md` | Brief for an outside copy/UX review, with the output format |

## Tools

| | |
|---|---|
| `tools/ranker.html` | Pairwise rarity survey, **Notable and up only** (80 species). Publish to Netlify once the catalogue is complete |
| `app/tool/build_ranker.dart` | Regenerates the ranker from species.json |
| `app/tool/merge_rankings.dart` | Bradley-Terry fit over everybody submitted answers |
| `tools/rank-list.html` | **Order the animals by hand inside each tier**, with points spread across a band |
| `app/tool/build_rank_list.dart` | Regenerates rank-list.html from species.json |
| `tools/photo-picker.html` | **Pick species photographs yourself.** Regenerate with `source_species_photos --picker` |
| `app/tool/generate_icon.dart` | Launcher icons at every density |
| `app/tool/serve_web.dart` | Static server. `--root ..` to serve the content tools |
| `app/tool/apply_photo_picks.dart` | Apply the picker's export: downloads, downscales, rewrites credits |
| `app/tool/source_species_photos.dart` | **Fetch CC0/CC-BY photos from iNaturalist.** `--candidates` for options |
| `app/tool/contact_sheet.dart` | Grid of photos to eyeball. **Never merge a sourced photo unseen** |
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

- **The bird half of the dex could still use sub-grouping** — raptors, water
  birds, LBJs. Splitting Animals from Birds fixed the worst of it; 124 birds in
  one run is still a long scroll.
- **The official population figures are unverified by us.** SANParks serves its
  wildlife-trends PDF behind Cloudflare and it could not be fetched, so the
  2023/2024 survey ranges came from the owner's own research. They have the
  shape of real confidence intervals and match the direction of every secondary
  source, but nobody here has opened the primary document. Worth doing before
  launch.

- Big Five / Big Six bonuses, First Call double (designed in `docs/SCORECARD.md`)
- House rules screen
- Better caracal and African wildcat photographs (they fall back to silhouettes)
- **A better ostrich photograph.** The current one is a foraging bird with its
  head down in the grass, which is close to useless for identifying one. The
  full-bleed detail header made it obvious — the old medallion hid weak photos
  inside a small disc. Worth re-checking the whole set against the new layout.
- A drawn Kruger map — `docs/MAPS.md` step 1 first

## House style

Terse, factual comments that explain **why**, never what. Match the surrounding
code. Every behavioural change gets a test. Run before committing:

```bash
C:\src\flutter\bin\flutter.bat analyze && C:\src\flutter\bin\flutter.bat test
```
