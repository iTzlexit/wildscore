# Testing Phase 2 — camera, GPS and a park you cannot visit

## The problem

Phase 1 was easy to test: a JSON file and two screens, all of it reachable from
`flutter test`. Phase 2 is not, and it is worth being honest about why.

The core loop needs a **camera**, a **GPS fix**, and **being inside Kruger**.
None of those exist at your desk. And the real test — four days in the park with
a phone in a hot car and no signal — is something you get to do maybe twice a
year. You cannot iterate against it.

So the strategy is: **make almost everything testable from your desk, and treat
the field trip as a rare, expensive audit that you plan for.**

---

## Layer 1 — Pure logic (most of your coverage)

Everything that is not a camera or a sensor should be a plain Dart test, exactly
like the 58 you already have.

- Scoring: base points, night multiplier, repeat sightings at 10%, First Find
- Whether a GPS coordinate is inside the park boundary
- Sighting clustering — feed it fixed timestamps and coordinates, assert who
  gets the First Find
- Sightings database: insert, query by species, count distinct species
- Sync queue: what happens when the same sighting is uploaded twice

These are fast, deterministic and where bugs actually live. **Scoring in
particular must be exhaustively tested** — it is the number people compete over,
and a scoring bug discovered after a season has started cannot be quietly fixed.

## Layer 2 — Fake the hardware

This is the decision that makes Phase 2 tractable, and it must be made **before**
the camera code is written, not after.

Put the camera and GPS behind interfaces, and provide fakes:

```dart
abstract class CaptureSource {
  Future<CapturedPhoto> capture();
}

abstract class LocationSource {
  Future<Position> currentPosition();
}
```

Real implementations wrap `camera` and `geolocator`. Fakes return a bundled test
image and a coordinate you choose. Then the **entire loop** — shutter, save,
species picker, reveal, score, collection update — runs in a widget test with no
hardware at all.

This is the same pattern that already rescued the Codex tests: `CodexScreen`
takes its repository as a constructor parameter, so tests supply an in-memory
one. It is ordinary constructor injection and you know it well from ASP.NET
Core. Apply it to hardware and Phase 2 stops being frightening.

### A debug-only simulator screen

Ship a dev-mode screen in debug builds only:

- Pick any species
- Pick a coordinate from a preset list (Skukuza, Satara, Pafuri, *outside the
  park*)
- Pick a time of day, to exercise the night multiplier
- Fire a simulated capture

You can then run the whole game from an emulator, including the reveal, in
seconds. Guard it with `kDebugMode` so it can never appear in a release build.

## Layer 3 — On a real device, from your desk

Some things need real hardware but not a real park.

**Mock the GPS.** On the emulator, use the location controls in the extended
menu, or from a terminal:

```bash
adb emu geo fix 31.5967 -24.9947
```

That is Skukuza. On a physical phone: Developer options → *Select mock location
app*, with a mock provider app installed.

**Test camera permission states properly** — granted, denied, permanently
denied. The last one is the nasty case: you cannot re-prompt, you have to send
the user to system settings. It is also the one nobody tests, and the one that
generates one-star reviews.

**Test offline properly.** Aeroplane mode, then use the app for an hour. Log
sightings, close the app, reopen it, log more. Then reconnect and confirm
everything syncs exactly once.

**Test on a cheap phone.** Not your own. An entry-level Android with 3 GB of RAM
is what most of your users have, and camera preview plus a big list is exactly
where those devices fall over.

## Layer 4 — The field trip

You get few of these. Plan them like a release.

**Before you go:**
- Turn on verbose logging to a file. A failed trip that produces no diagnostics
  is a wasted trip.
- Charge everything, and take a power bank you do not need — see below.
- Take a second phone if you possibly can.

**In the park, deliberately test:**
- [ ] A full day with no signal, logging as you go
- [ ] **Battery.** Camera plus GPS plus a hot car is brutal. If the app flattens
      a phone by 11am it is unusable regardless of how good the reveal is.
      Measure it.
- [ ] **Heat.** Phones throttle and cameras shut down above 40°C. Kruger in
      summer will find this.
- [ ] Screen legibility in direct midday sun
- [ ] One-handed use while holding binoculars. This is the real ergonomic test
- [ ] A genuinely fast sighting — something that gives you four seconds
- [ ] Sync on the way home, when signal returns intermittently

**Afterwards:** write down every moment the app annoyed you, before you forget.
Those notes are worth more than any test suite.

---

## What this means for the build order

1. Define `CaptureSource` and `LocationSource` **first**, with fakes
2. Build the reveal, scoring and collection against the fakes — all testable
3. Wire in the real camera and GPS last
4. Then go to the park

Doing it the other way round — camera first — means the interesting parts of
Phase 2 are untestable until the very end, and you will not find the scoring
bugs until someone is on a leaderboard with them.

## What you still cannot test

Say this out loud so it is not a surprise:

- Whether the reveal actually *feels* good. Only a person can tell you.
- Whether people cheat, and how. You find that out after launch.
- Whether it drains a battery over four consecutive days.
- Whether a family in a car actually enjoys it, which is the only test that
  really matters and cannot be automated at all.
