# Species artwork

The app runs without any files in this folder. Missing images fall back to a
generated monogram plate tinted to the species' rarity, so nothing looks broken
while you sort the art out.

## What goes here

One file per species, named for its `id` in `assets/data/species.json`:

```
assets/species/ground-pangolin.jpg
assets/species/impala.jpg
```

**Format:** JPEG, quality ~85
**Dimensions:** 1200 × 900 (4:3), subject centred and roughly filling the frame
**Budget:** keep every file under 250 KB — 71 species at 250 KB is ~18 MB, and
app-store download size is a real conversion factor.

The list screen crops to a 72 × 72 square from the centre and the detail screen
shows the full width at 280px tall, so keep the animal off the extreme edges.

## Sourcing — read this before you download anything

**Do not pull images from a Google image search.** Almost all of them are
copyrighted, and an app-store listing is exactly the kind of commercial use that
gets a takedown or an invoice.

Legitimate options, roughly in order of how well they'd serve this app:

| Source | Licence | Notes |
|---|---|---|
| **Your own photos** | Yours | You have been to Kruger. This makes the app genuinely yours and costs nothing. |
| **Commissioned illustrations** | Yours, work-for-hire | A South African illustrator, ~R150–400 per species. Expensive in total, but see below. |
| [iNaturalist](https://www.inaturalist.org) | Mostly CC | Excellent African coverage. Filter to CC-BY or CC0 and record the photographer. |
| [Wikimedia Commons](https://commons.wikimedia.org) | CC / public domain | Attribution required. Quality is uneven. |

### A recommendation

For a collection game, **illustrations beat photographs.** A consistent
illustrated set makes the cards feel like a set — which is the whole point — and
a silhouette version of an illustration reads far better as a locked, unfound
species than a blacked-out photo does. It also sidesteps licensing entirely,
because you own the work.

You do not need all 71 at once. Commission the 15 rarest first: those are the
cards people will screenshot and post, and they are what the app is selling.

## Attribution

If you use anything CC-licensed, credits are legally required and belong in an
in-app licences screen. Track them in `assets/data/attributions.json` as you go —
reconstructing this later, after fifty downloads, is miserable.
