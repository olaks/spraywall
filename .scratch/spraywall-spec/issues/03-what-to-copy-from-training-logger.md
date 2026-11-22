# What to copy from training_logger

Type: research
Status: resolved
Map: [Spraywall: problem-setting app spec](../map.md)

## Question

Which parts of `../training_logger/flutter_app` should the new app copy as a starting point, and what does each one bring with it?

Look at: the climbing grade scales (Font/V), theme and accent colours, Drift setup (including the web worker and the migration/schema-test approach), JSON backup/import, the undo-snapshot pattern, `scripts/check.sh` + pre-commit hook, `build-apk.sh` / `deploy-web.sh` / `release.sh`, and the pinned-dependency workarounds.

For each: worth copying (yes/no), what it depends on, and what must be renamed or stripped. Note anything in `CODING_STANDARDS.md` that should carry over as-is.

## Answer

Copy the plumbing, rebuild the domain. Nearly verbatim (with a rename pass for `training_logger`/`olaks/training_logger`/`/training_logger/`): `utils/grades.dart`, the dark Material 3 theme + four accents and `theme_provider.dart`, `undo_snackbar.dart`, `share_file*.dart`, `pick_text_file.dart`, `backup_provider.dart`, the web SQLite files (`drift_worker.dart`/`.js`, `sqlite3.wasm`, `coi-serviceworker.js`), `scripts/check.sh`, `.githooks/pre-commit`, `build-apk.sh`, `release.sh`, `deploy-web.sh`, `analysis_options.yaml`, the `run-linux` agent skill, and the pubspec pins with their comments (drift `<2.34.1`, `jni: 1.0.0` override, win32-5 trio). Rebuild as patterns only: the Drift DB class (start at schema v1 with `foreign_keys` in `beforeOpen` and photo blobs in their own table), schema dump + `schema_test.dart` from the first commit, JSON backup (versioned, name-keyed, idempotent merge, lookups before loop, base64 photos), and delete-returns-snapshot undo. All four `CODING_STANDARDS.md` rules carry over; the name-matching one needs adapting to per-layout problem names. Leave all screens and training-domain utils behind.

Full table with paths, dependencies and renames: [research/what-to-copy-from-training-logger.md](../research/what-to-copy-from-training-logger.md)
