# Maps — what to build, and what not to

> Research and recommendation, 2 August 2026. No code yet.

## What already exists

Every serious Kruger app has an offline map. It is table stakes, not a
differentiator:

| App | What it does |
|---|---|
| [Latest Sightings](https://latestsightings.com/app) | The big one. Real-time community sightings, pins load offline |
| [KrugerGuide](https://kruger.guide/) | Fully offline map, live location, filterable points of interest, community sightings board |
| [KrugerExplorer](https://www.krugerexplorer.com/the-app) | Offline, plus a species life list |
| [Kruger Animal Tracker](https://www.krugeranimaltracker.com/) | Verified live sightings and offline maps |

Two things follow. **Nobody will choose Wild Score because it has a map** — that
race is run. And **an offline map is not novel enough to be the next big
feature** unless it does something the others do not.

## Three different maps, wildly different costs

These get conflated. They are not the same product.

### 1. "Where I found it" — a personal map

Your own sightings, plotted. Private, nobody else sees it.

This is the one that fits. [VISION.md](VISION.md) says the app is where your
sightings live so you can visit them when you miss the park, and a map is the
most natural possible expression of that. It is also the only one of the three
that nobody else is doing, because the others are all *live community* products.

### 2. "Where am I" — a navigation map

Camps, gates, roads, a blue dot. Genuinely useful, and four apps already do it
well. Worth having eventually; not worth being the reason anyone downloads this.

### 3. "What is everyone seeing" — a live sightings map

**Do not build this.** Two reasons, and the first one is not a design opinion:

> In 2016 the BBC reported that South African national parks were
> [considering banning wildlife sighting apps](https://feeds.bbci.co.uk/news/technology-36489080)
> outright, on the grounds that broadcasting animal locations aids poachers and
> causes traffic jams at sightings.

That risk has not gone away, and it lands on apps that broadcast locations in
real time. Wild Score is currently a personal record and a car game, which is a
different category and a much safer one. Building a live sightings map moves it
into the category under scrutiny, and takes on moderation, liability and a
regulatory dependency at the same time.

Second reason: Latest Sightings has a decade of head start and the community
already lives there.

## The rule that constrains all of it

**Latest Sightings — the largest app in this space — does not report rhino
sightings at all.** Not blurred, not delayed. Not at all, because of poaching.

That is the industry standard set by the people closest to the problem, and it
is stricter than anything we have written down. Ours should match it:

> **Rhino and pangolin never get a location. Not shared, not private, not
> region-level, not on the device.**

The "not even privately" part matters more than it looks. Backups leave the
phone — that is the entire point of the feature built today. A rhino coordinate
sitting in a backup blob in somebody's Gmail is a real exposure, created by a
feature designed to be helpful.

## What it would actually take

### A real offline tile map: moderate, and heavy

| | |
|---|---|
| **Raster tiles** | Simple to render, huge. Kruger to zoom 14 is roughly 5,000 tiles, call it 40–80 MB on a 56 MB app |
| **Vector tiles** | Roughly 10–20 MB for the same area, but needs a renderer — `maplibre_gl` (native, large) or `vector_map_tiles` (pure Dart, slower) |
| **Licensing** | OpenStreetMap's tile policy forbids bulk downloading. MapTiler and Mapbox charge, or you host tiles yourself — which is a server, which is the thing we do not have |

Doable. Not cheap in app size, dependencies, or decisions.

### A drawn map: easy, and possibly better

Kruger's road network is unusually simple: one tar spine (H1-1 through H1-9),
a couple of dozen numbered H and S roads, twelve main rest camps, nine gates.

A hand-built SVG of that is a few hundred kilobytes, renders instantly, needs no
tiles, no licence, no server and no native dependency — and is **more legible in
a moving car** than an OpenStreetMap render, because it shows only the things
that matter and none of the things that do not.

This is what a paper Kruger map looks like, and there is a reason that design
has survived sixty years.

## Recommendation

**Start without GPS at all.**

Location permission is not free: a prompt, a privacy-policy section, a
store-review question, POPIA obligations, and a battery cost. And it is not
needed — the data already has `parkRegions` on every species, and a player can
tap *where* in two taps when they end a drive.

In order:

1. **Ask "which part of the park?" when a drive ends.** One tap, three options,
   no permission, no map. The collection can then say *you found this one in the
   north*, and the drive history gets a place as well as a date. Cheap, and it
   is most of the emotional value of a map.
2. **A drawn map screen** with camps, gates and roads, and your drives plotted
   by region. Still no GPS, still no permission.
3. **Real tiles and a blue dot** — only if people ask, and only once there is a
   reason to carry the weight.

## But should this be the next feature at all?

Honestly: probably not.

A map is a *want*. The things standing between this app and its first real users
are all smaller and duller — the rarity rankings are still unreviewed, there is
no licences screen, and the Google Play tester clock has not started and takes
fourteen calendar days that cannot be compressed.

The map is a very good second season feature. Shipping is the first one.
