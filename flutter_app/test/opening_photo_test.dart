import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/marks/opening_photo.dart';

/// Which photo the problem view opens on.
void main() {
  WallPhoto photo(String id, int order) => WallPhoto(
      id: id, layoutId: 'l', sortOrder: order, width: 4, height: 3,
      addedOn: '2026-11-22');
  Mark mark(String photoId, Role role) => Mark(
      id: newId(), problemId: 'p', photoId: photoId, role: role,
      cx: 0.5, cy: 0.5, r: 0.02);

  final photos = [photo('wall', 0), photo('left', 1), photo('kicker', 2)];

  test('the first photo with a start mark', () {
    final marks = [mark('wall', Role.hand), mark('kicker', Role.start),
                   mark('left', Role.start)];
    expect(openingPhoto(photos, marks)!.id, 'left',
        reason: 'first in the layout order, not in mark order');
  });

  test('else the first with any mark', () {
    expect(openingPhoto(photos, [mark('kicker', Role.foot),
                                 mark('left', Role.hand)])!.id, 'left');
  });

  test("else the layout's first photo", () {
    expect(openingPhoto(photos, [])!.id, 'wall');
    expect(openingPhoto([], []), isNull);
  });
}
