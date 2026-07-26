# 00 — Setup (Windows)

You are a backend developer. This page assumes you know Git and a terminal, and
nothing about mobile. Do these in order. Total time: ~60–90 min, mostly downloads.

---

## 1. Flutter SDK

Download from <https://docs.flutter.dev/get-started/install/windows/mobile>

Extract to **`C:\src\flutter`**.

Rules that catch people out:
- **Not** `C:\Program Files\...` — the space in the path breaks Flutter's tooling.
- **Not** anywhere inside OneDrive — sync will corrupt builds.

## 2. Add Flutter to PATH

Start menu → search "environment variables" → *Edit environment variables for your
account* → select `Path` → *Edit* → *New* → `C:\src\flutter\bin` → OK.

**Close and reopen your terminal.** PATH changes don't apply to already-open shells.

Verify:

```bash
flutter --version
```

## 3. Android Studio

Download from <https://developer.android.com/studio>.

You will write code in VS Code, not Android Studio. You need it anyway because it
is the only sane way to install the **Android SDK**, the **platform tools**, and an
**emulator**. Think of it as the Android equivalent of installing the .NET SDK.

On first launch, accept the standard setup (it downloads the SDK — a few GB).

Then install the command-line tools, which Flutter needs and which the standard
setup does *not* include:

> Settings → Languages & Frameworks → Android SDK → **SDK Tools** tab →
> tick **Android SDK Command-line Tools (latest)** → Apply.

## 4. Create an emulator

Android Studio → (More Actions / hamburger) → **Device Manager** → **+** →
pick **Pixel 8** → choose the latest system image with Google Play → Finish.

An emulator is a full virtualised Android device. It's slow to boot the first time
and fine after that. Leave it running while you work — hot reload pushes code into
the running app in under a second.

## 5. VS Code + Flutter extension

<https://code.visualstudio.com> → Extensions → install **Flutter** (it pulls in Dart
automatically).

## 6. Verify the whole chain

```bash
flutter doctor
```

Then accept the SDK licences (it prompts several times — type `y`):

```bash
flutter doctor --android-licenses
```

Re-run `flutter doctor` until everything is green **except** the Xcode / CocoaPods
lines. Those are red on every Windows machine and are expected — see §8.

### If `flutter doctor` can't find the Android SDK

```bash
flutter config --android-sdk "C:\Users\alex\AppData\Local\Android\Sdk"
```

---

## 7. Run the app

```bash
cd C:\dev\wildscore\app
flutter create --project-name wildscore --org com.wildscore --platforms=android,ios .
flutter pub get
flutter run
```

**Check this after `flutter create`:** open `pubspec.yaml` and confirm the
`flutter: assets:` block at the bottom is still there, listing `assets/data/`
and `assets/species/`. `flutter create` skips files that already exist, but if
that block ever goes missing the app will start and then fail to find the
species catalogue. It is the first thing to check if you get an asset error.

What each does:

| Command | What it does |
|---|---|
| `flutter create .` | Generates the **native host projects** — `android/` (Gradle) and `ios/` (Xcode). Your Dart code in `lib/` is already written; this only adds the platform shells around it. Safe to run over an existing folder; it never overwrites `lib/`. |
| `flutter pub get` | Restores packages. The direct equivalent of `dotnet restore`. |
| `flutter run` | Builds, installs on the emulator, launches, and attaches a hot-reload session. Press **r** to hot reload, **R** to restart, **q** to quit. |

Nothing about this needs a network connection at runtime — the species data ships
inside the app bundle as an asset.

---

## 8. iOS — the Mac problem

Apple only permits building and signing iOS apps on macOS. There is no legal way
around it. You have three options, in order of what I'd actually do:

1. **Build Android first, ship it, worry about iOS later.** Recommended. South
   African market share is heavily Android, and you learn the whole store pipeline
   once before doubling it.
2. **Codemagic / GitHub Actions macOS runners** — CI rents you a Mac per build.
   Roughly free at low volume. You still need a physical Apple device or the
   simulator to test properly, which is the weak point.
3. **Buy a used Mac mini.** ~R8–12k second-hand. Genuinely the least painful route
   if the app becomes real.

You do not need to decide now. Everything through Phase 4 is Windows-only work.

---

## 9. Before you launch on Google Play — start this in week one

A new **personal** Google Play developer account must run a **closed test with at
least 12 testers who stay opted in for 14 consecutive days** before it is allowed
to publish publicly. This blocks more solo developers than any technical problem.

Start recruiting those 12 people now — family, colleagues, the Kruger Facebook and
Latest Sightings communities. It costs you nothing today and saves a fortnight later.

Developer account fees: Google Play **$25 once**, Apple **$99/year**.
