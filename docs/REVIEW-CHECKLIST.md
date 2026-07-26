# Review checklist

Run this before merging anything into `main`. It has two halves: the part a
machine does, and the part only you can do.

---

## 1. The automated gate

```bash
pwsh scripts/check.ps1
```

Format, analyze, and the full test suite. Takes about 20 seconds. **If this is
red, stop — nothing else on this page matters yet.**

It also runs automatically on every commit via the hook in `.githooks/`. Enable
it once per clone:

```bash
git config core.hooksPath .githooks
```

### What the tests actually protect

| File | Guards |
|---|---|
| `test/species_data_test.dart` | The catalogue itself — parses, unique ids, sorted rarest-first, points match tier, Big Five and Big Six complete, **rhino and pangolin flagged sensitive**, regional specials not marked park-wide |
| `test/species_model_test.dart` | Parsing, search across English/Afrikaans/scientific names, tier point values, the error message on a bad enum |
| `test/codex_screen_test.dart` | What a user can do — search, filter by category and region, empty state, clear filters, open a species, the protection notice appearing only where it should |

Tests assert **behaviour, not implementation**, so refactoring should not break
them. If a refactor does break one, that is the test doing its job — read it
before you change it.

---

## 2. What tests cannot catch

Automated tests run in a fake environment with a fake font. They will never tell
you the app feels good. Do these by hand.

### Every change

- [ ] `flutter run` on a real device or emulator — not just green tests
- [ ] Scroll the full Codex list. Smooth? No stutter on a cheap phone?
- [ ] Open three species from different tiers. **Does a Legendary card still
      look obviously different from a Common one at a glance?** If that stops
      being true, the product is broken even if every test passes
- [ ] Rotate through the filter panel — nothing overlapping, nothing cut off

### When you touch the UI

- [ ] Check at **large system font size** (Settings → Display → Font size →
      largest). This is where layouts break, and a real overflow bug was found
      this way already
- [ ] Check on a small screen (≤ 5.5", or a 360×640 emulator)
- [ ] Long species names — *Southern African Rock Python*, *Southern Ground
      Hornbill* — still fit without clipping?

### When you touch `species.json`

- [ ] Tests pass (they check structure, not truth)
- [ ] **Is the data actually correct?** Distribution and rarity are the things
      experienced Kruger visitors will judge you on. A wrong range is worse than
      a missing species
- [ ] New species that is a poaching target → `isSensitive: true`, and add it to
      the assertion in `species_data_test.dart`

### Before any release

- [ ] Aeroplane mode: does everything still work? Offline is the normal case,
      not the fallback
- [ ] Cold start from a killed app — how long to first paint?
- [ ] Read [VISION.md](VISION.md) non-negotiables and confirm none has quietly
      eroded
- [ ] Install size still sane (`flutter build apk --analyze-size`)

---

## 3. The vision test

From [VISION.md](VISION.md), applied to the whole change:

> **Does this make the moment of finding a rare animal better, or make it easier
> to show someone?**

If neither, ask why it is in this release.

---

## 4. Branch workflow

`main` stays green and runnable. Never commit straight to it.

```bash
git checkout -b feature/camera-capture
# ...work...
pwsh scripts/check.ps1
git commit -am "Add camera capture"
git checkout main
git merge feature/camera-capture
```

Branch names: `feature/…`, `fix/…`, `data/…` for species edits.

One phase per branch, roughly. If a branch is open longer than a week it has
grown too big — split it.

### Commit messages

Say what changed and why, not what file you touched. `Fix points banner
overflow at large font scale` beats `update detail screen`. In six months the
log is the only record of why a decision was made.
