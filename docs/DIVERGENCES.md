# Divergences from MASTER-VISION.md

[MASTER-VISION.md](../MASTER-VISION.md) is canonical and arrived after Phase 1
was already built. This records every place the code and the working docs
disagree with it.

**No code has been changed yet.** This is the audit, not the migration.

---

## 1. The positioning is inverted — fix this first

**MASTER-VISION.md opens with:**

> Wild Score is where your Kruger sightings live, so you can visit them when you
> miss the park.
>
> This is also the business model. People don't resent paying to keep a photo
> album. They resent paying for leaderboards.

**Our `docs/VISION.md` opens with:** *Catch → Score → Profile → Rank*, framed as
"the reason a player drives one more loop road at last light."

Both describe the same app. They point the product in different directions.

The master's frame is **memory first, game second** — the competition exists to
make the collection worth building, not the reverse. Ours reads as a competitive
game that happens to keep photos. That difference decides:

- Whether the app feels good in October, when the next trip is in July
- **What people are willing to pay for.** The master's monetisation follows
  directly from its framing, and ours does not: we put the paywall on
  *submitting your score*, which is paying for a leaderboard — the exact thing
  the master says people resent.

**This is the single most important correction in this document.** Everything
else is mechanics.

`docs/VISION.md` needs rewriting around the master's sentence.

---

## 2. Settled — confirmed, keep as built

| Decision | Note |
|---|---|
| **Supabase**, not self-hosted ASP.NET Core + R2 + Render | Confirmed by Alex. Master's stack section is superseded here. |
| **Sensitive locations never rendered** | Master says "coarse grid **or nothing**" — never-render is the "or nothing" branch, and stricter. Compliant. |
| **The reveal lands with the camera**, not before it | Master puts the reveal in Phase 1 as part of the Codex; there is nothing to reveal until capture exists. |
| **No packages before there is a problem** | Riverpod and Drift deferred. Master names both; timing is ours. |

---

## 3. Mechanics we do not have at all

### Quick Log — the biggest functional gap

**One tap, no photo, under three seconds from app open.** Builds the Codex,
scores points, feeds Wild Card objectives. It is how you record the forty
impala, in a moving car.

We specced camera capture as the *only* way to record a sighting. That is wrong,
and it makes the app unusable at the speed it actually needs to work.

It also resolves the argument we had about capture ordering: **Quick Log is the
fast path.** Pick-species-then-shoot is fine for Capture precisely because Quick
Log exists for everything else.

### Trip sessions — a different trust model

> Verify the session, not each individual image.

A session opens when the device enters the park boundary and stays valid while
the GPS trace is continuous, on known roads, at plausible speeds, within gate
hours. **Everything captured inside a valid session inherits that trust.**

We specced per-photo GPS + timestamp. The session model is stronger and cheaper:
forging eight hours of coherent trace on real park roads is harder than driving
there.

### The Codex middle state

Three states: undiscovered silhouette → **logged (stock image)** → verified
(your photo replaces the stock image permanently, plus a tick).

We built two. The *logged* state is missing, and it is the state Quick Log
produces — so the two gaps are the same gap.

**Confirmed by Alex:** logged → verified is automatic on sync. No separate
action.

### Also entirely absent

- **Collection of Six** — six promoted captures, freely swappable, the only ones
  stored at full resolution
- **The Den** — the six as animated sprites; tap opens your real photo. ~12
  eligible species. Never build hunger, decay or streaks.
- **Species Crowns** — per-species seasonal holder, Hall of Fame for past
  holders. Quick Logs never earn crowns.
- **Ranks** — Day Visitor → Tracker → Ranger → Field Guide → Head Ranger →
  Legend
- **Wild Card** — daily objective, generated locally at trip start
- **The sync ritual** — cards flipping pending → verified one at a time. "Don't
  hide it behind a spinner."
- **Provisional scoring** — live score during the drive, points confirm later
- **No points for off-road positions or speeding** — detectable from the trace
- **Four photos per capture**

---

## 4. Naming collision: "Tracker" is a rank

We call every player a **Tracker** — it is on the onboarding card, the profile
strip, and throughout the copy.

In the master, **Tracker is the second of six ranks**: Day Visitor → *Tracker* →
Ranger → Field Guide → Head Ranger → Legend.

So the app currently promotes every new user to rank two on signup and calls it
their identity. This must be renamed before ranks ship, and it is user-visible
copy in several places.

---

## 5. Rarity tiers — mapping from the master's examples

Two tiers are deleted (`uncommon`, `scarce`) and the curve changes shape. The
master's examples settle roughly 30 of our 71.

| Species | Ours now | Master says | Move |
|---|---|---|---|
| Impala, zebra, wildebeest, kudu, warthog, baboon, vervet | common 5 | Common 5 | — |
| **Giraffe, hippo, waterbuck** | common 5 | **Frequent 15** | up |
| Elephant, buffalo, nyala, crocodile | frequent 10 | Frequent 15 | revalue |
| **Spotted hyena** | frequent 10 | **Notable 30** | up two |
| White rhino, lion | uncommon 25 | Notable 30 | revalue |
| Leopard | scarce 50 | Rare 60 | revalue |
| **Cheetah** | rare 100 | **Rare 60** | down |
| **Black rhino** | veryRare 250 | **Rare 60** | down two |
| African wild dog, roan | rare 100 | Very rare 100 | rename only |
| **Sable, honey badger** | scarce 50 | **Very rare 100** | up |
| **Serval, caracal** | rare 100 | **Exceptional 200** | up |
| Aardwolf, aardvark | veryRare 250 | Exceptional 200 | revalue |
| Pangolin | legendary 500 | Legendary 400 | revalue |

**Worth querying with the Kruger guide:** black rhino at Rare 60 sits below wild
dog at Very rare 100. In Kruger, black rhino sightings are meaningfully rarer
than wild dog — they are far fewer animals in far thicker bush. This may be
deliberate; it may be an artefact of the examples being illustrative rather than
exhaustive.

The remaining ~40 species have no example to map from and need judgement.

---

## 6. Leaderboards — we built one the master forbids

> **Never build a "most sightings today" leaderboard.** It rewards racing
> between sightings, which is exactly what the Quiet Sighting bonus exists to
> discourage.

`docs/SPEC.md` currently specs four boards, including **"Best single trip — one
visit, one score."** That is the banned mechanic with a different window.

The master's answer to "how does a casual player win something" is **Species
Crowns** — 45 separate competitions — not more leaderboards. That is a better
answer than mine and it replaces the four-board scheme.

Keep: the Collection board (breadth over years) is compatible with crowns and
ranks. Drop: best-single-trip.

---

## 7. Monetisation — prices and the paywall are both wrong

| | Ours | Master |
|---|---|---|
| Season Pass | R249 | **R199** (R149 founding season), $14.99 international |
| Vehicle Pass | R499 | **R399** / $29.99 |
| Free tier | Codex, camera, collection | Camera capture, Quick Log, live scoring, daily scorecard, trip summary, **full Codex browsing** |
| Pass unlocks | Leaderboard, share cards, stats, submitting your day | **Collection of Six, the Den**, crown/leaderboard eligibility, share cards, Quiet Sighting mode, badges |

**The paywall placement is the real error.** We put it on *submitting your day's
score* — which is charging for a leaderboard, the thing the master explicitly
says people resent.

The master sells **the Six and the Den**: keeping your photos, beautifully. That
follows from the positioning in §1, and it is why §1 matters more than any
mechanic in this file.

Per-territory pricing is also missing from our doc: an international visitor
already pays R602/person/day in conservation fees, so $14.99 is invisible to
them while a South African family feels every rand.

---

## 8. Scope: 45 species or 71?

The master says 45 throughout — "all 45 species", "forty-five separate
competitions". We shipped **71**, including 11 birds and 5 reptiles.

Not necessarily wrong, but it is a decision, and it changes crowns (71
competitions, not 45) and the Codex completion percentage.

---

## 9. Build order — 12 phases, not 7

Our roadmap's seven phases predate the master. Its twelve are authoritative and
`ROADMAP.md` should be restructured to match.

Note **the Den is Phase 7** — the most expensive thing in the project, and the
most tempting to build early. The master says: resist.

Where we actually are: **Phase 1 complete except the three-state model and the
reveal animation.**

---

## What still needs a decision from Alex

1. **Rewrite `docs/VISION.md` around the master's framing?** (§1) — my
   recommendation is yes, and first.
2. **Re-tier the ~40 species** the examples do not cover, and confirm the black
   rhino / wild dog ordering. Best done in the same pass as the guide's review.
3. **45 species or 71?** (§8)
4. **Rename the player noun** — "Tracker" is taken by the rank system (§4).
5. **Drop the best-single-trip board** in favour of crowns? (§6)
6. **Confirm the Supabase call still stands** now that the master specifies
   ASP.NET Core + R2 + Render. Alex has already said yes; noting it because the
   canonical document disagrees.
