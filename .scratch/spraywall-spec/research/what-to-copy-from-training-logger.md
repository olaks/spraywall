# What to copy from training_logger

Research for [issue 03](../issues/03-what-to-copy-from-training-logger.md).
Source: the repo at `/home/ola/Documents/dev/training_logger` (read only, as of
2026-11-21). Paths below are relative to that repo unless they say otherwise.

## Summary

Copy the plumbing, not the domain. The tooling (`scripts/check.sh`,
`.githooks/pre-commit`, the three build/release scripts), the web SQLite
files, the theme, the grade lists, the undo snackbar and the file share/pick
helpers can come across almost verbatim with a rename pass. Drift, the
backup and undo pieces are **patterns** to rebuild against the new tables
(walls, layouts, wall photos, problems, marks), because the training_logger
versions are 2,500 lines welded to exercises/sets/plans. Start the new app at
schema version 1 with the schema-dump and schema-test approach set up from the
first commit, not 19 versions of migrations.

## The table

| Item | Copy? | File paths | Dependencies | What to rename or strip |
|---|---|---|---|---|
| Font/V grade lists | Yes, verbatim | `flutter_app/lib/utils/grades.dart` | none | Nothing. `detectGradeScale` guesses a scale from logged grades; a problem probably stores its scale explicitly, so that helper may go. Grades are plain strings in lists; the index is the sort key (`gradeToIndex`). |
| Theme + accents | Yes | `flutter_app/lib/theme/app_theme.dart`, `flutter_app/lib/providers/theme_provider.dart`, accent row in `flutter_app/lib/screens/settings/settings_screen.dart` (lines ~29-76, ~203-240), wiring in `flutter_app/lib/main.dart` and `flutter_app/lib/app.dart` (~line 47-50) | `shared_preferences`, `flutter_riverpod` | Dark-only Material 3, four accents (Forest/Ocean/Dusk/Ember), pref key `theme_index`. Keep or rename accents. Note mark role colours (start/hand/foot/finish) must stay readable on photos and are a separate choice from the accent. |
| Drift DB class + `driftDatabase(...)` opener | Pattern only | `flutter_app/lib/database/database.dart` lines 1-30, 219-235 | `drift` (pinned `<2.34.1`), `drift_flutter ^0.3.0` | Keep: `driftDatabase(name:, web: DriftWebOptions(sqlite3Wasm:, driftWorker:))`, `AppDatabase.forTesting(super.e)`, `beforeOpen` running `PRAGMA foreign_keys = ON` (must be outside a transaction, see comment), `_hasColumn` helper. Rename DB name `training_logger` (it becomes the sqlite file name, e.g. `~/Documents/training_logger.sqlite` on Linux). Strip every table, the 19 migration blocks, `_seedDefaults`, `_purgeOrphans`. Start at `schemaVersion => 1`. |
| Tables file | No (pattern only) | `flutter_app/lib/database/tables.dart` | drift | Take the idea of photos in their own table (`ExerciseImages`, line 146: blob keyed by parent id) so list queries never load blobs; CLAUDE.md "Database" explains why. Wall photos are the main blobs here, so this matters more than in training_logger. `@TableIndex` declared on tables. |
| Generated code | No | `flutter_app/lib/database/database.g.dart` | build_runner, drift_dev | Regenerate. |
| Web SQLite worker + wasm | Yes | `flutter_app/lib/drift_worker.dart`, `flutter_app/web/drift_worker.js` (+ `.map`, `.deps`), `flutter_app/web/sqlite3.wasm`, `flutter_app/web/coi-serviceworker.js`, `<script src="coi-serviceworker.js">` in `flutter_app/web/index.html` | drift version (worker is compiled from it), sqlite3 wasm build | `drift_worker.js` is a compiled artefact of the drift version in use; recompile with `dart compile js -O2 -o web/drift_worker.js lib/drift_worker.dart` rather than trusting the copy if drift moves. `coi-serviceworker.js` (MIT, from gzuidhof) supplies COOP/COEP on GitHub Pages; keep it. Rename title/meta in `index.html` and `web/manifest.json` ("Training Logger" / "Training"). Replace icons/favicon. `.map`/`.deps` are optional. |
| Schema dump + migration test | Yes (approach + test skeleton) | `CLAUDE.md` "Database" section (dump commands), `flutter_app/drift_schemas/`, `flutter_app/test/generated_migrations/`, `flutter_app/test/schema_test.dart` | `drift_dev` (pinned with drift), `sqlite3 ^3.3.0` dev dep | Copy the first test ("a fresh database matches what the generated code expects", `validateDatabaseSchema`) now; the upgrade tests only once v2 exists. Do not copy the v16-v19 dumps. Copy the rule "a schema version is frozen once a release carries it" (CLAUDE.md). Rename package import `training_logger`. |
| JSON backup export/import | Pattern only | `flutter_app/lib/database/database.dart` lines 1058-1425 (`exportToJson`, `importFromJson`), `flutter_app/test/backup_test.dart` (statement-counting interceptor, ~line 331-365) | `dart:convert` | Keep the shape: top-level `version` + `exportedAt`, optional fields omitted when null, children nested under parents and referenced by **name** not id, photos as base64, import merges by case-insensitive name and is idempotent, lookups built before the loop, `batch` inserts. Strip all exercise/workout/plan/day-note/body-weight/inspiration code and the FitNotes CSV import (line 1426+). Base64 wall photos will make the file large; decide whether the backup includes photos (likely yes, they are the only copy). Start at `version: 1`. |
| Backup reminder | Yes, light edit | `flutter_app/lib/providers/backup_provider.dart`, `flutter_app/test/backup_status_test.dart` | `shared_preferences`, `dateFromStr`/`dateStrFrom` in `flutter_app/lib/utils/format_utils.dart` | Also defines `prefsProvider` (overridden in `main()`), which the theme and others need. Bring the two date helpers from `format_utils.dart` or inline them. Edit the "training history" wording. |
| Share/download a JSON file | Yes | `flutter_app/lib/utils/share_file.dart`, `share_file_io.dart`, `share_file_web.dart` | `share_plus`, `path_provider` (io); `dart:html` (web) | The web half uses deprecated `dart:html` behind `// ignore`s; consider porting to `package:web` while copying. Nothing to rename. |
| Pick a text file | Yes | `flutter_app/lib/utils/pick_text_file.dart` | `file_picker` (win32-5 pin) | Nothing. |
| Undo snapshot pattern | Yes (pattern + snackbar verbatim) | `flutter_app/lib/utils/undo_snackbar.dart`; `deleteCategory`/`restoreCategory` and `DeletedCategory` in `flutter_app/lib/database/database.dart` (lines ~402-470, ~2393-2460); `flutter_app/test/undo_test.dart`, `delete_undo_test.dart`, `delete_set_snackbar_test.dart` | drift transactions, foreign keys on | Snackbar verbatim (`persist: false` is load-bearing, see its doc comment). Rebuild `DeletedProblem` (problem + its marks), `DeletedLayout`/`DeletedWall` (photos, problems, marks) with matching `restore*` that reinserts with original ids, parents first. |
| Riverpod wiring | Pattern only | `flutter_app/lib/providers/app_providers.dart` (`dbProvider` lines 15-19, `StreamProvider`s, `extension DbMutations on WidgetRef` line 387), `flutter_app/lib/main.dart` | `flutter_riverpod ^3.3.1` | Copy `dbProvider` and the `main()` override pattern (prefs read before `runApp`). Strip everything else (TrackNotifier, timers, wakelock, load series). |
| Router + app shell | Pattern only | `flutter_app/lib/app.dart` | `go_router ^17.2.0` | Shell route with bottom nav + detail routes; lifecycle listener that rolls "today" forward is training-specific, strip it. |
| Image picking | Pattern only | `flutter_app/lib/screens/exercises/edit_exercise_screen.dart` (~line 187-250, `ImagePicker().pickImage(maxWidth: 512, imageQuality: 80)`) | `image_picker ^1.1.0` | 512 px is far too small for a wall photo whose holds must be markable; choose a new max size. |
| `scripts/check.sh` | Yes, verbatim | `scripts/check.sh` | `flutter`, coreutils `timeout` | Assumes app lives in `flutter_app/` next to `scripts/`; keep that layout or edit the `cd`. |
| Pre-commit hook | Yes, verbatim | `.githooks/pre-commit` | git; `git config core.hooksPath .githooks` per clone | Greps for `^flutter_app/`; same layout assumption. |
| `build-apk.sh` | Yes | `build-apk.sh` | JDK 17 at `/usr/lib/jvm/java-17-openjdk`, `bsdtar` | Rename `training-logger-linux.zip`. |
| `release.sh` | Yes | `release.sh` | `gh` CLI, existing local tag `v<version>` from `pubspec.yaml`, `check.sh`, JDK 17, `bsdtar` | Rename `REPO="olaks/training_logger"`, artefact names `training-logger-$TAG.*`. |
| `deploy-web.sh` | Yes | `deploy-web.sh` | `gh` CLI, GitHub Pages set to branch `gh-pages` path `/`, SSH push access | Rename `REPO`, `BASE_HREF="/training_logger/"`, mktemp prefix. Commit name/email are the owner's; fine to keep for the same owner. |
| Android signing | Config yes, key: decide | `flutter_app/android/app/build.gradle.kts` (lines ~36-60), `flutter_app/android/key.properties` and `flutter_app/android/app/release-keystore.jks` (both gitignored via `flutter_app/android/.gitignore`) | Gradle | Change `namespace`/`applicationId` from `com.example.training_logger`. The keystore can be reused or a new one made; either way it is not in git, so it has to be copied/created by hand. |
| Linux desktop ids | Rename | `flutter_app/linux/CMakeLists.txt` (`BINARY_NAME`, `APPLICATION_ID`), `flutter_app/android/app/src/main/AndroidManifest.xml` (`android:label`) | — | Easier to let `flutter create` generate platform folders for the new name than to copy them. |
| Pinned dependencies | Yes, with comments | `flutter_app/pubspec.yaml`, CLAUDE.md "Pinned dependencies" | Flutter SDK version on this machine | Keep: `drift '>=2.18.0 <2.34.1'` (lift with drift_dev together); `dependency_overrides: jni: 1.0.0` (Linux build); `file_picker ^11`, `share_plus ^12`, `wakelock_plus <1.6` win32-5 trio. Spraywall likely needs no `wakelock_plus`, `audioplayers`, `fl_chart`, `table_calendar`, `url_launcher`; dropping `wakelock_plus` loosens the trio but `file_picker` 12 / `share_plus` 13 still need win32 6, so re-check before lifting. `jni` comes via `path_provider_android`, so the override still applies. |
| `analysis_options.yaml` | Yes | `flutter_app/analysis_options.yaml` | `flutter_lints ^6.0.0` | Just `include: package:flutter_lints/flutter.yaml`. |
| `run-linux` agent skill | Yes, worth it | `.claude/skills/run-linux/` (`SKILL.md`, `launch.sh`, `navigate.sh`, `navigate.dart`, `screenshot.py`, `seed_demo.py`, `stop.sh`) | Linux desktop build, python3, X11 | Rename paths/binary (`training_logger_run`, `training_logger.sqlite`), rewrite `seed_demo.py` for walls/problems. Keeps the agent away from the real DB. |
| CLAUDE.md | Partly | `CLAUDE.md` | — | Carry over: build/run commands, build_runner and worker-recompile commands, check/hook paragraph, hand-aligned style note, widget-test fake-time note, migration/freeze rules, pinned-deps section, COOP/COEP note. Strip: legacy `app/` dir, periodized plans, ACWR, routes, tables. |
| Domain code (screens, plans, load, hangboard, inspirations, FitNotes) | No | `flutter_app/lib/screens/**`, `flutter_app/lib/utils/{periodization,plan_setup,training_load,phase_countdown,beeper,body_weight,youtube}.dart` | — | — |

## CODING_STANDARDS.md: what carries over

Source: `CODING_STANDARDS.md`.

- **As-is:** "Deletes clear their children and hand back a snapshot" (swap the
  example class names for `DeletedProblem`, `DeletedLayout`, ...); "Imports
  build their lookups before the loop"; "A migration test starts from the
  generated schema of the version it upgrades"; "An undo that outlives its
  widget goes through the database it captured".
- **Adapt:** "Names match ignoring case, first match winning" applies if
  backups match problems/walls by name. Problems are named per layout, so the
  natural key is probably (wall, layout, problem name), not a global name.
- The style rule (hand-aligned `=`/`:` columns, no `dart format`) lives in
  `CLAUDE.md`, not the standards file; decide whether the new app keeps it.

## Surprising or worth knowing

- CLAUDE.md says "Two holds" in pubspec but lists three (drift, jni, the win32
  trio).
- `flutter_app/android/key.properties` and `release-keystore.jks` exist on
  disk but are gitignored, so a fresh clone builds release APKs with the debug
  key (`build.gradle.kts` falls back silently).
- CI was removed on purpose; `check.sh` (via the hook and `release.sh`) is the
  only gate (`release.sh` comment).
- `share_file_web.dart` still uses deprecated `dart:html`.
- Wall photos change the weight of several decisions that were minor in
  training_logger: blob table separation, image downscale size (512 px there),
  and backup file size with base64 photos.
