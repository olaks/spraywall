import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Long edge of a stored wall photo: enough to show 2–3 cm footholds on a
/// whole-wall shot, at about half a megabyte.
const kPhotoLongEdge = 2560;

/// Long edge of the thumbnail used in lists and photo strips.
const kThumbLongEdge = 384;

/// A wall photo ready to store: upright, at most [kPhotoLongEdge] px, and with
/// no EXIF at all, so the GPS a phone camera writes never reaches the
/// database, a backup or a shared image.
class ImportedPhoto {
  final Uint8List data;
  final Uint8List thumb;
  final int       width;
  final int       height;

  const ImportedPhoto({
    required this.data,
    required this.thumb,
    required this.width,
    required this.height,
  });
}

/// Thrown when the picked file isn't an image `package:image` can read.
class UnreadablePhoto implements Exception {
  const UnreadablePhoto();

  @override
  String toString() => "That file isn't a photo this app can read";
}

/// Turns picked image bytes into an [ImportedPhoto]. Pure and synchronous, so
/// callers run it in an isolate (`compute`) to keep the UI responsive.
ImportedPhoto importPhoto(Uint8List bytes) {
  // The JPEG decoder rotates the pixels by the EXIF orientation and clears
  // the tag, so the decoded image is already upright.
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const UnreadablePhoto();

  final photo = _fitLongEdge(decoded, kPhotoLongEdge);
  final thumb = _fitLongEdge(photo,   kThumbLongEdge);
  // Resizing copies the EXIF along; encoding would write it back, GPS and all.
  photo.exif = img.ExifData();
  thumb.exif = img.ExifData();

  return ImportedPhoto(
    data:   img.encodeJpg(photo, quality: 85),
    thumb:  img.encodeJpg(thumb, quality: 80),
    width:  photo.width,
    height: photo.height,
  );
}

/// The list thumbnail for a stored photo, made again from its bytes (a
/// backup doesn't carry thumbnails). Pure, like [importPhoto], for an
/// isolate.
Uint8List makeThumb(Uint8List data) {
  final decoded = img.decodeImage(data);
  if (decoded == null) throw const UnreadablePhoto();
  final thumb = _fitLongEdge(decoded, kThumbLongEdge)..exif = img.ExifData();
  return img.encodeJpg(thumb, quality: 80);
}

/// [image] shrunk so its long edge is at most [longEdge]; never enlarged.
img.Image _fitLongEdge(img.Image image, int longEdge) {
  final long = math.max(image.width, image.height);
  if (long <= longEdge) return image;
  return image.width >= image.height
      ? img.copyResize(image, width: longEdge,
          interpolation: img.Interpolation.average)
      : img.copyResize(image, height: longEdge,
          interpolation: img.Interpolation.average);
}
