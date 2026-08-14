# How Wild Score is written

> **Follow this for every word that ships** — onboarding, rules, buttons,
> empty states, store listing, emails. Set by the owner on 9 August 2026 after
> reading the whole of the onboarding back. Where this document and a clever
> sentence disagree, this document wins.

## Who is reading

Somebody on holiday, at a gate, at six in the morning, with the engine running
and people in the car waiting. They are excited and they are in a hurry. They
want to start playing, not to be taught.

That reader is the test for every line. Not "is this accurate" — it always is —
but **"would they read this now, or skip it?"**

## The rules

1. **One screen, one question.** If a screen answers two things, it is two
   screens or it is one screen with something deleted.
2. **Two or three lines a paragraph.** Never more.
3. **Never explain the same idea twice.** If the heading says it, the body does
   not repeat it. This is the single commonest fault in what we have written.
4. **Cut, then cut again.** The last full pass removed about 40% of the words
   and lost nothing.
5. **Simple language.** No jargon, no invented terminology, nothing a
   fourteen-year-old in the back seat would have to ask about.
6. **Active voice.** "Press Start Drive", not "the drive can be started".
7. **Playful, not instructional.** This is a game people play on holiday. It
   should not read like a manual, and it should not read like a warning label.
8. **Do not open on the reader's disappointment.** An early draft led with "six
   hours of driving, and nothing to show for it". Naming a problem is a real
   technique and it is the wrong one here: nobody at a gate at dawn wants to be
   told their last holiday was a let-down. Ask them a question instead.

## Vocabulary

Use **spot** and **sighting**. Consistently, everywhere.

| Use | Not |
|---|---|
| spot | find, see, get, bag |
| sighting | spotting, find, one |
| player | user, participant |
| vehicle, car | party, group |
| points | score (as a noun for one animal) |

"Claim" is allowed for the specific act of taking a sighting for a player —
"the first player to call the animal claims the sighting" — because that is
what the button does. It is not a synonym for spotting.

## Tone, by example

**Good.** Short, active, one idea, and it sounds like a person.

> **Claim a Spot**
> The first player to call the animal claims the sighting.
> Tap the eye icon, choose the animal, and the points go to that player.

**Bad.** Two ideas, a hedge, and an explanation nobody asked for.

> When a member of your party identifies an animal, the first person to make a
> verbal identification is credited with the sighting. Note that pointing does
> not count. You may then use the eye icon adjacent to the player's name in
> order to record which animal was seen, at which point points will be
> allocated accordingly.

## The tier names

Set by Alex on 10 August 2026. Use them exactly, capitalised as written, and
never the old ones — the words are the whole point.

| Tier | Band | It means |
|---|---|---|
| **Ghost** | 600–1000 | You can go a whole career without seeing one. |
| **Mirage** | 350–550 | You think you see it, and it vanishes. |
| **Cryptic** | 150–320 | Hiding in plain sight. |
| **Prize** | 60–140 | What everybody is hoping for. |
| **Bush Icons** | 20–55 | Why Kruger is famous, and seen most trips. |
| **Bush Staples** | 5–15 | The reliable everyday ones. |

They replaced Legendary, Very rare, Rare, Notable, Frequent and Common — six
words for one idea, three of which mean "rare", and no reader could say which
of Rare and Very rare was worse. Never write "the Legendary tier" again.

## The tour is now the only page

There **was** a Rules page — a reference for somebody landing on it mid-argument
at 40km/h. It was deleted on 13 August 2026 and the tour absorbed it, on the
owner's call. So the tour now does both jobs: it teaches at the gate, and it is
what somebody scans mid-drive. Keep it scannable. Anything that only makes
sense read in order, once, belongs on the first slide or nowhere.

It is replayable from the Wild Score page, which is where somebody is standing
when the argument starts.

## Things that always get said the same way

- **Points measure how difficult an animal is to find, nothing more. Every
  animal in Kruger is equally special.** This appears on the first slide and in
  the rules, and it is not optional — a scoring game about wildlife has to say
  it out loud. It is the one deliberate repetition.
- **Wild Score runs on honesty, just like the paper version.** Nothing is
  checked and nothing needs to be.
- **Watch the animal first — the phone can wait.**
- The app is **Wild Score**, two words. The product line is
  **Wild Score: Kruger Edition**.

## Where the copy lives

| | |
|---|---|
| First-run tour, three slides | `app/lib/features/onboarding/intro_tour.dart` |
| How to play | **the tour** — the Rules screen was deleted on 13 Aug and the tour absorbed it, replayable from the Wild Score page |
| Player-facing rules, in prose | `docs/HOW-TO-PLAY.md` |
| Species About text | `app/assets/data/species.json` — see below |
| Credits and licences | `app/lib/features/profile/licences_screen.dart` |

`**Bold**` works in rule and step bodies and in tour bodies — see
`app/lib/shared/emphasis.dart`. Use it on the **two or three words that carry
the rule**, not on whole sentences. A test fails if an asterisk ever reaches
the screen.

## Before you ship a change to any of it

Read it out loud at the speed somebody reads a phone at a gate. If you run out
of patience before the end, so will they.

## Species About text — how it actually gets written

The mammals were redone at 100 words on 14 August 2026. Everything else — 125
birds, 9 reptiles, 2 invertebrates, the baobab — is still on the older ~50-word
text and reads thinner beside them.

**The method, which took three rounds to settle.** Do not shortcut it; the
owner has said twice that rushing this is what went wrong the first time.

1. Give him the **exact species list** — counted, not estimated, and split into
   batches he can paste into one message.
2. Give him a **prompt** for a second chat that can search the web: 100 words
   maximum, real sources, no invented numbers, what you can see from a car,
   where in Kruger to try, one fact worth reading out loud.
3. He runs it there and pastes the result back.
4. It goes in **verbatim** — with one exception below.

**The exception, and it matters.** Check every factual claim that is cheap to
check, and fix the ones that do not survive it. Tell him which and why; he has
asked for exactly this ("i agree fix the ones you dont agree"). Claims that
came back wrong more than once:

- **White rhino** — the "wyd / wide-mouthed mistranslation" story. Rookmaaker
  (2003) found no written evidence for it. The origin is unknown. Came back
  twice.
- **Waterbuck** — that the oily coat makes predators avoid them. Folklore;
  lions take them regularly. The smell is real, the immunity is not.
- **Bat-eared fox** — placed on the "northern" plains around Satara. Satara is
  central. Came back twice.
- **Caracal** — "single digits per year" sightings. Overstated.

And one the second chat got *right* against our own data: it said Kruger holds
close to 30,000 elephant. Our population card said 20,000, taken from a raw
aerial count. The 2020 sample-based estimate is 31,324 (95% CI 28,457–34,191).
**The card was wrong, not the copy** — it has been corrected. Check both
directions before assuming the pasted text is the thing in error.
