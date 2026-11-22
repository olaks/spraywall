# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Spraywall sets boulder problems on a climbing spray wall: one user marks holds on photos of the wall. The app is in `flutter_app/`, a Flutter project for Android, Linux desktop and Web (WASM) from one Dart codebase. It copies its plumbing from `../training_logger`.

- Vocabulary: `GLOSSARY.md` (Wall, Layout, Wall photo, Problem, Mark, Role, Grade, Reset, …). Use its terms in code, tests and UI text.
- Decisions: `docs/adr/`. Every id is a UUIDv7 string (ADR 0001).
- The spec and the build tickets: `.scratch/spraywall-spec/spec.md` and `.scratch/spraywall-mvp/issues/` (the local tracker, see `docs/agents/issue-tracker.md`).
- `sample/` holds the real wall photo for manual checks. It carries GPS: never commit it or copy it into tests.

## Build and run commands

All commands run from `flutter_app/`:

```bash
flutter pub get                        # install dependencies
flutter run -d linux                   # run Linux desktop version
flutter run -d web-server --web-port 8080  # run web version locally
flutter build apk --release            # release APK
flutter build web --wasm               # web build
flutter build linux --release          # release Linux build
```

Rebuild Drift-generated code after changing database tables or queries:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Rebuild the web SQLite worker (only after a `drift` upgrade):

```bash
dart compile js -O2 -o web/drift_worker.js lib/drift_worker.dart
```

Run tests:

```bash
flutter test                           # all tests
flutter test test/walls_test.dart      # single test file
```

`scripts/check.sh` runs `flutter analyze` and the tests; the pre-commit hook in
`.githooks/` runs it (enable per clone: `git config core.hooksPath .githooks`).
`release.sh` also builds the web version and prints the manual checklist.
Review rules live in `CODING_STANDARDS.md`.

The Dart is hand-aligned (columns of `=` and `:` lined up), not `dart format`
output: edit in that style, and leave `dart format` off existing files.

## Tests

Everything runs on the VM: unit tests for pure-Dart logic, database tests on
an in-memory database, and widget tests. No goldens and no device tests; what
only a device can show is on `release.sh`'s manual checklist. Each build
ticket lists the tests that close it.

Shared helpers live in `test/helpers/`: `openTestDb()` (foreign keys on),
seed builders that go through the app's own database API, `jpegFixture()`
(generated JPEGs with optional EXIF orientation and fake GPS),
`StatementCounter`, and `pumpApp()` for widget tests, with a
`FakePhotoSource` in place of the picker and the photo import run inline
(an isolate never finishes under fake time). `pumpApp` opens a 400×800
phone window (the test default, 800×600, would be a wide window); pass
`size:` for a wide one. It also puts a `FakeShare` in place of the share
sheet / save dialog / download, takes a `clock:` for the backup reminder,
and with `keepPrefs: true` reopens the app over what the last run stored
(how a test lets days pass).

Widget tests run in fake time, where a drift stream (`watch…().first`) never
completes: read streams inside `tester.runAsync` (one-shot queries and writes
complete without it), and advance the clock a millisecond after the tree is
torn down so drift's stream-close timer can run (`teardownTree`). Write app
widget tests with `testApp`, which runs it after the body, pass or fail: the
binding checks timers before any `addTearDown`, and a failed test that skips
it hangs the runner for minutes. A button
enabled by `setState` needs a `pump()` before it can be tapped. A reorder
drag moves in steps (`moveTo` plus `pump` in a loop) to a point measured from
the target row; one long jump lands short. Let a snackbar slide in
(`pumpAndSettle`) before tapping its action. Seeding that reads a stream
(`seedProblem` without explicit marks) goes inside `runAsync` in a widget
test. A write from the test body after `pumpApp` doesn't reach the app's
streams under fake time: seed what the screen should show before pumping.
An app action whose result arrives through streams the screen hadn't
seen before (a reset moves it onto the new layout's) needs `settleDb`, which
alternates real-time gaps with frames; `pumpAndSettle` would leave the old
state on screen, or spin on a progress indicator.

## Architecture

- **State:** Riverpod 3. `dbProvider` holds the database; screens watch
  `StreamProvider`s over `watch…` queries in `providers/app_providers.dart`.
  `prefsProvider` and `themeIndexProvider` are overridden in `main()`.
- **Navigation:** go_router, plain stack with the wall list as the root and
  nested routes, so the back stack and a web reload follow the hierarchy.
  Unknown routes and ids show `NotFoundScreen`.
- **Database:** Drift, tables in `database/tables.dart`. Photo bytes live in
  `WallPhotoBytes`, apart from `WallPhotos`, so lists never load blobs.

### Database

Schema v1. A schema version is frozen once a release carries it — compare
against the newest `v*` tag. An unreleased version may be amended in place,
re-dumping its schema; a released one only moves forward with a migration step
in `database.dart`.

Foreign keys are enforced (`PRAGMA foreign_keys = ON` in `beforeOpen`) and no
table cascades. Undo works by each delete returning a snapshot that the
matching `restore*` puts back.

Indexes are declared with `@TableIndex` / `@TableIndex.sql` on the tables (the
partial unique index `layouts_one_current` keeps one current layout per wall).
After changing the schema, dump it so future migrations can be verified
against this version:

```bash
dart run drift_dev schema dump lib/database/database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/generated_migrations/
```

`test/schema_test.dart` checks the dump against a fresh install.

### Pinned dependencies

Holds in `pubspec.yaml`, worth revisiting when the Flutter SDK or the toolchain moves:

- `drift` below 2.34.1 — newer versions break `drift_dev`'s schema verifier, and the `drift_dev` release that fixes it needs a newer analyzer than this Flutter SDK allows. Lift both together. `web/drift_worker.js` is compiled from this drift version.
- `jni` overridden to 1.0.0 and `jni_flutter` to 1.0.3 — both arrive via `path_provider_android` and are Android-only, but they are still compiled for the Linux desktop build, where jni 1.0.1+ fails; jni_flutter 1.1+ needs jni ^1.2. Lift together.
- `file_picker` and `share_plus` held on the win32 5 line (file_picker 12 and share_plus 13 need win32 6; in training_logger that broke the APK via wakelock_plus). Re-check before lifting.

A stale Gradle cache can survive a dependency change and fail the APK build with a missing plugin class; `flutter clean` clears it.

## Web deployment note

The web version uses WebAssembly SQLite and needs these HTTP headers:
```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```
GitHub Pages can't set them, so `web/coi-serviceworker.js` adds them; it must
load before `flutter_bootstrap.js`. The Flutter dev server sets them itself.
