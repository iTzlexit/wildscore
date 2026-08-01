# ARCHIVED — the original plan

> This is the `00-START-HERE.md` written before any code existed. It was never
> saved to disk; the `KrugerPoke` folder was empty when work began, so the first
> two days of building happened without it.
>
> **It is kept for the record and for the ideas in it that are still good.**
> Where it conflicts with the live docs, see
> [DIVERGENCES.md](../DIVERGENCES.md) for what changed and why.
>
> It also references `SPEC.md` and `VERIFICATION-AND-PROGRESSION.md` from that
> session. **Those two files have never been seen** — if they still exist
> anywhere, they contain product decisions (the original rarity table, the trust
> model, Species Crowns, ranks) that are otherwise lost.

---

## What changed and why

SPEC.md was written assuming .NET MAUI, on the reasoning that you already write
C# daily. That reasoning was wrong once I learned you've never built a mobile
app.

**Revised recommendation: Flutter.**

- You have to learn mobile development regardless — app lifecycle, permission
  models, platform differences, store submission. Language is a small fraction
  of that curve.
- Dart is easy coming from C#. Same async/await, same class model, similar
  syntax, strong typing.
- MAUI's three weakest areas are precisely this app's three hardest problems:
  **camera control, offline maps, on-device ML.**
- The Pokémon feeling you're chasing lives entirely in animation and polish.

**Your backend stays .NET.**

## Naming

`KrugerPoke` is fine as a local folder. It is not fine as a product name.
Nintendo defends the Pokémon trademark aggressively.

Directions: **Wild Score**, **Spotted**, **Bushveld**, **Sighted**,
**The Big List**, **Trackside**.

## The tech stack (as originally proposed)

| Concern | Package |
|---|---|
| State management | Riverpod |
| Local database | Drift |
| Camera | `camera` |
| Location | `geolocator` |
| Background tracking | `flutter_background_geolocation` or `workmanager` |
| Offline maps | `flutter_map` + `flutter_map_tile_caching` |
| Sensors | `sensors_plus` — gyroscope trace for the 360° pan |
| In-app purchase | RevenueCat |
| HTTP | `dio` |
| Image handling | `image` |
| Animation | Flutter built-ins, `rive` |

Backend: ASP.NET Core 9, PostgreSQL + EF Core, ASP.NET Identity + JWT,
Cloudflare R2 for photos, Render or Azure App Service, Claude vision for AI
verification, RevenueCat webhooks.

## The iOS problem

Cannot build iOS from Windows. Options: Codemagic/Bitrise cloud macOS
(recommended), a used M1 Mac Mini (~R8–12k), or ship Android first.

## Store accounts

- Apple Developer Program $99/year. **Register for the Small Business
  Program** — 30% to 15%.
- Google Play Console $25 once. **12 testers, 14 consecutive days** before
  public release.

### Things that get apps rejected

- Background location without clear justification
- Missing restore-purchases
- Broken or missing privacy policy URL
- Incomplete App Privacy declarations
- Crashes on the reviewer's device
- Placeholder content

## Monetisation

**Season Pass — R249/year, non-renewing.** Not auto-renewing: a once-a-year
activity generates cancellations and resentment. Aligns with the crown reset.

Unlocks: permanent collection, crown and leaderboard eligibility, shareable
scorecards, Quiet Sighting bonus mode, badges.

Free forever: camera capture, species logging, live score, trip summary.

Later: **Vehicle Pass R499** (5 players on one trip), park unlocks
(Pilanesberg, Addo, Etosha), cosmetics, physical end-of-season print.

Net at 15%: R249 → R212. R10k/month ≈ 570 passes/year.

## Holding onto the Pokémon feeling

1. **The reveal moment** — animation, sound, a card that flips, the score
   climbing.
2. **The visible gap** — silhouettes of unfound species.
3. **Rarity that's legible** — distinct colour, frame, animation per tier.
4. **Effortless showing off** — one tap to a shareable image.

Two of these — the reveal and the share card — should be built early, in
Phase 1.

## Original domain concepts

Species, Trip, TrackPoint, Sighting, **PanCapture**, CollectionEntry.
RarityTier and **LocationPrecision** enums. A **ScoringService** with a
**Quiet Sighting multiplier**. A **LocationPrivacyService** coarsening
sensitive species to a ~25km grid, implemented on both client and server.

## Original next steps

1. Save the three markdown files
2. `git init`
3. Install Flutter, Android Studio, VS Code; `flutter doctor`
4. Run Prompt 0
5. **In parallel, start Phase 0 validation.** Post the concept in Kruger
   Facebook groups this week.
6. Recruit 12 Google Play testers early.
