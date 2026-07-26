# Tech Stack

Principle: **add a dependency only when the phase that needs it arrives.** Every
package is a version-conflict risk and a thing to learn. The list below is
deliberately short.

---

## Client — Flutter (Dart)

Chosen over .NET MAUI despite your C# background, because:

- You have to learn mobile either way. Lifecycle, permissions, store submission
  and platform quirks are ~85% of the curve; the language is the rest. Dart is
  trivially learnable from C# — same `async`/`await`, same class model.
- The three hardest parts of this app are **camera control**, **offline maps**
  and **on-device ML**. Flutter is strong at all three; MAUI is weak at all three.
- The product lives or dies on the reveal moment feeling good. Flutter's animation
  system is far ahead of MAUI's, and that is not a cosmetic concern here.

**Dart for C# developers:** <https://dart.dev/resources/coming-from/csharp-to-dart>

## Phase 1 — no packages at all

| Need | What we use |
|---|---|
| Navigation (2 screens) | `Navigator.push` |
| State (search + filters, one screen) | `StatefulWidget` + `setState` |
| Data (71 species, read-only) | JSON asset via `rootBundle` |
| Images | `Image.asset` |

`go_router`, `riverpod`, `drift` and `cached_network_image` all appear in Phase 2+
below, when there is genuine cross-screen state and real persistence. Reaching for
them now buys nothing and costs you a week of package troubleshooting.

## Phase 2+ — added as needed

Versions below are what was current on 2026-07-26. Re-check before adding one —
`flutter pub add <name>` picks the latest automatically.

| Phase | Package | Version then | Why |
|---|---|---|---|
| 2 | `camera` | 0.12.0+2 | In-app capture. **Not** `image_picker` — that can be pointed at the gallery, which destroys the verification story. |
| 2 | `sqflite` | 2.4.3 | Local sightings store. SQL you already know. Drift only if the queries get complex. |
| 2 | `path_provider` | 2.1.6 | Where to write captured photos on disk. |
| 2 | `flutter_riverpod` | **3.3.2** | See the warning below before reading any tutorial. |
| 2 | `go_router` | 17.3.0 | Bottom navigation and deep links into a shared sighting. |
| 3 | `geolocator` | 14.0.3 | GPS fix at capture time — the primary verification signal. |
| 3 | `flutter_map` + `mbtiles` | 8.3.1 | Offline park map. There is no cell signal in most of Kruger; this is non-negotiable. |
| 4 | `supabase_flutter` | 2.16.0 | Backend — see below. |
| 5 | `purchases_flutter` (RevenueCat) | 10.4.3 | Store payments. |
| 6 | `google_mlkit_image_labeling` or TFLite | — | On-device species suggestion. Last, not first. |

> **Riverpod is on 3.x, and almost every tutorial and Stack Overflow answer you
> will find is written for 2.x.** The API changed substantially — `StateNotifier`
> and `StateNotifierProvider` gave way to `Notifier`/`NotifierProvider`, and much
> of the old code does not compile. When you get to Phase 2, read the official
> migration guide first and treat any blog post older than 2025 as wrong. This is
> a good example of why nothing was added in Phase 1: a dependency picked early
> is a dependency whose API churns under you before you need it.

## Backend — Supabase, not ASP.NET Core

This reverses the earlier plan, and it is the single biggest "easiest yet most
effective" decision in the project.

Supabase gives you, on day one and with no server to operate: **Postgres**, auth,
object storage for photos, row-level security, and a good Flutter SDK. Building
the same thing in ASP.NET Core means you also own hosting, migrations, an identity
system, a blob store, a CDN and a deployment pipeline — weeks of work that adds
nothing a user can see.

Your four years of backend experience is not wasted; it is exactly what lets you
use Supabase properly instead of badly. You will write SQL, design the schema, and
write RLS policies — that *is* backend work.

The escape hatch matters: Supabase **is** Postgres. If you outgrow it, you put
ASP.NET Core in front of the same database and migrate incrementally. Nothing is
one-way.

Leaderboard scoring and anti-cheat run as **Supabase Edge Functions** (TypeScript)
or as Postgres functions. Never trust a score the client calculated.

## Payments — RevenueCat

Apple StoreKit and Google Play Billing are two entirely different APIs with two
entirely different receipt-validation flows, and receipt validation is where
homegrown IAP quietly leaks money. RevenueCat wraps both, is free under
~$2.5k/month revenue, and handles the **non-renewing annual pass** you want.

**Sell a "2026 Season Pass", not an auto-renewing subscription.** For a park most
people visit once a year, a subscription generates cancellations and resentment —
nobody wants to pay monthly for a park they see in July. A season pass reads
completely differently and lines it up with the annual leaderboard reset: seasons
end, standings turn over, buying in again is a willing act.

## Not doing (and why)

- **Firebase** — pulls you into Google's ecosystem, and its query model fights the
  relational leaderboard/season data you actually have.
- **On-device ML in v1** — a species classifier trained well enough to be
  trustworthy is a project in itself. v1 verification is camera-only capture +
  GPS inside park boundaries + timestamp. That is already stronger than paper.
- **A custom backend before there are users** — see above.
