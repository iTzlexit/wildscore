# Wild Score — where everything stands

> Living document. Updated as things move.
> Last updated: 8 August 2026.

`STATE.md` is the technical handover. This is the plan.

---

## Done

**The app**

- [x] Onboarding — three-slide picture tour, then a first name. No account.
- [x] Animal Dex — 96 species, search, filters, rarity sort, full-bleed detail card
- [x] Wild Score — players, claiming, standings, per-player hauls, restart, end day
- [x] Drive history — filters by year and month, pagination, delete
- [x] Latest Sightings — best finds newest first, grouped by trip, with roads
- [x] Profile — lifetime points, seven collections, backup and restore
- [x] GPS road naming — "Leopard · S100", entirely offline
- [x] Rhino and pangolin never get a location, enforced at source
- [x] Backup/restore by pasteable code — no server
- [x] Wild card bonus — first impala/zebra/giraffe/wildebeest pays 50
- [x] Crowd multiplier — alone doubles, jam halves
- [x] Male lion bonus — 100 instead of 40
- [x] App icon, credits and licences screen
- [x] Photo sourcing pipeline — iNaturalist, CC0/CC-BY only, with a contact sheet

**Housekeeping**

- [x] 240 tests, `flutter analyze` clean
- [x] Private GitHub repo, APK builds locally
- [x] All 96 photographs legally cleared (CC0 or CC-BY, irrevocable)

---

## Blocking a store launch

Roughly in the order they need starting.

- [ ] **Google Play developer account** — ~$25 once-off. Nothing else can start
      until this exists.
- [ ] **12 testers × 14 consecutive days** on Play's closed track. **Calendar
      time — cannot be compressed.** Start the day the account exists.
- [ ] **Rarity tiers reviewed.** The whole scoring system rests on numbers
      nobody has checked. The tool is built and ready; what is left is getting
      people to it.

      1. **Host `tools/ranker.html` on Netlify.** Drag the file onto
         `netlify.com/drop` — no account, no CLI, a real URL in ten seconds.
         **Hosting it there is what makes answers collect themselves**: the page
         posts to Netlify Forms, which needs no setup beyond deploying it. Read
         them under Forms → rankings in the Netlify dashboard.
         Free tier is **100 submissions a month**, which is plenty; if it goes
         past that the code on screen still works as a fallback.
      2. Rebuild first with your own contact details so the fallbacks aim at
         you: `dart run tool/build_ranker.dart --whatsapp 27… --email …`
      3. Post the link to Kruger Facebook groups and send it to any guides.
      4. **Aim for 20–30 responses.** Simulated with eight, the extremes sort
         correctly and the middle is visibly noisy. Fewer than twenty is not
         worth acting on.
      5. Paste the codes into a text file, one per line, and run
         `dart run tool/merge_rankings.dart codes.txt`.
- [ ] **Privacy policy URL** — required by both stores even though the app
      collects nothing. Needs somewhere to host it.
- [ ] **Name check** — "Wild Score" against both stores and CIPC. The Android
      `applicationId` is `com.wildscore.wildscore` and is **permanent after
      first publish**.
- [ ] **Store listing** — description, screenshots, 1024×500 feature graphic.
- [ ] **Copy and UX pass** — see `docs/EXTERNAL-REVIEW-PROMPT.md`. In progress.

---

## Worth doing before launch

- [x] **Rules screen rewrite** — settled a different way: the screen was deleted
      on 13 Aug and the tour absorbed it
- [ ] **Better photographs** — ostrich (head down in grass, near useless). The
      caracal and African wildcat were fixed on 13 Aug; the rest of the set is
      worth re-checking against the full-bleed header, which hides nothing.
- [ ] **About text for the other 137 entries** — 125 birds, 9 reptiles, 2
      invertebrates, the baobab. Mammals were redone at 100 words on 14 Aug;
      the method is in `docs/WRITING-STYLE.md` and matters more than it looks.
- [ ] More species — birds especially. The pipeline makes this cheap now.
- [ ] Big Five / Big Six bonuses — designed in `docs/SCORECARD.md`, not built.
      **Not First Call** — that was the wild card, deleted on purpose on 12 Aug.
- [ ] **A carcass as an *extra*** ("on a carcass" on a leopard or lion claim),
      not a species. Kill-in-a-tree came out for exactly this reason.
- [x] House rules screen — shipped as **Wild Score settings**, behind the gear
      on the Wild Score page: Jam Tax and daily limits

---

## To decide

Not started, and each needs a decision before any code.

- [ ] **Company or personal?** CIPC registration vs sole proprietor vs just
      banking it. See `docs/BUSINESS.md`.
- [ ] **Price and paywall.** R250–300 once-off agreed in principle. **Play
      Billing, not Stripe** — decided. What is free vs paid is not.
- [ ] **Promotion** — see below.
- [ ] **Supabase backend.** Agreed in principle. Nothing depends on it yet.
- [ ] **Community sightings map.** A different product with moderation and
      SANParks risk. `docs/MAPS.md`.
- [ ] **Photo verification** and the "pet"/arena idea.
- [ ] **Multiplayer across phones** — blocked by no signal. The camp-sync idea
      is the only version that works.
- [ ] **Leaderboard** — per-car totals uploaded at camp. Needs the backend.
- [ ] **Facebook or social verification.** Long shot, later.

---

## Promotion

### Kruger YouTube channel — first approach

**Status:** not sent.

The plan, in order:

1. **Email one.** Genuine fan letter first, then the app, then a request to
   test it. **No deal mentioned.** See `docs/PROMOTION.md` for the draft.
2. **If they reply and are interested** — send the APK and installation
   instructions.
3. **Ask for feedback specifically on the rarity tiers**, which is the thing
   they are uniquely qualified to judge and the thing most in need of it.
4. **Only if they like it** — talk about a promo code and a share of sales.

**Why that order:** a first email that opens with a business proposal reads as
marketing and gets deleted. A first email that asks a Kruger expert for their
opinion on a Kruger thing is flattering and easy to say yes to. The deal comes
after they have seen it and formed a view.

### Other channels, not started

- [ ] SANParks forums and Kruger Facebook groups — huge, obsessive, and free
- [ ] Camp shops — the offline sale, and the reason a once-off price works
- [ ] Instagram accounts that repost Kruger sightings

---

## Open questions for the next conversation

1. Company structure and how the money is received
2. Promo code mechanics and what percentage is fair
3. What is free vs paid in the app
4. Whether the sightings map is a Phase 2 or a never
