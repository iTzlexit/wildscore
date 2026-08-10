# Letting a car set its own prices

> Added 10 August 2026, on Alex's suggestion, after a long argument with
> ourselves about whether a bird should ever outscore a lion.

## Why this exists

Our points are **one opinion, taken nationally**, and Kruger is not one place.

Sable and roan are the sighting of the trip in the south and close to a Tuesday
on the Punda Maria road. A car based in the far north for a week is playing a
different game from a car at Berg-en-Dal, and no single table is right for both.

We spent several rounds trying to find the table that was right for everyone.
There isn't one. So the table ships as a **default**, and anybody who disagrees
moves a number.

## How it works

Open any animal in the Animal Dex, tap **"Worth something else to you?"**, and
move the slider.

- The slider steps through **fixed rungs** — the same ones every animal in the
  catalogue already sits on. No free numbers: somebody putting an impala on 999
  would quietly wreck their own game, and this is operated with a thumb in a
  moving vehicle.
- The card says **"You changed this from 250"** afterwards, and offers to put it
  back. An edit you cannot see or undo is a trap.
- Choosing the catalogue's own value stores **nothing**, so a future
  revaluation still reaches you.

Stored in `shared_preferences` as `{speciesId: points}`, holding only what
differs. The common case is an empty map.

## Why it is applied at load

`SpeciesRepository.loadAll(housePoints: …)` folds the overrides in when the
catalogue is read, which happens once at startup. Everything downstream — the
dex tiles, the claim sheet, the standings, the sightings feed — sees the edited
number **without knowing the feature exists**.

The alternative was passing an override map to every call site that scores
something, which is four places today and a bug the first time somebody adds a
fifth.

**Past drives are unaffected.** A claim stores the points it scored at the time,
so a table edited in March cannot rewrite February.

## What it does not change

- **The rarity tier.** That is a field-guide fact about how hard an animal is to
  find nationally, and it still drives the filters, the collections and the
  sightings feed. Only the *game value* moves.
- **The modifiers.** Everything else is a proportion — the male lion is ×1.5,
  a jam is −20%, a night animal in daylight is ×2.5 — so they all ride on top
  of whatever the player chose. This is why flat bonuses were removed.
- **The decay on elephant and buffalo.** Also a multiplier, for the same
  reason: revalue an elephant to 200 and the third of the day is 80.

## The ladder

Every score in the game, and every value the editor offers:

| Tier | Rungs |
|---|---|
| Common | 5, 10, 15 |
| Frequent | 20, 30, 40, 55 |
| Notable | 60, 80, 100, 120, 140 |
| Rare | 150, 200, 250, 320 |
| Very rare | 350, 425, 500, 550 |
| Legendary | 600, 750, 875, 1000 |

**Ties are the feature.** Ranking 190 animals by hand produced 190 distinct
numbers, which claims we can tell the seventeenth-hardest Notable from the
eighteenth. Nobody can. Snapping to a coarse ladder says the true thing — these
six are about as hard as each other, and that lot are harder — and collapses
190 animals to 24 scores.

The bands never overlap, so the worst Legendary still beats the best Very rare.

## The three things a car can change

Added 10 August 2026, on Alex's suggestion. All of them hold **only what
differs from the default**, so the common case is an empty object and an update
that changes our minds still reaches everybody who never had an opinion.

### 1. What an animal is worth

On the animal's own page in the Dex. Slider, fixed rungs, described above.

### 2. How often it can be claimed

Same page, under the score: **twice a day**, **4 a day**, **once this trip**, or
**no limit**.

Once-a-trip is the interesting one. Set it on everything and the scorecard stops
being a scoreboard and becomes a checklist — find each animal once, and the
winner is whoever found the most different things. Some cars will want exactly
that, and it costs us nothing to allow it.

Three states, not two: a cap, **no cap**, and no opinion. A car that wants
unlimited impala has to be able to say so, and that is not the same as never
having asked — our default can still move under the second and must not move
under the first. Stored as a present key holding null.

### 3. What a traffic jam costs

**Profile → House rules.** Anything from nothing to half, in tenths.

Zero is a real choice, not a token one: some cars will decide a sighting is a
sighting and the tax is us being clever at them. The claim sheet's button reads
the car's own number, so a car on 40% never sees a button saying 20%.

Choosing our own value **clears the setting** rather than storing a copy of it.
Otherwise a car that agreed with us in August would be pinned to that number
when we changed our minds in September.

## Two views of the catalogue

The Dex toggles between them from the row above the list.

- **Grid** — big photographs, grouped Animals then Birds. For browsing.
- **Ranking** — one line each, numbered, rarest at the top, straight through
  from the pangolin to the impala. For comparing.

The ranking ignores the Animals/Birds split, because a ranking with two number
ones is not a ranking, and it ignores the chosen sort, because rarest-first is
the only order in which it means anything.

**A bug this shook out:** "Rarest first" sorted by *tier* and then
alphabetically, which was identical to sorting by points back when every animal
in a tier scored the same. It is not identical now — it put the aardvark above
the pangolin, on a list whose whole promise is that the top is the hardest thing
in the park. It sorts by points now, and the tier ordering falls out of that
because the bands do not overlap.
