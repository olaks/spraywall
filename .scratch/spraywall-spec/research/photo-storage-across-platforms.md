# Research: storing and picking wall photos on Android, Linux and Web

Ticket: [01 – Storing and picking wall photos](../issues/01-photo-storage-across-platforms.md)
Date: 2026-11-21

Package versions checked: `image_picker` 1.2.3, `image_picker_android` 0.8.13+17,
`image_picker_linux` 0.2.2, `image_picker_for_web` 3.1.1,
`image_picker_platform_interface` 2.11.1, `drift` 2.34.0, `sqlite3` 3.3.0
(all from the local pub cache, which is what `training_logger` resolves), and
`image` 4.13.1, `camera` 0.12.2, `flutter_image_compress` 2.5.1 (latest
archives from pub.dev). Sample: `sample/IMG_20210522_093949634.jpg`.

## TL;DR

| Concern | Recommendation |
|---|---|
| Getting photos in | `image_picker` on all three targets. Offer **gallery everywhere**. Show **camera** only when `ImagePicker().supportsImageSource(ImageSource.camera)` is true. That rules out Linux. On web the button only opens a camera on mobile browsers. Don't add `camera` or `file_picker`. |
| Where bytes live | **Drift BLOB rows** in a `WallPhotos` table of their own, just as `ExerciseImages` does. Store `width`/`height` next to the bytes. Not files on disk, because web has no file system. |
| Downscale/recompress | **Yes**, on import: long edge **2560 px**, JPEG **quality 85**. Do it in Dart with `package:image`, not with `image_picker`'s `maxWidth`/`imageQuality`, which behave differently on each platform. About 0.4–0.5 MB per wall photo, and about 20 MB decoded when it is drawn. |
| EXIF | `package:image`'s `decodeJpg` applies orientation and clears the tag. Then set `image.exif = ExifData()` before `encodeJpg`. Otherwise **GPS is written back out**. Store only the re-encoded bytes, never the original. |

## 1. Picking: what each plugin supports

### image_picker (the one already in `training_logger`)

- Platform table: Android SDK 24+, Linux "Any", Web, plus iOS, macOS and Windows.
  ([image_picker README](https://pub.dev/packages/image_picker))
- **Linux: no camera.** "By default, `ImageSource.camera` is not supported,
  since unlike on Android and iOS there is no system-provided UI for taking
  photos". You can only plug in your own `cameraDelegate`. Desktop pickers wrap
  `file_selector`. ([image_picker README, "Windows, macOS, and Linux"](https://pub.dev/packages/image_picker#windows-macos-and-linux))
- **Linux ignores resize options.** "The arguments `maxWidth`, `maxHeight`, and
  `imageQuality` are not currently supported."
  ([image_picker_linux README](https://pub.dev/packages/image_picker_linux))
  So `training_logger`'s `maxWidth: 512` (`edit_exercise_screen.dart:242`,
  `exercises_screen.dart:703`) has no effect on Linux. There, exercise photos go
  into the DB at full size.
- **Web: camera means a hint to mobile browsers.** The plugin adds an
  `<input type=file capture=…>`. "Each browser may implement `capture` any way
  they please". Desktop browsers just open a file dialog.
  `supportsImageSource(camera)` still returns `true` on web, because the base
  `ImagePickerPlatform` default returns true for both sources
  (`image_picker_platform_interface` `image_picker_platform.dart:343`). Only
  the desktop `CameraDelegatingImagePickerPlatform` returns
  `cameraDelegate != null` (`:359`).
  ([image_picker_for_web README](https://pub.dev/packages/image_picker_for_web#limitations-on-the-web-platform))
- **Web resize** draws the image to a `<canvas>` and calls `canvas.toBlob(mime, quality)`
  (`image_picker_for_web` `lib/src/image_resizer.dart`). The output is a newly
  encoded file, so no EXIF from the original is copied.
- **Android resize** uses `BitmapFactory` and `Bitmap.compress`, then
  `ExifDataCopier` copies EXIF across. The copied tag list explicitly includes
  all `TAG_GPS_*` and `TAG_ORIENTATION` (`ExifDataCopier.java` lines 100–133).
  The pixels are **not** rotated. So a picker-resized Android photo **still
  carries GPS** and still relies on the orientation tag.
- Android uses the system Photo Picker on Android 13+. It can be killed under
  memory pressure while the camera intent runs. Call `retrieveLostData()` on
  start. ([image_picker README, "Handling MainActivity destruction"](https://pub.dev/packages/image_picker#handling-mainactivity-destruction-on-android))

### camera

The federated platforms are `android` (camera_android_camerax), `ios`, and `web`
(camera_web). **There is no Linux implementation** (`camera` 0.12.2
`pubspec.yaml` `flutter.plugin.platforms`). It would also mean building a
viewfinder UI of our own. A wall photo is taken rarely and the system camera app
does it better, so `camera` isn't worth adding.

### file_picker

`training_logger` already uses it for CSV import. For images it adds nothing
over `image_picker`'s gallery source, which on Linux already is a
`file_selector` dialog. It also pulls in the win32 pin trio described in
`training_logger/CLAUDE.md`. Not needed for photos.

## 2. Where the bytes live

### Options

1. **Drift BLOB column** (training_logger's `ExerciseImages`: `categoryId` PK + `data BlobColumn`,
   in its own table so that list queries never pull bytes; `tables.dart:139-152`).
2. **Files in the app directory** (`path_provider`), with the path stored in Drift.
3. Web-specific storage (OPFS files / IndexedDB) beside the DB.

### Why BLOBs win here

- **Web has no `dart:io` file system**, so option 2 only works on Android and
  Linux. It would need a second, web-only store (option 3), which means two code
  paths, two backup formats and no transactions spanning DB and photo. BLOBs give
  one code path everywhere, and that matches `training_logger`.
- **Consistency with layouts.** A layout and its photos are archived on reset and
  marks reference a photo. Keeping bytes in the same transaction as the rows
  means there can be no orphaned or missing files. Undo-by-snapshot, as in
  `training_logger`, also keeps working.
- **Backup/export** is one SQLite file, or one JSON with base64.
- **Performance cost is negligible at this scale.** SQLite's own measurements:
  "For BLOBs smaller than 100KB, reads are faster when the BLOBs are stored
  directly in the database file. For BLOBs larger than 100KB, reads from a
  separate file are faster", and 8192/16384-byte pages are best for large BLOBs.
  ([sqlite.org: Internal Versus External BLOBs](https://www.sqlite.org/intern-v-extern-blob.html))
  A wall photo is ~0.5 MB and is read once when a photo is opened. That costs
  milliseconds, not a design driver.
- Default `SQLITE_MAX_LENGTH` is 1,000,000,000 bytes per value, far above 0.5 MB.
  ([sqlite.org/limits.html](https://www.sqlite.org/limits.html))

### Web specifics (Drift WASM)

From `drift` 2.34.0 `lib/src/web/wasm_setup/types.dart`, `WasmStorageImplementation`:

- `opfsShared`: OPFS through a shared worker. Needs nested workers, which are
  "only implemented in Firefox".
- `opfsLocks`: OPFS through dedicated workers. **Requires cross-origin
  isolation** (`COOP: same-origin`, `COEP: require-corp`).
- `sharedIndexedDb` / `unsafeIndexedDb`: the fallbacks.

So on Chrome and Safari, the OPFS path depends on COOP/COEP. On GitHub Pages
those headers can't be set, which is why `training_logger` ships
`web/coi-serviceworker.js`, loaded in `index.html` before `flutter_bootstrap.js`.
Spraywall should copy that setup.

**Why it matters more with photos:** the IndexedDB fallback in `sqlite3` is an
`InMemoryFileSystem` that is persisted asynchronously. "It uses an in-memory
cache to synchronously wrap this file system (at the loss of durability
guarantees)" (`sqlite3` 3.3.0 `lib/src/wasm/vfs/indexed_db.dart:20-24, 450-479`).
So without COI, the **entire DB, every photo included, sits in worker memory**.
At ~0.5 MB a photo, 100 photos come to ~50 MB, which is tolerable. Still, it is
another reason to re-encode on import, and to keep `coi-serviceworker` working.

A side effect of COEP `require-corp`: any cross-origin image or asset the page
loads needs CORP/CORS headers. Our photos come from the DB as bytes, so they
aren't affected.

**Quota and eviction** ([MDN: Storage quotas and eviction criteria](https://developer.mozilla.org/en-US/docs/Web/API/Storage_API/Storage_quotas_and_eviction_criteria)):

- Chrome allows up to 60% of disk per origin.
- Firefox best-effort allows min(10% of disk, 10 GiB per site group).
- Safari 17+ allows ~60%.
- Quota is not the limit that matters. **Eviction** is: best-effort origins go
  first under LRU pressure, and Safari, with tracking prevention, deletes
  script-written data after 7 days without interaction.
- Call `navigator.storage.persist()` on web. Firefox prompts for it, while
  Chrome and Safari decide on their own from engagement. Also keep an
  export/backup path, because web is the least durable target.

### Table shape (suggestion, not code)

`WallPhotos(id, layoutId → Layouts, width, height, sortOrder, createdAt)` with the bytes in a
separate `WallPhotoData(photoId PK → WallPhotos, jpeg BLOB)`. The other option
is one table that list queries simply never `SELECT` from. Either way, follow
the `ExerciseImages` rule: only the widget that draws a photo reads its bytes.

Storing `width`/`height` lets marks be laid out (as normalised 0–1 coordinates)
before the image decodes. A small (~512 px) thumbnail BLOB is optional, for
layout and photo lists. It is cheap to add at import time.

## 3. Downscale / recompress on import

### Measurements on the sample (3120×4160, 2.43 MiB, JPEG q≈95, moto g(7) play)

ImageMagick, `-strip`, long edge × quality → bytes:

| long edge | q90 | q85 | q80 |
|---|---|---|---|
| 4160 (none) | 1.72 MB | 1.05 MB | 0.82 MB |
| 3072 | 0.81 MB | 0.56 MB | 0.44 MB |
| **2560** | 0.56 MB | **0.39 MB** | 0.31 MB |
| 2048 | 0.37 MB | 0.26 MB | 0.21 MB |
| 1600 | 0.24 MB | 0.18 MB | 0.14 MB |

`package:image` 4.13.1 (Dart JIT on desktop), full decode → resize to 2560 →
`encodeJpg(quality: 85)`: decode 239 ms, resize 74 ms, encode 133 ms, giving
**498 KB**. With the EXIF left in, the output is 510 KB and contains the GPS
IFD. With `exif` cleared there are 0 EXIF/GPS tags (checked with
`identify -verbose`). Expect several times slower in AOT on a mid-range phone,
and slower again on web. That is still a one-off cost per import.

### Resolution vs. footholds

- In the sample, the T-nut grid (~20 cm pitch, assumed) is ~195 px, so ~1 mm/px
  at full resolution. That works out to ~1.6 mm/px at 2560 and ~2 mm/px at 2048.
- I cropped the same area at full size and at 2048. The small screw-on feet
  (~2–3 cm, ~15–20 px across at 2048) stay clearly recognisable, colour and
  shape included. 2560 leaves margin for wider shots of bigger walls.

### Memory

- Flutter draws a decoded RGBA bitmap: 1920×2560×4 ≈ **19.7 MB**, against
  3120×4160×4 ≈ **52 MB** for the original. Two or three of those in the image
  cache are fine on a 3–4 GB phone. Twelve-megapixel originals in a photo list
  are not.
- Use `ResizeImage` / `cacheWidth` for thumbnails, and the full image only
  inside the zoomable view (`InteractiveViewer`).
- 2560 also stays under the 4096 px maximum texture size that is common on
  mobile GPUs. That limit is general knowledge and I didn't verify it against
  Flutter's own docs for this ticket.

### Why not use the picker's `maxWidth`/`imageQuality`

They are ignored on Linux. On Android they keep GPS and leave the orientation
tag in place. On web, canvas re-encoding drops EXIF. Three different behaviours,
so do the resize in one place, in Dart, where it can be unit-tested with
`sample/`.

`flutter_image_compress` (native, fast) has no Linux implementation (its
platforms are android, ios, macos, web and ohos), so it can't be the single
path.

Run the pure-Dart step in `Isolate.run` on Android and Linux. On web it runs on
the UI thread, because there are no isolates there, so show a progress
indicator.

`decodeJpg(bytes, scale: 2)` (fast DCT downscaling) is useful only when the
source is at least 2× the target, for example a 50 MP phone. On the 12 MP
sample, scale 2 gives 2080 px, below 2560.

## 4. EXIF: orientation and GPS

- The sample has **no Orientation tag** (its pixels are already upright) but
  **does carry GPS** (`exif:GPSInfo` IFD) along with make and model. Other phones
  write rotated pixels plus Orientation 6/8, so handle both cases.
- `package:image` 4.13.1 applies orientation in `decodeJpg`. Rows are converted
  "in the EXIF orientation", and the decoder sets `exif.imageIfd.orientation = null`
  (`lib/src/formats/jpeg/_jpeg_image.dart:17-51`). `bakeOrientation()` exists
  for other formats and also nulls the tag (`lib/src/transform/bake_orientation.dart`).
- **GPS trap:** the decoded `Image` keeps the rest of the EXIF, and
  `JpegEncoder` writes `image.exif` whenever it isn't empty
  (`lib/src/formats/jpeg_encoder.dart:63, 705-720`). Clear it with
  `image.exif = ExifData()` before encoding. My test confirmed GPS survives
  otherwise.
- Don't rely on the platform to strip GPS. Android's `image_picker` resize
  copies GPS tags explicitly. The Android Photo Picker docs say nothing about
  location redaction. Web drops EXIF only as a side effect of canvas re-encoding.
- Since only the re-encoded bytes are stored, stripping is complete and needs
  nothing else (no `exif` or `native_exif` package). If a capture date is
  wanted, read `DateTimeOriginal` from the decoded EXIF into a column before
  clearing it.

## Open points for the map

- Whether a layout's photos need a thumbnail column (helps the layout list), or
  whether `cacheWidth` decoding of the 2560 px BLOB is fast enough. It is cheap
  to add at import either way.
- How web backup and export works, since web storage is evictable. It belongs
  with whatever backup design the map has.
- Linux camera: none. A user on Linux imports a photo taken on the phone. Worth
  stating in the spec so nobody builds a `cameraDelegate`.
