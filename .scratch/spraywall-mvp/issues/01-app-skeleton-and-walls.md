# 01: App skeleton and walls

Spec: [Spraywall MVP](../../spraywall-spec/spec.md)

**What to build:** A fresh install opens on the wall list. On first run the empty state says "Create your first wall"; creating one (name + grade scale) goes straight into the new wall's (empty) wall screen. Settings has the theme choice. Underneath, the repository is started with the plumbing copied from `training_logger` and schema v1 in place, so every later slice only adds behaviour.

**Blocked by:** None (can start immediately)

**Status:** done (spraywall-11, 2026-11-22), awaiting first commit

- [x] Repository started (git) with the plumbing copied from `training_logger` per the spec's *Stack and what is copied* (theme, undo snackbar, grades, share/pick helpers, web SQLite files, scripts, pre-commit hook, analysis options, pubspec pins with their comments), renamed
- [x] Schema v1 with all six tables, UUIDv7 ids (ADR 0001), foreign keys on in `beforeOpen`, FK indexes and the current-layout partial unique index; schema dump committed
- [x] Schema test (fresh install matches the dump; indexes agree) and a foreign-key enforcement test pass
- [x] Shared test helpers: in-memory database factory with foreign keys on, seed builders writing through the database API, generated JPEG fixtures, statement-counting interceptor
- [x] Wall list with first-run empty state; New wall dialog (name required, unique ignoring case; grade scale Font/V) creates the wall and its first current layout and opens it
- [x] Routes `/`, `/settings`, `/walls/:wallId` and a not-found page for unknown ids
- [x] Widget test: create a wall from the empty state and land on its wall screen
- [x] `check.sh` (analyze + tests under a timeout) passes; `release.sh` also runs `flutter build web --wasm`; the manual checklist from the spec is in the release notes or script

## Comments

- 2026-11-22 (spraywall-11): built. `check.sh` passes (analyze clean, 16 tests); `flutter build web --wasm` and `flutter build linux` succeed, and the Linux app starts and creates its database. Notes for later slices:
  - **New pin:** `jni_flutter: 1.0.3` joins the `jni: 1.0.0` override. A fresh resolve picked jni_flutter 1.1.0, which needs jni ^1.2 and breaks the Linux build (`training_logger`'s older lockfile hides this).
  - **Uniqueness:** `walls_name` and `problems_name` are `COLLATE NOCASE` unique indexes (ASCII only), backed by a Dart `toLowerCase()` check (`wallNameTaken`). `layouts_one_current` is a partial unique index.
  - **`package:image`** is a dev dependency for `jpegFixture()`; ticket 03 moves it to `dependencies`.
  - **Not copied:** the `run-linux` agent skill (not in this ticket's criteria; worth adding when a slice needs screenshots). Release signing falls back to the debug key until `android/key.properties` exists.
  - **`.gitignore`** keeps `sample/` and the prototype's byte-identical copy of it out of git (GPS).
  - **Not committed yet:** `git init` done and `core.hooksPath` set; the first commit is waiting for the user's go-ahead.
