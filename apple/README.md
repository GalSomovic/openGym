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
  App/                  SwiftUI app (iPhone + iPad): project.yml (XcodeGen), dev.sh, shot.sh
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
- **Walks, runs and rides with GPS** (optional, Today → "Walk, run or ride"): a live map of the
  route, distance, moving time and pace, pause/resume, tracking on with the screen locked (When
  In Use location plus the `location` background mode) and a Lock Screen Live Activity. Fixes
  worse than 20 m are dropped and the rest smoothed (`OpenGymCore/Route.swift`, tested). An
  activity is filed as an ordinary openGym cardio workout (`core/activity.js`), so History,
  the calendar and the streak count it; the route stays in a file on the device, outside the
  profile and backups.
- **Apple Health, opt-in** (Settings → Apple Health): strength workouts (start and end, no
  invented calories), walks/runs/rides with distance and route (an `HKWorkoutSession` with its
  live builder while tracking), and weigh-ins are saved; the latest body weight can be imported
  and the 7-day step average fills the calorie setup. Nothing is asked until it is turned on.
- iPad layouts, widgets, Siri/App Shortcuts, haptics.

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

## Food database

The optional food log can search about 7,700 generic foods offline: **USDA FoodData Central**
Foundation Foods and SR Legacy, public domain (CC0), credited in About as "U.S. Department of
Agriculture, Agricultural Research Service. FoodData Central". `apple/mediatools/usda_foods.py`
downloads the CSVs into the gitignored `apple/Media/_raw/usda/` and writes the committed
`apple/App/GymFree/Food/usda-foods.json` (about 0.9 MB, 0.2 MB gzipped): per 100 g kcal, protein,
fat, available carbohydrate (USDA's carbohydrate by difference minus fibre, as on EU labels) and
fibre, plus household portions. Search runs in Swift (`Food/FoodDatabase.swift`); picking a food only
fills in the per-100 g values, and logging stays in `apple/core/nutrition.js`.

## Plan

| Phase | Scope |
|---|---|
| 0 | Fork, engine bundle, JavaScriptCore bridge with tests ✅ |
| 1 | Profile store (openGym's state JSON, saved atomically), typed snapshots, headless workout actions with tests ✅ (iCloud sync moves to phase 6) |
| 2 | Library (search, filters, demos), Plan + routine editor, exercise settings, starter plans ✅ (muscle map moves to phase 5) |
| 3 | Workout logger: sets, supersets, warm-ups, drop sets, rest-pause, side sets, plates, rest timer, timed holds, progression on finish, UI tests ✅ (pre-workout weigh-in moves to phase 5 with body weight) |
| 4 | Guided mode: one set at a time with the demo, spoken cues that duck your music, Lock Screen Live Activity with Set done / Skip rest buttons, opt-in AlarmKit rest alarm ✅ |
| 5 | History, stats (1RM, volume, effort), recovery and detrained maps, structural balance, body weight, check-in QR |
| 6 | Imports (FitNotes, Strong, Hevy CSV, openGym backups), export, 16 languages (openGym's catalogues), iPad |
| 7 | QA, accessibility, App Store release under a distinct name |

## Building

```sh
cd frontend && npm ci && cd ..
apple/core/build.sh                       # test the actions, bundle the engine
cd apple/OpenGymCore && swift test        # bridge and store tests
apple/core/fetch-media.sh                 # once: the exercise animations (about 125 MB)
brew install xcodegen && apple/App/dev.sh # generate, build, install on the booted simulator
```
