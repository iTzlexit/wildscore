# Accounts and sign-in

> Phase 4 work. Written now because the migration path has to be designed before
> the first account exists, not after.

## The rule

**The app never requires an account.** Not to install it, not to open it, not to
play, not to keep a collection for five years.

An account is offered at exactly one kind of moment: when the player wants
something a single phone cannot do.

- Get their collection back after losing the phone
- See it on a second device
- Appear on the leaderboard
- Post to the sightings feed

That is the whole list, and every item on it needs a server. Which is also, not
coincidentally, the paid line — see [MONETISATION.md](MONETISATION.md).

## Why no account at the gate

The onboarding is a name and a tap, and it should stay that way. A family at
Numbi at 05:30 with one bar of signal will not create an account, verify an
email, and choose a password. They will put the phone down.

Every account screen shown before the player has anything to protect is a
screen that loses people who would have loved the app.

## What we support

| Method | Why |
|---|---|
| **Sign in with Google** | Most South African Android users are already signed in. One tap, no typing. |
| **Sign in with Apple** | **Mandatory on iOS** the moment any other third-party sign-in is offered — App Store Review Guideline 4.8. Not optional, and it is a common rejection. |
| **Email magic link** | For everyone else. A six-digit code or a link; no password to invent, forget or leak. |

All three are built into Supabase Auth, which is the planned backend.

### Not email and password

Deliberately excluded. Passwords mean a reset flow, a support burden, and
credential storage that becomes a liability the day it leaks — for an app whose
most sensitive data is *where a rhino was standing*. They also convert worse
than every option above.

## The migration is the hard part

Everything currently lives in `shared_preferences` on one phone: the profile,
the spotted set, the drive history. When someone signs in for the first time,
**that local data is the truth**.

> **Sign-in uploads. It never downloads over the top.**

Get this backwards and the first thing an account does is delete five years of
sightings, which is the worst bug this product could ship.

The order:

1. Create the account
2. Upload the local profile, spotted set and every visit
3. Only then start syncing normally

Signing in on a *second* device is the case where a merge is genuinely needed:
union the spotted sets, union the visits by `endedAt`, keep the earliest
profile. Never delete a local record because the server has not seen it.

Worth deciding before writing any of it: what happens when someone signs into an
account that already has data from a different phone. Union is almost always
right; "last write wins" quietly eats collections.

## Privacy, briefly

- **POPIA applies.** A privacy policy is required by both stores anyway; it needs
  to say what is collected and why, and it needs to be a real URL before the
  first submission.
- Collect the minimum: a name, an email, the sightings. No contacts, no
  precise location history, no advertising identifiers.
- **Sensitive species locations never leave the device**, account or not. See
  [SIGHTINGS-FEED.md](SIGHTINGS-FEED.md). An account changes nothing about that.
- Account deletion must be reachable **inside the app** — Google Play has
  required this since 2023, and it must actually delete rather than deactivate.

## What this means for the build

Nothing changes in Phase 1–3. The app stays local, which is why it works with no
signal for a week.

When Phase 4 lands, the sign-in screen is a *destination the player chose to
visit*, reached from a "Back up my collection" row on the profile. It is never a
gate, never a modal on launch, and never the first thing anybody sees.
