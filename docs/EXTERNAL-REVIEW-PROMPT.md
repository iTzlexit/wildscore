# Copy & UX review brief

Paste everything between the lines into ChatGPT, then attach screenshots.

The important part is the **output format**. It asks for changes as
`file → exact old string → exact new string`, which is what makes the fixes
mechanical to apply. Prose feedback like "the tone could be warmer" costs a
round of guessing; an exact replacement does not.

Re-usable — run it again whenever the copy drifts.

---

You are a senior product designer and copywriter. Your specialisms are onboarding
copy, information hierarchy on small screens, and cutting word count without
losing warmth. I am going to show you a mobile app and ask for a hard,
specific critique.

## The product

**Wild Score** — a field guide and scorecard game for Kruger National Park,
South Africa. Android and iOS, built in Flutter. Not launched yet.

**What it is.** Kruger is a 20,000 km² game reserve. People drive through it for
days looking for animals. Families have played a paper version of this game for
generations: everyone in the car competes to spot animals first, rarer animals
are worth more points. Wild Score is that game, plus a permanent record of every
animal you have ever seen.

**Who it is for.** South African families on a Kruger trip, mostly with kids in
the back seat, mostly people who have been going for years. Also first-timers who
do not yet know a kudu from a nyala. It is not for serious birders — there are
better apps for that.

**The positioning.** Species checklist apps exist and are commodity. A scorecard
that a family argues over does not exist. **The game is the differentiator; the
collection is why anyone still has the app in March.**

**Hard constraints that shape everything:**

- **There is no cell signal in most of Kruger.** The app makes zero network
  calls. Everything — 96 species, all photographs, the road network — is bundled
  in the install.
- **No accounts, no login, no email, no password.** You type a first name and
  you are playing. Data lives only on the phone.
- **No ads.** Planned as a once-off purchase of about R250–300 (~$14) on the
  Play Store. Currently free.
- One phone per car. One person keeps score for everyone. Multiplayer across
  phones is not possible without signal.

**How the game works:**

- Every animal sits in one of six rarity tiers: Common 5, Frequent 15, Notable
  40, Rare 100, Very rare 300, Legendary 2,000 points.
- Rarity means **how hard it is to find in Kruger**, not how impressive it is. A
  pangolin beats an elephant because the elephant is standing in the road.
- You add everyone in the car by first name. When somebody shouts, you tap an
  eye icon next to their name and pick the animal. The points go to them.
- For notable animals the app asks who else was there: **found it alone = double
  points, arrived at a traffic jam of parked cars = half**. A male lion is worth
  more than a lioness.
- At the end of the day you end the drive. Points bank into a lifetime total and
  every animal the car saw joins the phone owner's permanent collection.

**Four tabs:** Profile (lifetime points, collections), Wild Score (the game and
drive history), Animal Dex (the 96-species field guide), Sightings (your best
finds, newest first, with the road each happened on).

**The tone I am going for:** warm, dry, South African. Like a friend explaining
a family game, not a manual. Confident and a bit funny. Never corporate, never
try-hard, never "Embark on your wildlife journey!".

## What I want from you

I will paste screenshots of individual screens. For **each screen**, tell me:

1. **What a first-time user understands in three seconds.** Be blunt if the
   answer is "nothing".
2. **Where the wording is doing badly** — vague, too long, too clever, missing
   the point, or explaining something nobody asked.
3. **What to cut.** I think several screens have too much text. Say which
   sentences earn their place and which do not.
4. **What is missing** — the question a real user would have that the screen
   does not answer.
5. **Hierarchy problems** — wrong thing biggest, important thing buried.

Then give me **rewritten copy**.

## Output format — this matters

My developer applies your changes directly to the source. Give every copy change
in this exact form:

```
FILE: <the file I told you the screen lives in>
FIND: <the exact current string, copied character for character from what I gave you>
REPLACE: <your new string>
WHY: <one line>
```

Rules for this:

- **Never paraphrase the FIND string.** It must match the source exactly or the
  change cannot be applied automatically.
- One block per change. Do not bundle several edits into one block.
- If a sentence should simply be deleted, put `REPLACE:` and leave it empty.
- If you are proposing something structural (move this section, split this
  screen, add a new element) do **not** use the block format — write it under a
  heading `STRUCTURAL:` and describe it in plain prose, because that needs a
  decision before it needs code.

Group your response as:

1. **Verdict** — three sentences on the app's copy overall.
2. **Per screen** — the five points above, then the replacement blocks.
3. **STRUCTURAL** — anything that is not a string swap.
4. **Top five** — if I only do five things, which five.

## Also give me an opinion on these, separately

**The intro tour.** Three slides shown on first launch. Slide 1: an illustrated
game-drive vehicle on a dirt road with animal faces in the seats — "The best
game in Kruger is played from the back seat". Slide 2: a mock scoreboard plus
the full rarity table — "Spot it, tap it, take the points". Slide 3: a gold
rosette — "End the day. Crown the Ultimate Spotter."

Tell me whether three slides is right, whether those are the right three ideas,
and what the illustrations should show instead if they are wrong. The
illustrations are drawn in code, so "a photo of a real family" is not available
to me — but any drawable scene is.

**The rules screen.** Full current text below. It is the screen I am least happy
with. I want it scannable, obviously ordered, and short enough that somebody
actually reads it at a park gate with the engine running.

---

RULES SCREEN — CURRENT TEXT
File: `app/lib/features/scorecard/rules_screen.dart`

Screen title: How to play

Intro: "A game for long drives in the park. Find out who is actually any good at spotting."

Button: "Show me the quick tour"

SECTION: HOW IT IS PLAYED
1. Enter the players — "Everyone in the car who wants to play. First names only — no accounts, no sign-ups. On your own works too."
2. Every animal has a scarcity level — "From Common up to Legendary, based on how hard it is to find in Kruger. An impala is 5 points. A pangolin is 2,000."
3. Points go to whoever spots it first — "Tap the eye beside their name, then tap the animal. Tap the animal again later to take it back off them."
4. Tally up at the end of the drive — "Highest score takes the bragging rights. Tomorrow everyone starts level again."

SECTION: OR DO NOT PLAY AT ALL
Just keep a list — "Tick animals off in the Animal Dex as you find them. No game, no scores, nobody keeping count — your collection fills up all the same."

SECTION: THE RULES
- Inside the park only — "The gate is the line. That kudu on the way in was lovely, and it does not count."
- One sighting, one claim — "Reverse back for another look by all means. It is still the same leopard."
- A pride is one lion — "Twelve lions at a kill is one claim, not twelve. Sorry."
- No asking at a jam — "Cars stopped ahead means something good. No winding down a window to ask what it is. Find it yourself — that is the fun."
- Finding it yourself is worth double — "For anything Rare and up, and for the Big Five, the app asks who else was there. An empty road pays double. Rolling up to eleven parked cars pays half — it still counts, you did see it, but somebody else found it."
- A male lion is worth more — "A lioness is a lion. A black-maned male standing in the road is the picture on the front of the brochure, and it pays 100 instead of 40."
- The first one is worth more — "Impala, zebra, giraffe and wildebeest pay 50 for the first sighting instead of 5. After that they are worth what they have always been worth. The impala bonus comes once a trip; the others reset every morning."
- The common ones run out — "Impala and friends: once a day. Middling ones: three times. Anything rare stays open all day — every leopard counts."

SPIRIT OF THE GAME (a highlighted box)
Title: "It is a game, and only a game"
Body: "Every animal out there is worth the same. The points only measure how hard something is to find — a pangolin beats an elephant because the elephant is standing in the road.

Nothing is checked or verified. It runs on trust, same as the paper version. Watch the animal first; the phone can wait."

SECTION: WHAT EVERYTHING IS WORTH
(a table of the six tiers and their point values)
Footnote: "Not how impressive an animal is — how hard it is to find. Sweep up every common animal in the park in one day and a single pangolin still beats the lot of you."

---

Wait for my screenshots before reviewing the individual screens. You can react to
the rules screen text immediately, since I have given it to you in full.
