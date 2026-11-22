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
