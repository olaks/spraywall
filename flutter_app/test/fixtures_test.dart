import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'helpers/images.dart';

/// The photo-import tests trust these fixtures to carry the EXIF a phone
/// would write, so check that they really do.
void main() {
  test('a fixture carries the orientation and GPS it was asked for', () {
    final bytes = jpegFixture(width: 40, height: 30, orientation: 6, gps: true);
    final exif  = img.decodeJpgExif(bytes)!;
    expect(exif.imageIfd.orientation, 6);
    expect(exif.gpsIfd.gpsLatitude, closeTo(59.91, 0.01));
  });

  test('a plain fixture has no GPS', () {
    final exif = img.decodeJpgExif(jpegFixture());
    expect(exif?.gpsIfd.gpsLatitude, isNull);
  });
}
