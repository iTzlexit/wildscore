# Species artwork

The app runs without any files in this folder. Missing images fall back to a
generated monogram plate tinted to the species' rarity, so nothing looks broken
while you sort the art out.

---

## The key idea: the player's own photo becomes the card

The obvious plan is to license 71 animal photographs and be done. Do not do only
that, because it misses the best thing available to you.

**Once a species is caught, the card shows the player's own photograph of it.**

That is enormously more powerful than any stock image. Their collection is not a
set of pictures someone else took — it is a record of animals *they* found, in
their own photos, with the date and the score attached. Nobody else's collection
looks like theirs. And it costs nothing and licenses nothing.

This resolves the Codex/collection tension cleanly, by making them two screens
with two jobs:

| Screen | Purpose | Image shown |
|---|---|---|
| **Codex** | Field guide. Free, always useful, the hook. You must be able to identify an animal you have *not* found. | Reference art, always visible |
| **Collection** | Your trophy case. | **Silhouette** until caught → **your photo** after |

So the Codex is never mysterious — it is a working field guide, which is what
makes it worth recommending. The *collection* is where the empty slots stare at
you, and where the pangolin-shaped hole makes you want to go back.

## What you actually need to source

Per species, two things:

1. **A reference image** for the Codex — 1200 × 900, subject centred
2. **A silhouette** for the uncaught state in the collection

If you commission illustrations with transparent backgrounds, **the silhouette
is free** — fill the alpha channel with a flat colour at build time. That alone
is a good argument for illustration over photography.

### Naming

Files are named for the species `id` in `assets/data/species.json`:

```
assets/species/ground-pangolin.webp
assets/species/ground-pangolin-silhouette.webp
```

## Size budget — this matters more than you would think

The whole app is currently **16.3 MB**, and 15.9 MB of that is the Flutter
engine. Everything we have written is about 400 KB.

**71 images at 250 KB each is 18 MB — it would more than double the app.**
Download size is a real conversion factor on the store, especially in a market
where plenty of people install over mobile data.

So:

- **Use WebP, not JPEG.** Roughly half the size at the same quality, supported
  natively by Flutter. `cwebp -q 80` is the whole workflow.
- Target **≤ 80 KB** per reference image. At 800 × 600, WebP quality 80, that is
  comfortable.
- Silhouettes are flat colour and compress to almost nothing.
- 71 × 80 KB ≈ **5.7 MB**. Acceptable. 71 × 250 KB is not.

**Images must ship inside the app, not download on first run.** Offline is a
non-negotiable (see [VISION.md](../../../docs/VISION.md)) and a player who
installs at the gate with no signal must still get a working field guide.

## Sourcing — and the copyright trap

**Do not pull images from a Google image search.** Almost all are copyrighted,
and an app-store listing is exactly the commercial use that attracts a takedown
or an invoice.

| Source | Licence | Verdict |
|---|---|---|
| **Commissioned illustrations** | Yours, work-for-hire | Best. Consistent, silhouette-ready, owned outright |
| **Your own photos** | Yours | Free and authentic — but you have no pangolin photo |
| [iNaturalist](https://www.inaturalist.org) | Mostly CC | Good African coverage. Filter to CC-BY or CC0, record the photographer |
| [Wikimedia Commons](https://commons.wikimedia.org) | CC / public domain | Attribution required, quality uneven |

### The recommended plan

1. **Ship with CC photos.** Free, fast, gets you to launch. Track attributions
   in `assets/data/attributions.json` **as you go** — reconstructing this after
   fifty downloads is miserable, and it is a legal requirement, not a nicety.
2. **Commission illustrations for the rarest tiers as money allows.** Start with
   the 15 Legendary/Very Rare/Rare species. Those are the cards people
   screenshot and post, and they are what the app is selling.
3. **Let player photos do the rest.** Every caught species stops needing your art
   the moment it is caught.

### On consistency

Seventy-one excellent photographs from seventy-one photographers still look like
a database. One illustrator working through all seventy-one in a single style
looks like a **set** — and wanting to complete a set is the entire psychology
this app runs on. If you can only afford one thing, buy consistency.

### A caution on AI-generated art

Tempting, and wrong here. Generated animals get anatomical details subtly wrong,
and your most valuable users are exactly the people who will notice a sable with
the wrong horns. For a field guide that people trust to identify real animals,
accuracy is the product.
