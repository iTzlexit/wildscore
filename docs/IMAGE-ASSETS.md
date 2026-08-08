# Image assets — sourcing, licensing and cost

Three separate image problems with three different economics. **Item 1 is
already done**, which the brief for this document did not know.

| # | Problem | Status |
|---|---|---|
| 1 | Stock reference images, all 71 species | **Done.** Sourced, licensed, bundled |
| 2 | User photo storage | Capped by design at six full-resolution per user |
| 3 | Den sprites | Capped by design at ~12 species |

---

## 1. Stock reference images — already solved

All **71 species have a bundled photograph**, sourced from iNaturalist during
Phase 1.

| | |
|---|---|
| Licences | **54 CC-BY, 17 CC0**. Nothing else was accepted |
| Bundled size | **6.7 MB** — 96 KB average, 185 KB largest |
| Format | JPEG, 800px longest side, quality 72 |
| Attribution | `assets/data/attributions.json`, one entry per species |
| Pipeline | `app/tool/prepare_species_photos.dart`, re-runnable |

### The licence filter is the important part

iNaturalist's *default* photo for a species is very often **CC-BY-NC** —
non-commercial — which is illegal to use in a paid app. The pangolin's default
was exactly that. The fetch filtered to `cc0,cc-by` only, and every one of the
71 matched.

A test (`app/test/attribution_test.dart`) fails the build if any species loses
its credit, because CC-BY attribution is a licence condition, not a courtesy.

### What is NOT done — the credits screen

Credits currently appear **only as an overlay on the full-screen photo viewer**.
That is arguably sufficient for CC-BY, but it is fragile: a player who never
opens a photo full-screen never sees a credit.

**Needed before store submission:** a Licences screen listing every photographer,
licence and source URL, reachable from settings. Flutter provides
`showLicensePage()` for package licences — the photo credits belong alongside it.

Small job. Do not ship without it.

### The full checklist

Every entry, in dex order, with photographer, licence, size and source. The
"Replace?" column is for marking images you want re-sourced or commissioned —
quality is uneven, and the rarest species have the worst photos (see below).

See **[IMAGE-CHECKLIST.md](IMAGE-CHECKLIST.md)**.

### The known quality problem

**The rarer the animal, the worse the available photo.** Rare animals are
photographed rarely, and mostly by camera traps — the bundled pangolin image
carries a burned-in timestamp (`2/27/2020 5:02 AM`). There were only 13
commercially-licensed pangolin observations to choose from.

This is exactly backwards from what the product needs. **Legendary cards are the
ones people screenshot and post.** If any images get commissioned, start there.

---

## 2. Undiscovered silhouettes — solved with PhyloPic

### You cannot derive a true silhouette from a photograph

A silhouette needs an alpha channel. JPEGs have none, so `srcIn` blending
produces a black rectangle, not an animal shape. The interim solution was the
reference photo desaturated and crushed to ~15% brightness — workable, but the
background still leaks, and a silhouette should tease the *shape* and nothing
else.

### The source: PhyloPic

[PhyloPic](https://www.phylopic.org/) is an open database of organism
silhouettes — black on transparent, linked to taxonomy, with a
[public API](http://api-docs.phylopic.org/v2/). Exactly the asset needed, free.

**The licence trap, again.** PhyloPic's *primary* image for a taxon is
frequently **CC BY-NC-SA** — non-commercial, unusable in a paid app. The
leopard's primary image is. This is the second time this pattern has appeared
after iNaturalist's CC-BY-NC defaults, and it is worth stating as a rule:

> **On any open image platform, assume the default licence is non-commercial
> until proven otherwise. Filter explicitly, every time.**

The fetch uses `filter_license_nc=false&filter_license_sa=false`, which leaves
only CC0 and public-domain work.

### API notes, since the documentation is thin

- `filter_name` on `/nodes` is an **exact, lowercase** match. `Panthera pardus`
  returns nothing; `panthera pardus` returns the taxon
- `embed_items=true` is rejected unless `page` is also supplied
- Resolve a taxon to a clade UUID, then query `/images?filter_clade=<uuid>`
- Every request needs a current `build` number from `/`, or you get **410 Gone**
- Fall back from species to genus — many species have no silhouette of their
  own, and a genus-level shape is perfectly adequate for a tease

### What this does not give you

Silhouettes are **generic**. One leopard shape may stand in for several cats,
and a genus fallback means the impala silhouette is an antelope, not
specifically an impala. That is fine for an undiscovered slot and would not be
fine for identification.

Flat black on transparent compresses to almost nothing — 71 silhouettes add well
under 500 KB.

---

## 3. Community reference images

**Spec this as a feature.** When a player captures a verified photo, offer to
donate it as the community reference image for that species. It costs nothing,
quality improves over time, and it is a status hook — your pangolin photo becomes
what every new player sees.

It solves the sourcing problem using the thing the app already produces.

### Requirements

**Opt-in, and it is a licence grant, not a toggle.** The player must grant a
perpetual, worldwide, royalty-free licence to use the photo as a reference image.
That belongs in the terms, with a plain-language summary at the point of donation
— *"we can use this as the reference photo for Leopard, with your name on it,
forever."* A checkbox with no explanation is not consent.

**Moderation before it goes live.** Wrong species, poor crops, and the
occasional deliberately bad submission all need catching. A donated image
replaces what every player sees — that is not an auto-publish surface.

**Attribution to the photographer**, shown wherever the image appears, exactly as
Wikimedia credits are now.

**All EXIF stripped.** Location, device, timestamp — gone before upload, not
after. This is not optional.

### The rule that is easy to miss

> **Sensitive species must never accept community reference images.**

A donated rhino or pangolin photograph can contain recognisable terrain — a
ridgeline, a specific tree, a road marker. Stripping EXIF does nothing about
that, because the location is *in the picture*.

Any species at `sensitivityLevel` `coarse` or `never` keeps its neutral sourced
image permanently. The tier most likely to attract enthusiastic donations is
precisely the tier where donation is most dangerous.

### Sequencing

Launch on the Wikimedia/iNaturalist set. Turn donation on once there are enough
verified captures to be worth moderating — realistically after the first season.
It is a Phase 6+ feature, not a launch dependency.

---

## 4. Dimensions, formats and budgets

| Use | Rendered at | Source needed | Format | Target |
|---|---|---|---|---|
| Codex grid tile | ~190pt → 570px @3x | 800px | JPEG q72 | ≤ 100 KB |
| Codex detail hero | 430×280pt → 1290×840 @3x | **1200px** | JPEG q75 | ≤ 160 KB |
| Silhouette | as tile | derived | PNG, transparent | ≤ 8 KB |
| Card face (the Six) | full bleed | player photo, full res | JPEG q85 | server-side |
| Sighting thumbnail | 110pt → 330px @3x | 400px | JPEG q70 | ≤ 25 KB |

### Two changes worth making

**The detail hero is under-resolved.** Sources are 800px; the hero needs ~1290px
at 3×. It is soft on a modern phone. Re-run the pipeline at 1200px — that takes
the bundle from 6.7 MB to roughly 11 MB.

**WebP would halve it.** Flutter decodes WebP natively, and at equivalent quality
it is 25–35% smaller than JPEG. At 1200px WebP the bundle lands around **7 MB**
— better images than today for the same size. The pipeline needs a WebP encoder;
`cwebp` as a build step is the simplest route.

**Budget context:** the app is 23 MB, of which ~15.9 MB is the Flutter engine and
1.2 MB is fonts. Images are the only asset category that can grow without limit,
so they are the one worth watching. Download size is a real conversion factor,
especially where people install over mobile data.

---

## 5. What commissioning would cost — the avoided path

Illustrations, South African illustrator, 2026 rates. **Estimates, not quotes.**

| Item | Unit | Total |
|---|---|---|
| Codex illustrations, 71 species | R150–400 | **R11,000–28,000** |
| — the 15 rarest only | R150–400 | **R2,300–6,000** |
| Silhouettes | R0 if transparent | — |
| **Den sprites, ~12 species, animated** | **R2,500–8,000** | **R30,000–96,000** |

### The real cost is the den, not the Codex

Static illustrations are affordable; **animated sprites are five to ten times as
expensive per species** and are the single largest line item in the project. That
is why MASTER-VISION.md caps the den at ~12 species, and why it is Phase 7.

### The recommendation

1. **Launch on the CC set.** It is done, it is legal, it costs nothing.
2. **Commission the 15 rarest** when there is revenue — R2,300–6,000 buys the
   cards people actually screenshot, and fixes the camera-trap problem where it
   matters.
3. **Let community photos replace the rest**, progressively and for free.
4. **Do not commission all 71.** Consistency is worth buying, but not before the
   app has users, and community photos may make most of it unnecessary.

---

## Confirmations requested

**User photo storage capped at six full-resolution per player** — confirmed as a
design constraint, but **there is no schema yet**; the backend is Phase 3. Added
to the roadmap so it is enforced when the schema is written, rather than
discovered when the storage bill arrives.

**Den sprites capped at ~12 species** — confirmed, in MASTER-VISION.md and
carried into ROADMAP Phase 7.

---

## The sourcing pipeline (August 2026)

The question "how are we going to add all these birds" has an answer now, and
it is three commands from `app/`:

```bash
dart run tool/source_species_photos.dart      # fetch what is missing
dart run tool/contact_sheet.dart              # look at all of it at once
dart run tool/prepare_species_photos.dart build/sourced-photos
```

`source_species_photos` queries iNaturalist for research-grade observations,
prefers South African ones, and **filters on licence twice** — once in the API
request and once in the parser — because a filter that silently stops working
would put a non-commercial image into a paid app. CC0 and CC-BY only, hard-coded.

### The middle step is not optional

The first automated run produced nineteen photographs and **five of them were
unusable**: a dead barn owl on tar, a flattened boomslang on gravel, and three
vultures too distant to identify. A later run offered a skinned puff adder.

That is not a bug in the tool. **iNaturalist is a biodiversity record, not a
photo library** — a dead animal by the road is a perfectly good record, and it
gets uploaded constantly. Research-grade means the identification is right, not
that the picture is any use to somebody trying to name an animal standing in
front of them.

So `--candidates` fetches eight per species and `contact_sheet` lays them out
for a human to pick from. **Never merge a sourced photo without looking at it.**

### One thing that was got wrong and then fixed

The first ranking put CC0 ahead of CC-BY, on the theory that no attribution
obligation is safer than one. It is not safer, it is just narrower: both
licences are equally fine to ship, so preferring one throws away better
pictures for nothing. That preference is what produced the dead owl. Licence is
a filter; filters do not belong in sort orders.
