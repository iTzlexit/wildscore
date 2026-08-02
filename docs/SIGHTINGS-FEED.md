# The sightings feed

> **Two exciting sightings a day, shared to the leaderboard.** Alex posted these
> today, from here. A social feed for a park.

This is the marketing channel made native. [VISION.md](VISION.md) already says
the share card is not a nice-to-have but *the* distribution mechanism — this is
that, kept inside the app where it also drives return visits.

---

## The shape

- **Two per player per day.** A hard cap, and the cap is the feature.
- **Rare animals only** — Very rare, Exceptional and Legendary, plus the Big
  Five regardless of tier.
- Appears on the **Leaderboard** tab alongside standings, newest first.
- Later: likes and comments. *"Where was that?"* and *"well done on that score"*
  are the two things people will want to say, and both are worth building — but
  neither before the feed itself exists.

## Why two, and why only the rare ones

Both limits exist for the same reason: **a feed of forty impala is not a feed
anyone opens twice.**

Two forces a choice. Choosing is what makes the post feel like a statement
rather than a dump, and it means the feed is always the best thing everyone saw
that day rather than everything everyone saw.

Restricting to rare tiers does the same work from the other side, and has a
second benefit — it makes the feed *aspirational*. Scrolling past someone's wild
dog is precisely the feeling that gets a person back in the park.

## The rule this cannot break

> **Sensitive species must never carry a location in the feed. Ever.**

Rhino and pangolin are `sensitivityLevel: never`. A public feed post is the
single most dangerous surface in the entire app for those species — it is
exactly what a poacher would read.

Three specific requirements, all enforced **server-side**, not in the client:

1. **No coordinates, no map pin, no place name** for a sensitive species. Not
   "near Satara". Not the region. Nothing.
2. **EXIF stripped before upload**, not after. Location, device, timestamp.
3. **Consider blocking the post entirely** for `never`-level species. A rhino
   photograph can contain identifiable terrain — a ridgeline, a windmill, a
   specific tree — and no amount of metadata scrubbing helps when the location
   is *in the picture*.

On (3): I would block rhino and pangolin from the feed and say why in the app.
"This sighting is too sensitive to share publicly" is a message that makes a
player feel responsible rather than restricted, and it is the safer default. It
can always be relaxed; a leaked location cannot be un-leaked.

For everything else, location is **region-level only** — "Central Kruger", never
a pin.

## Moderation

A public feed is a public surface, and the store review process will ask about
it. Needed before launch, not after:

- **Report a post**, reachable from every post
- **A block list** so a player never has to see a specific person again
- **Takedown ability** — a way to remove a post server-side without an app update
- A stated content policy the store can be pointed at

None of this is optional once user-generated content is visible to strangers.
It is also the main reason the feed is not a small feature.

## Offline

Same as everything else: the park has no signal.

- Posts are **selected and queued offline** during the day
- They upload at the **end of the day**, back at camp, alongside the score
- The two-per-day cap is enforced **by day of sighting**, not by upload time —
  otherwise a week's backlog syncing at once floods the feed

## Where it sits in the build

**After the scorecard, and after accounts.** It needs:

1. A backend and real user accounts — a feed of anonymous local names is
   meaningless
2. Photo storage (Cloudflare R2, not Supabase Storage — egress fees)
3. Moderation tooling, which is not optional

Realistically this lands with or just after the leaderboard. It is the single
strongest retention feature in the plan, and it is also the one with genuine
safety obligations attached. Both of those argue for building it deliberately
rather than early.
