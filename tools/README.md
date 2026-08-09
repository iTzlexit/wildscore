# tools/

Content tools. Not part of the app build.

## ranker.html

**Ask people how hard each animal is to find, and collect the answers.**

The point values in the app only work if the tier assignments are right, and the
people who actually know are the people who drive the park. This is the page to
put in front of them.

Open it locally to do your own pass:

```bash
start tools/ranker.html
```

Choices save to `localStorage` as you go, so you can close the tab and come
back. **Done — send** exports only what you changed, along with an optional name
and how well the person knows Kruger.

### Sharing it with a Facebook group

The file needs to be *hosted* before it can be a link. Two decisions:

**1. Where it lives.** Any static host works — it is one file with no backend.

- **Netlify Drop** (<https://app.netlify.com/drop>) — drag the file onto the
  page, get a URL in about ten seconds. No account needed to start.
- **GitHub Pages** — free, but this repo is private, so it needs a separate
  public repo. More steps, more permanent.
- **Cloudflare Pages** — same idea, and it is already the plan for photo
  storage later.

Netlify Drop is the right answer for a first run.

**2. Where the answers go.** Set `ENDPOINT` at the top of the `<script>` block.

- Leave it **empty** and the page falls back to *copy* plus a `mailto:` link.
  Zero setup, but it depends on the person having email configured on the device
  they are browsing on, and a meaningful number will not.
- Set it to a **form endpoint** and submissions arrive on their own:
  - [Formspree](https://formspree.io) — 50 submissions/month free, emails you
    each one. Easiest.
  - [Web3Forms](https://web3forms.com) — free, higher limit, also emails.
  - [Basin](https://usebasin.com) — similar.

Either way the payload is JSON, so it can be pasted straight back into a chat
for analysis.

### What to expect from the data

- **Weight by experience.** "Many trips over many years" is worth more than "a
  few trips", which is why the page asks. Someone on their first visit has no
  basis to rank a caracal.
- **Expect partial responses.** The page says out loud that changing five is
  useful, because a form that demands all 74 gets abandoned at 74.
- **Watch for the excitement bias.** People rank leopard as harder than it is
  because it is thrilling, and rank nocturnal species as easier than they are
  because they have only ever done day drives. Both are correctable once the
  spread is visible across enough responses.
- **Twenty responses is enough** to move something confidently. Five is not.

### A note on collecting from strangers

No email address, no login, nothing that identifies a person beyond a name they
type themselves — and the name is optional. Keep it that way; there is no reason
this needs anything more, and anything more turns a two-minute favour into a
privacy question.

## photo-picker.html

**Choose the tile photo for the four Small Five species.**

They are the only four in the catalogue whose photo was picked by a machine
rather than by eye, and it shows: the auto-pick for Ant Lion is the adult
insect, which almost nobody recognises. The pit in the sand is what people
actually see.

Candidates are pulled from iNaturalist and filtered to **CC0 and CC-BY only** —
the default licence on open image platforms is usually non-commercial, which is
illegal in a paid app. See `docs/IMAGE-ASSETS.md`.

```bash
start tools/photo-picker.html
```

Click one per species, **Export**, paste the JSON back into the chat. The
download, downscale and attribution update all run from there.

## prepare_species_photos.dart

See `app/tool/`. Downscales sourced photographs into `assets/species/`.

## photo-picker.html

**Choose the photograph for every species yourself.**

Regenerate it whenever the catalogue changes — the candidates are baked in, so
it goes stale the moment a species is added:

```bash
cd app && dart run tool/source_species_photos.dart --picker
```

That fetches eight CC0/CC-BY options per species from iNaturalist and writes
both `photo-candidates.json` and `photo-picker.html`. **Metadata only** — no
images are downloaded, the page loads them from iNaturalist, so the whole
catalogue takes about three minutes.

Open it over HTTP rather than `file://`, so the "in the app" thumbnails resolve:

```bash
cd app && dart run tool/serve_web.dart --root .. 8099
```

Then <http://localhost:8099/tools/photo-picker.html>.

Thumbnails are iNaturalist's 240px variant, so the page needs a connection but
not much of one. A pick still stores the full-size URL — that is what gets
downloaded and shipped.

Each species shows what is **in the app now** first, then the alternatives.
Click one to change it; click it again to go back to leaving it alone. Picks
save to `localStorage`, so you can close the tab. **Export** gives a JSON blob
of only what you changed.

To apply it:

```bash
cd app && dart run tool/apply_photo_picks.dart picks.json --dry-run
cd app && dart run tool/apply_photo_picks.dart picks.json
```

It downloads each chosen photograph, downscales it to the same 800px/q72 as the
rest, and rewrites that species' credit. Species you did not pick are untouched.
It refuses the whole batch — writing nothing — if any pick carries a licence
that may not ship, names no photographer, or points at a species that is not in
the catalogue.

**Ant Lion has no candidates.** Its "scientific name" is a family
(Myrmeleontidae) rather than a species, so the search returns nothing. It keeps
the photograph that was picked by hand for the Small Five.
