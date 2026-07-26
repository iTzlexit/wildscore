# Vision — what we are actually building

> This is the north star. When a technical decision is genuinely close, the one
> that better serves this document wins. Re-read it before starting any phase.

---

## The core loop — this *is* the app

Everything below this line is detail. This is the product:

> **You photograph an animal in the park. The moment the shutter fires, it is
> caught. It is scored by how hard it was to find, it lands permanently on your
> profile, and your position on the leaderboard moves.**

Four things, in a loop, and nothing may get between them:

| | |
|---|---|
| **Catch** | Camera only, in the park. The shutter is the catch. |
| **Score** | Points by rarity. An impala is 5. A pangolin is 500. |
| **Profile** | Your permanent collection and your total. It is *yours*, and it grows for years. |
| **Rank** | A seasonal leaderboard of verified sightings. Your standing among other trackers. |

The reason a player drives one more loop road at last light, and the reason they
come back to Kruger next winter, is that **there are rare animals out there that
are not yet on their profile.** Every feature either serves that sentence or it
does not belong in the app.

### The catch moment

This is the Pokémon comparison made literal, and it is the single most important
interaction in the product. When the shutter fires:

1. **The animal is caught.** Not "submitted", not "pending review". Caught.
2. The app **stops** — the whole screen is the catch. Nothing else on it.
3. A card turns over revealing the species, its tier and its points.
4. **The score counts up.** Visibly, with sound, at a speed set by rarity.
5. If it is new to the collection, it says so loudly. First ones matter most.
6. One tap to show someone.

A pangolin must not resemble an impala at any point in that sequence. Common
species get a brief, satisfying acknowledgement. Legendary ones get a
full-screen event that a person in the car will lean over to watch.

**Nothing may sit between the shutter and the reveal.** No loading spinner, no
network call, no "syncing". The verification, the GPS write and the eventual
upload all happen behind the celebration. The player never waits to find out
what they caught.

---

## Where it came from

A family trip to Kruger, and a scorecard on paper. Everyone in the car keeping
their own tally, arguing about whether a glimpse of a tail counts, comparing
totals at the gate. The game was better than the drive.

The paper version has three problems, and the app exists to solve exactly these:

1. **Nothing is verified.** Whoever argues hardest wins.
2. **Nothing survives the trip.** The scorecard gets thrown away at the gate.
3. **Nobody outside the car ever sees it.**

Everything else is decoration.

## The end goal, in one paragraph

A South African family plans their July Kruger trip and buys the season pass
before they leave, the way they'd buy the park map. For four days, every animal
they see gets photographed in the app — offline, no signal needed. Rare
sightings produce a moment in the car where everyone leans over to look at one
phone. On the drive home there's a real argument about the final standings. That
evening a share card goes onto WhatsApp and Facebook, and three people who see
it ask what the app is. Their collection is still there in December, and it is
still there when they come back next winter — but the season has reset, the
leaderboard is open again, and the pangolin they got in 2027 is worth bragging
about for the rest of their lives.

## The feeling we are protecting

The user described it as the feeling of catching a Pokémon and showing it off.
That is the correct reference and the honest one — a collection game whose
appeal is scarcity, permanence and status.

Three feelings, in priority order:

**1. The reveal.** The seconds after you log a rare animal. The app must stop
everything — animation, sound, a card that turns over, the score climbing. A
pangolin cannot feel like an impala. This is the product. Everything else is
supporting structure.

**2. The showing off.** One tap from a sighting to something worth posting. If
it takes four screens, nobody shares, and if nobody shares, nobody hears about
the app. This is simultaneously the emotional payoff and the entire marketing
budget.

**3. The permanence.** The collection is a record of years in the park, not a
score that resets. Seasons reset; the collection never does. What you found in
2027 is yours forever.

> **A discipline note.** Pokémon is our internal design reference and nothing
> more. No public-facing name, icon, tagline, screenshot or store listing should
> evoke it — not "poke", not "dex", not "gotta catch". Nintendo enforces
> aggressively and a takedown after launch would be fatal. The inspiration is
> private; the product is its own thing.

## What "finished" looks like

A visitor can:

- Browse a genuinely useful field guide to the park, free, before they've paid
  anything — species, rarity, points, where and when to find them
- Buy a season pass once, for a year, with no subscription and no renewal trap
- Photograph animals **in the app only**, with GPS and timestamp captured
  automatically, working entirely offline for days at a time
- Watch a rare find get the reveal it deserves
- Keep a permanent, personal collection that grows across years and trips
- Compete on a seasonal leaderboard that resets, so newcomers always have a
  reason to start
- Share a single beautiful card in one tap
- Play against their own family in a private group, which is where this started

And SANParks, or a guide, or anyone who cares about the park, can look at the
app and find nothing objectionable in it.

## What success looks like

Concrete, in rough order of when they'd happen:

| Milestone | Why it matters |
|---|---|
| 30 people in a Kruger Facebook group say they'd pay R249 | Validates the whole thing for the cost of one evening |
| 12 closed testers, 14 days, Google Play requirement cleared | The gate that blocks most solo developers |
| One stranger posts a share card unprompted | Proof the reveal-and-share loop works |
| 500 season passes in the first year | ~R125k. Real, and achievable in a market this size |
| A returning user buys a second season | The retention model is real, not a one-off novelty |
| A guide or lodge recommends it to guests | Distribution that doesn't cost money |

## Non-negotiables

These are settled. They are not open to being traded away later for
convenience, and this section exists so that future-you cannot quietly reverse
them under deadline pressure.

**Camera only.** Never a gallery import. Not as a setting, not as an
accessibility option, not "just for testing". The moment a photo can come from
the camera roll, every score in the app is worthless and the leaderboard is a
lie.

**Rhino and pangolin locations are never shown.** Not on a profile, not on the
leaderboard, not in a share card, not in an export, not to friends. Sightings
count for points; the coordinates are stored encrypted and never rendered.
Poaching is not a hypothetical risk in Kruger. If this ever conflicts with a
feature, the feature loses.

**Offline is the normal case, not the fallback.** Most of the park has no
signal. Everything must work for four days with the phone in aeroplane mode and
sync cleanly afterwards. An app that needs a connection to log a sighting is
useless in the place it was built for.

**Rarity tracks reality.** Points reflect how hard an animal actually is to
find, not how famous it is. Lion is easier than sable. If the scoring doesn't
match what experienced visitors know, we lose exactly the users who care most.

**No pay-to-win.** Money buys access and cosmetics. It never buys points,
multipliers or leaderboard position.

**The season pass never auto-renews.** People visit once a year. A subscription
breeds cancellations and resentment; a pass matches the rhythm of the thing.

## What this is not

- **Not a social network.** Sharing points outward, to WhatsApp and Facebook.
  We are not building a feed.
- **Not a conservation-data platform.** iNaturalist exists and is better at it.
  If real records emerge as a by-product, that's a bonus and a possible SANParks
  conversation — not a requirement.
- **Not a safari-booking or trip-planning app.** Scope creep dressed as
  business model.
- **Not AR, not live maps of other people's sightings.** Chasing other players
  to a leopard is bad for the animals and bad for the park, and it would end
  any relationship with SANParks before it started.
- **Not multi-park at launch.** Kruger, done properly, by someone who knows it.
  Addo and the Kgalagadi are what version 3 looks like if version 1 works.

## The test

Before building anything, ask:

> **Does this make the moment of finding a rare animal better, or make it
> easier to show someone?**

If neither, it is probably Phase 5 work being done in Phase 2.
