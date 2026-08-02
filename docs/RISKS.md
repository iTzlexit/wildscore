# What could actually kill this

> Honest list, ordered by how much damage each one does. Most are cheap to fix
> now and expensive to fix after launch, which is the only reason to write it
> down this early.

---

## 1. Losing a collection — and no, the device does not reliably back it up

**This is the one.** Everything lives in `shared_preferences` on one phone.

The hopeful answer is that the operating system backs it up. The accurate answer
is that it *sometimes* does:

| | What actually happens |
|---|---|
| **Android** | Auto Backup covers `shared_preferences` and is on by default — but only over Wi-Fi, only when the device is idle and charging, capped at 25 MB, **silent when it fails**, and restored only during new-device setup. |
| **iOS** | Included in an iCloud backup *if* iCloud Backup is switched on and there is space. Plenty of people have it off or full. |

So: a partial, invisible, unverifiable safety net. Not something to promise
anyone, and not something a user will forgive when it does not work.

The failure is not a bug report. Somebody with three seasons of sightings loses
a phone, opens the app on the new one, sees zero, and **tells people**. That is
the review that ends a small app.

### The fix that needs no server

**Export and import a backup file.** One JSON of profile, collection and every
drive, written with the system share sheet so it can go to Drive, WhatsApp or
their own email. Import reads it back and merges.

- Costs nothing to run
- Removes the catastrophic case entirely
- Turns "I lost everything" into "I lost since my last export"
- Doubles as the migration path into cloud accounts later

**Worth building before launch, not after.** It is perhaps an evening's work and
it is the difference between a disappointed user and a hostile one.

---

## 2. You cannot take payment where the app is used

In-app purchase needs a network. Kruger does not have one.

A paywall that lands at a gate at 05:30 is unpayable by a person actively trying
to pay. See [MONETISATION.md](MONETISATION.md): ask at camp in the evening,
check entitlement only when a drive *starts*, and cache it so a paid player
works offline for a week.

Get this wrong and the conversion rate is not low — it is arbitrary, and it will
look like the price is wrong when the problem is the timing.

---

## 3. The gap between trips

People go to Kruger once or twice a year. Between trips there is nothing to
score, and an app nobody opens for eight months is an app that gets deleted when
storage runs low.

This is the honest weakness of the whole idea, and it is **not fixable, only
survivable**:

- It is the strongest argument for **once-off pricing**. A subscription across a
  ten-month dead season is a cancellation with extra steps.
- The collection is the only thing that gets opened out of season — which is why
  it stays free, and why it should be the nicest screen in the app.
- Later: a memory feed, "two years ago today you found a pangolin". Cheap,
  local, and the only genuinely good reason to open this in November.

---

## 4. The rarity tiers are unreviewed

The entire scoring system rests on tier assignments that have not been checked
by anyone who guides in the park. If a guide opens this and sees something
obviously wrong, the app loses its authority in one screen — and authority is
what the whole field guide is trading on.

This is what `tools/ranker.html` exists for. It is the cheapest credibility
insurance available and it is currently unspent.

---

## 5. Photo licensing has a loose end

Every photograph is CC0 or CC-BY. **CC-BY legally requires the attribution to be
reachable by the user**, and there is no licences screen yet — the credits sit
in `attributions.json` and are shown only in the full-screen viewer.

Not a lawsuit risk at this scale. It is a store-review and reputation risk, and
it is one screen of work. See [IMAGE-ASSETS.md](IMAGE-ASSETS.md).

---

## 6. Google Play's twelve testers

A new personal Google Play developer account must run a closed test with **12
testers for 14 consecutive days** before it can publish to production.

Fourteen *consecutive* days. It cannot be backdated, rushed or bought, and the
count resets if testers drop below twelve. That is a calendar dependency between
finishing the app and anyone being able to install it.

**Start it as early as a build is usable.** It runs in parallel with everything
else and it is pure waiting.

---

## 7. iOS needs a Mac

Flutter builds Android on Windows. It does not build iOS on Windows, ever.

Options: a Mac, or a cloud macOS runner (Codemagic, GitHub Actions). Neither is
expensive; both need deciding rather than discovering.

**Ship Android first regardless.** The audience is South African families, and
Android's share of that market makes the decision for you.

---

## 8. The name

"Wild Score" has not been checked against CIPC or either app store. A rename
after launch costs the store listing, the reviews and any search ranking
accumulated.

Check it before the store listing is written, not after.

---

## What this list does not include

**Competition.** There are species checklists and there are trip loggers. There
is nothing that scores a car full of people against each other in a national
park, which is the thing this is actually selling — and it is a hard thing to
copy well because most of the work is the tier assignments and the rules, not
the code.

Being first is not the risk here. Being forgotten between trips is.
