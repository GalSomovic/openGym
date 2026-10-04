# openGym for Apple platforms (native)

A native SwiftUI app for iPhone and iPad, built on openGym. It is a fork of
[DuarteSantos8/openGym](https://github.com/DuarteSantos8/openGym) and is licensed, like
openGym, under the **GNU AGPL v3.0 or later**, with openGym's app-store exception
(see the root `NOTICE.md`). All source stays public in this repository.

openGym's author deliberately does not publish openGym on app stores. This app is an
independent fork, published under a different name, and credits openGym prominently.

## Architecture

```
apple/
  core/                 entry.js + build.sh: bundles openGym's training engine
                        actions.js: the profile and the steps that change it (vitest)
  OpenGymCore/          Swift package: JavaScriptCore bridge + typed Swift API
  App/                  SwiftUI app (iPhone + iPad), widgets, Live Activity
```

**Native UI, openGym's engine.** Every screen is SwiftUI. The training logic (progression
rules, 1RM, supersets, warm-ups, drop sets, recovery, structural balance, history, CSV and
Hevy imports, plates) is *not* reimplemented: openGym's own pure, unit-tested `frontend/src/lib`
modules are bundled into one script (`apple/core/build.sh`) that runs in JavaScriptCore inside
the app. Results therefore match openGym exactly, the state shape matches openGym backups, and
upstream fixes arrive by merging upstream and rebuilding. The script ships inside the app and is
never downloaded, which App Review allows.

**One way to change anything.** openGym's screens change the profile from closures inside its
React views. `apple/core/actions.js` reproduces those closures headless, on the same lib helpers
(start, tick a set, rest, supersets, add/swap/move exercises, finish, log a past workout), and
the default profile is lifted from openGym's own store at build time (`gen-defaults.mjs`).
Swift's `GymStore` calls these actions and draws the snapshots they return; it never writes the
profile itself, so fields it does not model survive untouched.

**Local-first.** No account and no server: data lives on the device, in openGym's state shape,
with optional iCloud sync (openGym's `sync-merge` reconciles devices). Server-only features
(passkey accounts, self-hosted sync, admin, web push, MCP) are replaced by native equivalents
or not applicable.

## Native additions

- **Guided workouts over your music.** Spoken cues (AVSpeechSynthesizer) and timer chimes duck
  the music you are already playing instead of stopping it (`.playback` + `.mixWithOthers` +
  `.duckOthers`); the current set and rest timer live on the Lock Screen and Dynamic Island
  (Live Activity), and the end of a rest can ring through silent mode (AlarmKit, opt-in).
- **Animated exercise demos.** Pluggable source (see "Exercise media" below).
- iPad layouts, widgets, Siri/App Shortcuts, haptics, Apple Health export (later).

## Exercise media

The demos are the 180×180 animated GIFs of the **free ExerciseDB V1 dataset by AscendAPI**
([oss.exercisedb.dev](https://oss.exercisedb.dev)), whose terms allow non-commercial apps with
credit to AscendAPI. This app is free, with no ads and no in-app purchases, and shows
"Exercise animations © AscendAPI (ExerciseDB)" with every demo, in About and in the store
listing. Every openGym exercise carries its ExerciseDB id (`0001-2gPfomN.jpg` → `2gPfomN`), so
all 1,324 map to an official GIF.

The GIFs are **never committed** (publishing the raw files would be redistribution):
`apple/core/fetch-media.sh` downloads them once, throttled and resumable, into the gitignored
`apple/Media/`, and Xcode bundles them (about 120 MB). The app makes no network calls for media.

## Plan

| Phase | Scope |
|---|---|
| 0 | Fork, engine bundle, JavaScriptCore bridge with tests ✅ |
| 1 | Profile store (openGym's state JSON, saved atomically), typed snapshots, headless workout actions with tests ✅ (iCloud sync moves to phase 6) |
| 2 | Library (search, filters, muscle map from MuscleMap, demos), Plan + routine editor, starter plans |
| 3 | Workout logger: sets, supersets, warm-ups, drop sets, rest-pause, side sets, plates, rest timer, progression on finish |
| 4 | Guided mode: animated demos, spoken cues over music, Live Activity, AlarmKit rest end |
| 5 | History, stats (1RM, volume, effort), recovery and detrained maps, structural balance, body weight, check-in QR |
| 6 | Imports (FitNotes, Strong, Hevy CSV, openGym backups), export, 16 languages (openGym's catalogues), iPad |
| 7 | QA, accessibility, App Store release under a distinct name |

## Building

```sh
cd frontend && npm ci && cd ..
apple/core/build.sh                       # test the actions, bundle the engine
cd apple/OpenGymCore && swift test        # bridge and store tests
```
