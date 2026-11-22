import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:spraywall/photos/photo_import.dart';

import 'helpers/images.dart';

/// Photo import: upright, at most 2560 px, no EXIF, with a 384 px thumbnail.
/// Byte sizes are not asserted; they depend on the encoder.
void main() {
  img.Image decode(Uint8List bytes) => img.decodeJpg(bytes)!;

  test('a 4000×3000 photo comes out at 2560 on the long edge', () {
    final out = importPhoto(jpegFixture(width: 4000, height: 3000));
    expect((out.width, out.height), (2560, 1920));
    final data = decode(out.data);
    expect((data.width, data.height), (2560, 1920),
        reason: 'the stored size is the real size');
  });

  test('a small photo is not upscaled', () {
    final out = importPhoto(jpegFixture(width: 800, height: 600));
    expect((out.width, out.height), (800, 600));
  });

  test('orientation 6 swaps width and height and leaves no tag', () {
    final out  = importPhoto(jpegFixture(width: 400, height: 300, orientation: 6));
    expect((out.width, out.height), (300, 400));
    final data = decode(out.data);
    expect((data.width, data.height), (300, 400));
    expect(data.exif.imageIfd.hasOrientation, isFalse);
  });

  test('the output has no EXIF, so no GPS', () {
    final input = jpegFixture(width: 400, height: 300, gps: true, orientation: 6);
    expect(decode(input).exif.gpsIfd.isEmpty, isFalse,
        reason: 'the fixture does carry GPS');

    final out = importPhoto(input);
    for (final bytes in [out.data, out.thumb]) {
      expect(decode(bytes).exif.isEmpty, isTrue);
      // And not just unreadable to `image`: no EXIF segment at all.
      expect(_hasExifSegment(bytes), isFalse);
    }
  });

  test('the thumbnail is 384 px on the long edge', () {
    final out   = importPhoto(jpegFixture(width: 3000, height: 4000));
    final thumb = decode(out.thumb);
    expect((thumb.width, thumb.height), (288, 384));
  });

  test('bytes that are not an image are refused', () {
    expect(() => importPhoto(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(isA<UnreadablePhoto>()));
  });
}

/// Whether a JPEG has an APP1 segment starting `Exif\0\0`.
bool _hasExifSegment(List<int> jpeg) {
  var i = 2;
  while (i + 4 < jpeg.length && jpeg[i] == 0xFF) {
    final marker = jpeg[i + 1];
    final length = (jpeg[i + 2] << 8) | jpeg[i + 3];
    if (marker == 0xDA) return false; // start of scan: no more headers
    if (marker == 0xE1 &&
        String.fromCharCodes(jpeg.sublist(i + 4, i + 8)) == 'Exif') {
      return true;
    }
    i += 2 + length;
  }
  return false;
}
