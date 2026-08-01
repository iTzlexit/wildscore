# Design direction

The design system, not a set of screens. Screens change; this should not.

**The governing idea:** [MASTER-VISION.md](../MASTER-VISION.md) says *the photo
is the prize, the frame is the ceremony.* Every rule below serves that. The
interface is a case for photographs — it must never compete with them.

Three consequences that fall straight out of it:

1. **Dark, always.** A dark interface makes photographs glow. A light one makes
   them look like documents. It is also the only sane choice at 5am in a game
   vehicle and at 9pm in a tent.
2. **The interface is desaturated; the photographs are not.** Almost all colour
   in the app is carried by the animals and by rarity. Chrome stays neutral.
3. **Ceremony is earned.** Common animals get a quiet acknowledgement. Legendary
   ones get everything. If everything is decorated, nothing reads as special.

---

## Colour

### Foundation

Near-black with a green cast, so it reads as bushveld rather than as a generic
dark theme. Never pure black — pure black makes photo edges look cut out.

| Role | Hex | Use |
|---|---|---|
| `background` | `#0D1110` | App background |
| `surface` | `#161B18` | Cards, fields, sheets |
| `surfaceRaised` | `#1E2521` | Chips, icon tiles, anything sitting on a card |
| `outline` | `#2E3833` | Hairlines, unselected borders |
| `outlineStrong` | `#3F4A44` | Dividers that need to be seen |

### Text

Warm off-white, never `#FFFFFF`. Pure white on near-black is harsh and reads as
cheap.

| Role | Hex | Use |
|---|---|---|
| `textPrimary` | `#F1EFE8` | Names, headings, numbers |
| `textSecondary` | `#A6AFA2` | Body, descriptions |
| `textMuted` | `#6E7A70` | Labels, captions, dex numbers |

### Accent and status

| Role | Hex | Use |
|---|---|---|
| `accent` | `#DCA84A` | Brass. The single interface accent — buttons, active states, the score |
| `accentInk` | `#14100A` | Text on accent |
| `verified` | `#5FA96B` | Verification ticks, caught counts |
| `danger` | `#E0736B` | Protected-species notices, errors |

**One accent only.** Brass reads as warm, slightly aged, and it is the colour of
late afternoon light in the bushveld. Adding a second accent is how dark themes
start to look like dashboards.

---

## Rarity — the most important visual decision in the app

> A Legendary card must not be mistakable for a Common one across a room.

Colour alone cannot do this. Roughly 8% of men have some colour vision
deficiency, and a lot of use happens in direct sun where hue washes out. So
rarity escalates across **five redundant channels at once**:

| Tier | Hex | Border | Wash | Glow | Frame | Motion |
|---|---|---|---|---|---|---|
| Common | `#8A8F86` stone | 1.0 | — | — | plain | — |
| Frequent | `#5FA96B` green | 1.0 | faint | — | plain | — |
| Notable | `#4A93C7` blue | 1.4 | light | — | plain | — |
| Rare | `#8B72D6` violet | 1.6 | medium | — | notched corners | — |
| Very rare | `#E08238` amber | 2.0 | medium | soft | notched corners | — |
| Exceptional | `#E0503A` crimson | 2.2 | strong | medium | notched + inner rule | static foil sheen |
| Legendary | `#E8C15A` gold | 2.6 | strong | strong | double frame + corner ornament | animated foil sweep |

**Common is deliberately hueless.** Stone grey says "this is not the interesting
one" more clearly than any colour could, and it makes everything above it read as
a step up.

The escalation is also *ordered by temperature* — neutral, green, blue, violet,
amber, crimson, gold — so the sequence reads correctly even in greyscale, because
perceived lightness rises with it.

**Animated motion appears at exactly one tier.** Legendary is the only tier that
moves in a list. Eighteen shimmering cards in a scrolling grid is noise; one is an
event.

---

## Typography

Two families, no more.

**Display — [Fraunces](https://fonts.google.com/specimen/Fraunces)**, variable
serif. Species names, screen titles, the score. It is warm and slightly
editorial, which is what makes the app read as *field guide* rather than *app*.
Use the `SOFT` axis low and `WONK` off — characterful, not novelty.

**Interface — [Inter](https://fonts.google.com/specimen/Inter)**. Everything
else: body, labels, buttons, numbers in tight spaces. Exceptional legibility at
small sizes and in bright light, which is the actual reading condition here.

Both are SIL Open Font Licence — free to bundle commercially.

**They must be bundled, not fetched.** Do not use the `google_fonts` package: it
downloads at runtime, and this app has no network for days at a time.

### Type scale

A 1.25 ratio, rounded to whole numbers.

| Token | Size / line | Family | Weight | Use |
|---|---|---|---|---|
| `display` | 46 / 46 | Fraunces | 700 | The daily score, reveal numbers |
| `title1` | 30 / 34 | Fraunces | 700 | Screen titles, species name on detail |
| `title2` | 22 / 26 | Fraunces | 600 | Section headings, card names |
| `body` | 15 / 22 | Inter | 400 | Descriptions, field notes |
| `bodyStrong` | 15 / 22 | Inter | 600 | Values in info rows |
| `label` | 13 / 16 | Inter | 500 | Buttons, chips, tabs |
| `caption` | 11 / 14 | Inter | 500 | Dex numbers, dates, credits |
| `overline` | 10 / 12 | Inter | 800, +1.6 tracking | `FIELD NOTES`, `LIFETIME POINTS` |

**Numbers use Inter with tabular figures** wherever they change — a score
counting up must not jitter as digit widths shift.

---

## Card anatomy

One card component, three states. The frame is identical in all three; only the
face and the metadata change. That is what makes the upgrade feel like the same
object improving rather than a different object appearing.

```
┌─────────────────────┐
│                     │  ← face: 4:5, fills the tile
│        FACE         │
│                     │
│ ▸ points   ▸ badge  │  ← overlays, top corners
├─────────────────────┤
│ No. 025             │  ← caption, textMuted
│ Ground Pangolin     │  ← title2
└─────────────────────┘
```

### Undiscovered

- Face: the reference photo desaturated and crushed to ~15% brightness, with a
  centred `?`
- Frame: `outline` at 1.0 regardless of tier — **rarity is not revealed before
  discovery.** Showing a gold frame on an animal you have never seen gives away
  the surprise and flattens the reveal
- Caption: dex number only. **No name, no points**
- The empty slots are the motivation. Seventy-one of them staring back is the
  product

### Logged — Quick Log, no photo

- Face: stock reference photograph, full colour
- Frame: full tier treatment
- Caption: dex number, name, points
- **A hollow ring in the top-right**, not a tick. It reads as "there is a level
  above this", which is exactly the intent — a logged card should feel slightly
  unfinished

### Verified — your photograph

- Face: **the player's own photograph**, permanently replacing the stock image
- Frame: full tier treatment
- A **filled tick** in `verified` green, plus the date
- Quiet Sighting mark if earned

The difference between logged and verified must be legible at thumbnail size,
because the whole Codex is a grid of thumbnails. Hollow ring versus filled tick
does that; a subtle border change would not.

---

## Motion

Motion is either invisible or ceremonial. Nothing in between.

### Interface motion — invisible

| Interaction | Duration | Curve |
|---|---|---|
| Tap feedback (card press) | 110ms | `easeOut`, scale 0.96 |
| Screen transition | 260ms | `easeOutCubic` |
| Filter / chip state | 180ms | `easeOut` |
| Sheet, dialog | 240ms | `easeOutCubic` |

Nothing here bounces. `easeOutBack` on a filter chip is a toy.

### The reveal — ceremonial, and scaled by rarity

Same five stages for every species. Only duration and intensity change.

1. **Hold** — the silhouette, one beat longer than feels comfortable
2. **Bloom** — colour floods in from the centre
3. **Frame** — the tier border draws itself, corners last
4. **Data** — name and dex number write in
5. **Count** — points tick up, `accent`, tabular figures

| Tier | Total | Extras |
|---|---|---|
| Common | 600ms | — |
| Frequent | 700ms | — |
| Notable | 1000ms | Haptic on bloom |
| Rare | 1300ms | Haptic, sound |
| Very rare | 1700ms | Glow pulse on frame |
| Exceptional | 2100ms | Foil sweep, screen dims behind |
| Legendary | 2800ms | Everything, plus a held beat before the count |

**The hold before the bloom is what makes it work.** Anticipation is the entire
mechanism — a reveal that starts immediately is just a transition. A pangolin
should make someone in the passenger seat lean over before they know why.

`easeOutBack` is correct here and only here.

---

## Spacing and elevation

**4pt base grid.** Permitted values: 4, 8, 12, 16, 20, 24, 32, 40, 56.

| Context | Value |
|---|---|
| Screen horizontal margin | 20 |
| Between cards in a grid | 12 |
| Card internal padding | 12 |
| Between a label and its value | 4 |
| Between sections | 28 |

**Corner radii:** 8 for chips and small controls, 14 for cards, 20 for sheets.
Nothing is a perfect circle except avatars and the camera button.

### Elevation: borders and glow, not shadows

Drop shadows do not read on a near-black background — they are invisible or they
look like dirt. Depth comes from:

1. **Surface lightness** — `background` → `surface` → `surfaceRaised`
2. **A hairline border** in `outline`
3. **Glow**, and only for Very rare and above, and only as a rarity signal

Glow is never decoration. If it appears anywhere that is not conveying rarity,
it is wrong.

---

## References that would help most

Drop these in `docs/references/` and I will work against them directly. In
priority order:

1. **Pokémon GO catch/reveal sequence** — a screen recording rather than
   stills, or 4–5 frames covering anticipation → burst → settle. The *timing* is
   what I need; I can read pacing from frames but a recording is far better.
2. **Two or three premium trading-card apps** — how a rare card frame differs
   from a common one. Foil, borders, corner treatments. This is the single
   hardest thing to get right from description alone.
3. **A physical field guide page** you rate — Sasol or Roberts. Photograph a
   spread. It tells me how much information density feels *authoritative* rather
   than cluttered, which is a judgement I cannot make without seeing what you
   consider good.
4. **Any app whose dark theme you like**, for any reason. Even unrelated to
   wildlife.
5. **Your own Kruger photographs**, if you have them — knowing what the real
   subject matter looks like against these colours matters more than any
   reference app.

For 1 and 2 especially, screenshots beat description. "Premium" and
"collectible" mean different things to different people and I would rather match
yours than guess.
