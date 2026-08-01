# Wild Score

A verified wildlife-spotting game for Kruger National Park. Photograph an animal
in the park, earn points scaled to how hard it was to find, build a permanent
collection, and compete on a seasonal leaderboard.

It started as a scorecard played on paper on a family trip. This is that game,
with the scoring made honest and the bragging made shareable.

> **Working name.** Check it against CIPC and both app stores before it goes
> anywhere public.

## Where to start

| | |
|---|---|
| **[docs/VISION.md](docs/VISION.md)** | **The end goal.** What we are building and why. Read before any phase. |
| **[docs/00-SETUP.md](docs/00-SETUP.md)** | Install Flutter and run the app. Start here to build. |
| **[docs/DEV-WORKFLOW.md](docs/DEV-WORKFLOW.md)** | Day to day: connecting a phone, hot reload, what to run before committing |
| [docs/SPEC.md](docs/SPEC.md) | What the product is, how scoring works, how sightings are verified |
| [docs/TECH-STACK.md](docs/TECH-STACK.md) | Every technology choice and the reasoning behind it |
| [docs/REVIEW-CHECKLIST.md](docs/REVIEW-CHECKLIST.md) | Run before merging anything. What the tests cover, and what only you can check |
| [docs/MONETISATION.md](docs/MONETISATION.md) | How users pay and how the money reaches your bank account |
| [docs/TESTING.md](docs/TESTING.md) | How to test camera, GPS and a park you cannot visit |
| [docs/DIVERGENCES.md](docs/DIVERGENCES.md) | Where the live docs disagree with the original plan, and why |
| **[docs/SCORECARD.md](docs/SCORECARD.md)** | **The day scorecard — current focus.** Players, chances, house rules, leaderboard |
| [docs/HOW-TO-PLAY.md](docs/HOW-TO-PLAY.md) | Player-facing rules. Source for the in-app How to play screen |
| [docs/DESIGN-DIRECTION.md](docs/DESIGN-DIRECTION.md) | Palette, type scale, rarity treatments, card anatomy, motion |
| [docs/IMAGE-ASSETS.md](docs/IMAGE-ASSETS.md) | Photo sourcing, licensing, silhouettes, community donations, cost |
| [ROADMAP.md](ROADMAP.md) | Seven phases, current status, decisions log |

## Status

**Phase 1 — the Species Codex.** A searchable field guide to 71 Kruger species
with rarity tiers, point values, field notes and regional distribution. No
camera, no GPS, no account, no network. It is the free tier of the finished app
and it is genuinely useful on its own.

The code has not been compiled yet — Flutter is not installed on the development
machine. Follow the setup guide and expect to fix a few analyzer complaints on
first run.

## Layout

```
docs/                     Specs and setup
app/
  assets/data/            species.json — the catalogue
  assets/species/         Artwork (empty; see the README in there)
  lib/
    domain/               Models and enums. No Flutter imports.
    data/                 Repositories.
    features/codex/       The Codex screens and their widgets.
    shared/               Theme and cross-feature widgets.
```

`domain/` deliberately has no dependency on Flutter. When the Supabase backend
arrives in Phase 4 it speaks the same model.

## Run it

```bash
flutter run
```

From `app/`, after completing setup. Press `r` to hot reload.
