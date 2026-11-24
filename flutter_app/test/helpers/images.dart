import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// A small solid-colour JPEG made in code. The real wall photo carries GPS and
/// is never committed, so tests build exactly the EXIF they need instead.
///
/// [orientation] sets the EXIF orientation tag (6 = rotated 90° clockwise),
/// and [gps] writes a made-up location — what a phone camera would add.
Uint8List jpegFixture({
  int  width       = 40,
  int  height      = 30,
  int? orientation,
  bool gps         = false,
  int  r = 200, int g = 180, int b = 140,
}) {
  final image = img.Image(width: width, height: height)
    ..clear(img.ColorRgb8(r, g, b));
  if (orientation != null) image.exif.imageIfd.orientation = orientation;
  if (gps) {
    image.exif.gpsIfd.setGpsLocation(latitude: 59.91, longitude: 10.75);
  }
  return img.encodeJpg(image, quality: 85);
}

/// A wall-coloured JPEG with one red hold: a disc of [radius] px at
/// [centre]. Something for the tracer to find.
Uint8List jpegWithHold({
  int width  = 1600,
  int height = 1200,
  required (int, int) centre,
  required int radius,
}) {
  final image = img.Image(width: width, height: height)
    ..clear(img.ColorRgb8(214, 186, 140));
  img.fillCircle(image, x: centre.$1, y: centre.$2, radius: radius,
      color: img.ColorRgb8(200, 30, 40));
  return img.encodeJpg(image, quality: 90);
}
