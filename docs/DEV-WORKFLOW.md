# Day-to-day development

## Is this only a mobile app?

**Yes.** The product ships to Android and iOS. Nothing else.

You will see a `web/` folder and web builds in this repo. That is **a development
convenience, not a product** — it lets code be compiled and eyeballed in a
browser in 40 seconds without an emulator. The real app cannot work on the web:
it needs a camera you cannot fake, a GPS fix, and days of offline operation.

There is a *possible* future case for a web page showing the public leaderboard
and a read-only Codex, purely as marketing. That is not the app, and it is not
on the roadmap.

## What you need connected

You have two options for seeing the app while you work. **Use your own phone.**

### Option A — your physical phone over USB (recommended)

Better than an emulator in every way that matters here: real camera, real GPS,
real performance, real screen in real sunlight. And you do **not** need Android
Studio for it.

1. On the phone: **Settings → About phone → tap "Build number" seven times.**
   That unlocks Developer options.
2. **Settings → Developer options → enable "USB debugging".**
3. Plug the phone into the PC with a cable that carries data — many charging
   cables do not.
4. The phone shows *"Allow USB debugging?"* — tick *Always allow* and accept.
5. Check the PC can see it:

```bash
C:\src\android-sdk\platform-tools\adb.exe devices
```

You should see your device listed. If it says `unauthorized`, look at the phone
— the prompt is waiting.

### Option B — an emulator

Needs Android Studio installed for the AVD manager. Fine for quick UI work,
useless for camera and GPS testing. Only worth it if you want to check small
screen sizes, or you do not want to keep your phone tethered.

## Running the app

Open the project folder — `C:\dev\wildscore` — in VS Code. Not the `app`
subfolder; the workspace root, so you can see the docs too.

Then either press **F5**, or from a terminal:

```bash
flutter run
```

Run that from `C:\dev\wildscore\app`. If `flutter` is not found, your PATH entry
is missing — see [00-SETUP.md](00-SETUP.md) step 2.

### Hot reload — the thing that makes Flutter worth it

While the app is running, save a file and the change appears **in under a
second**, with the app still on the same screen and the same state. You do not
rebuild, reinstall, or navigate back to where you were.

| Key | Does |
|---|---|
| `r` | Hot reload — keeps state |
| `R` | Hot restart — resets state, use after changing anything in `main()` |
| `q` | Quit |

Coming from backend work: this is closer to editing a running process than to
`dotnet build`. Leave the app running all day.

Some things hot reload cannot pick up — changes to `main()`, to global
variables, to enum definitions, or adding a package. Hot restart (`R`) handles
those. Adding a package needs a full stop and `flutter run` again.

## Before you commit

```bash
pwsh scripts/check.ps1
```

Format, analyze, all tests. About 20 seconds. Enable it as a hook once:

```bash
git config core.hooksPath .githooks
```

Then walk [REVIEW-CHECKLIST.md](REVIEW-CHECKLIST.md) for what tests cannot catch.

## Two different meanings of "tester"

These get confused, and they are months apart.

**Testing it yourself, now.** Install the APK, or run it from VS Code on your
phone. That is all "testing" means at this stage. Nobody else is involved.

**The 12 Google Play testers — Phase 5.** A separate thing entirely: Google
requires a **new personal developer account** to run a closed test with at least
**12 testers who stay opted in for 14 consecutive days** before it will let you
publish publicly. It is a launch gate, not a development activity.

You do not need those people yet, but **start collecting names now** — family,
colleagues, the Kruger Facebook groups. The 14-day clock cannot be backdated,
so every week you delay is a week added to your launch date. A list of names in
a text file is enough for now.

Once CI is green, every push to `main` produces downloadable APKs on the GitHub
Actions run. That is how you will get builds to those people without anyone
installing Flutter.
