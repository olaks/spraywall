# Storing and picking wall photos on Android, Linux and Web

Type: research
Status: resolved
Map: [Spraywall: problem-setting app spec](../map.md)

## Question

How should the app get **wall photos** in (camera and/or gallery) and store them on all three targets (Android, Linux desktop, Web/WASM), given the photos are about 12 MP JPEGs (see `sample/`)?

Find out:
- What `image_picker` / `file_picker` / `camera` support on each target (camera on Linux and Web?).
- Where the bytes should live: Drift BLOB rows (as `training_logger` does for exercise photos, `ExerciseImages`), app-directory files referenced by path, or something else. Consider the Web limits too (WASM SQLite on OPFS/IndexedDB, quota, COOP/COEP headers).
- Whether to downscale or recompress on import, and to what size, so pinch-zoom still shows tiny footholds while memory stays reasonable on a mid-range Android phone.
- EXIF handling: applying orientation on import, and stripping GPS.

The answer should recommend one approach per concern, with sources.

## Answer

Full findings and sources are in [research/photo-storage-across-platforms.md](../research/photo-storage-across-platforms.md).

- **Picking:** use `image_picker` alone. No `camera` package (it has no Linux support) and no `file_picker` for photos. Offer the gallery on every target. Show the camera button only when `supportsImageSource(ImageSource.camera)` is true, which hides it on Linux. On web the camera source opens the camera only on mobile browsers; desktop browsers fall back to a file dialog. On Android, handle `retrieveLostData()`.
- **Storage:** keep wall photos as Drift BLOBs in their own table, the way `ExerciseImages` does, and store `width`/`height` with them. Only the widget that draws a photo reads its bytes. Files on disk would need a second store on web, which has no file system. For web, keep the `coi-serviceworker` setup from `training_logger` so Drift uses OPFS. Without it, the IndexedDB fallback keeps the whole DB, photos included, in memory. Call `navigator.storage.persist()` too, and treat backup/export as needed because browser storage can be evicted.
- **Downscale:** do it on import in Dart with `package:image`: long edge 2560 px, JPEG quality 85. On the sample that gives about 0.4–0.5 MB per photo instead of 2.4 MB, and about 20 MB once decoded for display instead of 52 MB. Footholds of 2–3 cm stay clearly visible. Run it in `Isolate.run` on Android and Linux. Don't use `image_picker`'s `maxWidth`/`imageQuality`, because each platform treats them differently: Linux ignores them, Android keeps GPS, and web drops EXIF.
- **EXIF:** `decodeJpg` applies the orientation and clears that tag. Set `image.exif = ExifData()` before `encodeJpg`, because otherwise GPS is written back out (I confirmed this on the sample). Store only the re-encoded bytes.
