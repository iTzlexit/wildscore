# Wild Score — Product Spec

> Working name. Check availability at CIPC and on both app stores before you print
> anything. Avoid any name containing "poke", "dex", "catch 'em" or similar —
> Nintendo enforces aggressively and you do not want that letter.

## The product in one line

A verified wildlife-spotting game for Kruger National Park: photograph an animal in
the park, earn points scaled to how hard it was to find, build a permanent
collection, and compete on a seasonal leaderboard.

## The thing that must not be lost

You played this on paper with your family and loved it. Everything below exists to
protect that feeling, not to replace it. Concretely, the app must nail:

1. **The reveal.** Logging a Pangolin cannot look like logging an Impala. The app
   stops, animates, plays a sound, flips a card, ticks the score up. This is the
   product. Build it in Phase 2, not "when there's time for polish".
2. **The showing off.** One tap from a sighting to a share card good enough to post
   without editing. This is also your entire marketing budget.
3. **The scarcity.** Points must feel earned. If everything is worth something,
   nothing is.

## Scoring

Seven rarity tiers, assigned by how hard the animal actually is to see in Kruger —
not by how famous it is. Lions are easier to find than Sable.

| Tier | Points | Examples |
|---|---|---|
| Common | 5 | Impala, Zebra, Giraffe, Hippo |
| Frequent | 10 | Elephant, Buffalo, Hyena, Nyala |
| Uncommon | 25 | Lion, White Rhino, Klipspringer, Ground Hornbill |
| Scarce | 50 | Leopard, Sable, Honey Badger, Porcupine |
| Rare | 100 | Wild Dog, Cheetah, Roan, Serval, Python |
| Very Rare | 250 | Black Rhino, Aardvark, Aardwolf, Suni |
| Legendary | 500 | Pangolin, Brown Hyena, Pel's Fishing Owl |

**Modifiers (Phase 3+):**
- Big Five and Big Six Birds carry a badge and a completion bonus, not extra base points.
- Night-drive sightings of nocturnal species: ×1.5.
- First sighting of a species: full points. Repeats: 10%, so the collection still
  rewards breadth without making repeats worthless.
- **First Find bonus** — see below.

## Solo finds vs. joining a sighting

In Kruger, most people see lions because fifteen cars are already parked there.
Finding an animal yourself is a completely different achievement from driving up
to a traffic jam, and if both score the same then the leaderboard rewards
whoever passed the most crowds.

**This is detectable.** Sightings of the same species within a few hundred
metres and a couple of hours are one *sighting event*. The earliest capture
timestamp in that cluster is the finder; the rest joined.

Design rules, in order of importance:

1. **Capture the data from day one, ship the feature much later.** Every
   sighting stores a precise GPS fix and capture timestamp from Phase 3. Clusters
   can be computed retrospectively over historical data at any point; data you
   never captured is gone forever. This is the only part that must be right now.
2. **It needs density to work.** Fifty users across 20,000 km² will essentially
   never cluster. The feature improves as the app grows, which makes it a reward
   for growth rather than a launch dependency. Do not block Phase 5 on it.
3. **Bonus, never penalty.** The first finder gets a *First Find* bonus. Joiners
   are not docked — they did see the leopard, and it belongs in their collection.
   The collection records what you have seen in your life and must stay honest;
   the score records difficulty. Keeping those separate is what makes both feel
   fair.
4. **Ordering is server-assigned.** A device timestamp is a number a phone can be
   made to say anything. Capture time is recorded on device out of necessity —
   you are offline — but rank within a cluster is validated server-side at sync.

### The safety rule this creates

**Reward finding. Never reward arriving.**

A bonus for getting somewhere first is a bonus for speeding, for crowding
animals, and for cutting people off at a sighting. There must therefore be:

- No live feed of other people's sightings
- No "lion reported 4km north"
- No visible race, countdown or contested state

The bonus is computed quietly at sync. **You find out you were first when you
get home.** This is consistent with the ban on live sighting maps in
[VISION.md](VISION.md), and for the same reason: chasing animals is bad for the
park, and it would end any SANParks relationship before it started.

## Verification

v1 is deliberately not machine learning. Three signals, all cheap and all honest:

1. **Camera only.** In-app capture. No gallery import, ever. Not a setting.
2. **GPS inside park boundaries** at the moment of capture, stored with the photo.
3. **Device timestamp** at capture.

Offline is the normal case — most of Kruger has no signal. Sightings are written
locally and sync when the phone reconnects. The GPS fix and timestamp are captured
at the moment of the photo, so an offline sighting is exactly as trustworthy as an
online one.

Community review (Phase 6) handles the leaderboard tail: top-ranked players' rare
sightings are visible to other players, who can flag them. Cheating a leaderboard
nobody can see is not fun; cheating one everybody can see is hard.

## Sensitive species

**White Rhino, Black Rhino and Pangolin sightings never expose location.** Not to
friends, not on the leaderboard, not in the share card, not in exported data. The
sighting counts for points; the coordinates are stored encrypted and are never
rendered. This is a poaching-risk decision and it is not negotiable for a feature
request later.

The same rule applies to any species flagged `isSensitive` in the dataset.

## Monetisation

- **Season Pass** — one non-renewing annual purchase, ~R249. Unlocks the
  leaderboard, the full collection and share cards.
- **Free tier** — the Codex (the field guide) is free and always works. It is the
  hook and it is genuinely useful, which is what gets it recommended.
- **Later** — regional challenge packs, printed end-of-season collection cards,
  guided-operator tie-ins. Never pay-to-win on the leaderboard.

## Phases

| # | Phase | Contents |
|---|---|---|
| 0 | Validation | Post the concept in Kruger communities. Get 30 people saying they'd pay. Costs one evening. |
| 1 | **Species Codex** | Field guide: every species, rarity, points, regions, where and when to find them. No camera, no GPS, no account. ← **you are here** |
| 2 | Capture & collection | Camera capture, local storage, the reveal animation, the collection view with silhouettes for unfound species, share cards. Still offline-only, still no account. |
| 3 | Map & verification | Offline park map, GPS at capture, region tracking, night-drive multiplier. |
| 4 | Accounts & sync | Supabase auth, sighting sync, multi-device. |
| 5 | Leaderboard & Season Pass | Seasonal standings, RevenueCat, the annual reset. |
| 6 | Social | Friends, community flagging, group trips, the family scoreboard you actually played on paper. |

Phases 1–3 are a complete, sellable, offline product on their own. If the project
stops at Phase 3 it is still worth having built.

## Data accuracy

Distribution, seasonality and rarity in `species.json` are a solid first pass, not
gospel. Before launch, get a Kruger guide or an SANParks contact to review the
tier assignments and regional ranges. Getting Sable's range wrong is the kind of
error that loses you the exact users who care most.
