import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:spraywall/database/database.dart';
import 'package:spraywall/marks/mark_geometry.dart';
import 'package:spraywall/marks/outline.dart';
import 'package:spraywall/share/share_problem.dart';

import 'helpers/app.dart';
import 'helpers/images.dart';
import 'helpers/test_db.dart';

/// Sharing a problem as images: the caption, which photos go, the render
/// itself sampled pixel by pixel, and Share in the problem view's menu.
void main() {
  Mark mark(String photoId, Role role, double cx, double cy) => Mark(
      id: newId(), problemId: 'p', photoId: photoId, role: role,
      cx: cx, cy: cy, r: 0.05);

  group('pure parts', () {
    test('caption: name · grade · wall, no grade when ungraded', () {
      expect(shareCaption(name: ' Arête ', grade: '6B', wall: 'Home wall'),
          'Arête · 6B · Home wall');
      expect(shareCaption(name: 'Project', grade: null, wall: 'Gym'),
          'Project · Gym');
    });

    test("the photos carrying the problem's marks, in layout order", () {
      WallPhoto photo(String id, int order) => WallPhoto(id: id, layoutId: 'l',
          sortOrder: order, width: 4, height: 3, addedOn: '2026-11-22');
      final photos = [photo('wall', 0), photo('left', 1), photo('kicker', 2)];
      expect(photosToShare(photos, [mark('kicker', Role.start, .5, .5),
                                    mark('wall', Role.hand, .5, .5)])
              .map((p) => p.id),
          ['wall', 'kicker']);
      expect(photosToShare(photos, []), isEmpty);
    });

    test('file names: the problem, and the photo when there are several', () {
      expect(shareImageName('Arête', 'Photo 1', several: false), 'Arête.jpg');
      expect(shareImageName('Arête / sit', 'Kicker', several: true),
          'Arête_sit-Kicker.jpg');
    });

    test('the caption bar scales with the image, within limits', () {
      expect(captionBarHeight(2560), 179);
      expect(captionBarHeight(400),  48);
      expect(captionBarHeight(9000), 220);
    });
  });

  testWidgets('the render: the photo at its own size with a caption bar '
      'under it, each ring in its role colour, the hold inside left clear',
      (tester) async {
    const w = 800, h = 600;
    final marks = [
      mark('p', Role.start,  0.2, 0.3),
      mark('p', Role.hand,   0.4, 0.6),
      mark('p', Role.foot,   0.6, 0.3),
      mark('p', Role.finish, 0.8, 0.6),
    ];
    final jpeg = (await tester.runAsync(() async => encodeShareJpeg(
        await renderShareImage(
          photo:   jpegFixture(width: w, height: h),
          marks:   marks,
          caption: 'Arête · 6B · Home wall',
        ))))!;
    final out = img.decodeJpg(jpeg)!;
    expect((out.width, out.height), (w, h + captionBarHeight(w).round()));

    bool near(img.Pixel p, Color c) =>
        (p.r - c.r * 255).abs() < 40 && (p.g - c.g * 255).abs() < 40 &&
        (p.b - c.b * 255).abs() < 40;
    for (final m in marks) {
      final c = centrePx(m.cx, m.cy, const Size(w * 1.0, h * 1.0));
      final r = radiusPx(m.r, const Size(w * 1.0, h * 1.0));
      final ring = out.getPixel((c.dx + r).round(), c.dy.round());
      expect(near(ring, roleColors[m.role]!), isTrue,
          reason: '${m.role} ring is ${[ring.r, ring.g, ring.b]}');
      final inside = out.getPixel(c.dx.round(), c.dy.round());
      expect(near(inside, const Color.fromARGB(255, 200, 180, 140)), isTrue,
          reason: 'the hold is not covered');
    }
    final bar = out.getPixel(w ~/ 2, h + 2);
    expect(bar.r, lessThan(40), reason: 'the dark caption bar');
  });

  testWidgets('the render draws an outline mark as its outline, not its '
      'circle', (tester) async {
    const w = 800, h = 600, size = Size(800, 600);
    // A box 200 × 100 px around (400, 300).
    const box = [Offset(0.375, 0.4167), Offset(0.625, 0.4167),
                 Offset(0.625, 0.5833), Offset(0.375, 0.5833)];
    final around = enclosingCircle(box, size);
    final held = Mark(id: newId(), problemId: 'p', photoId: 'p',
        role: Role.hand, cx: around.cx, cy: around.cy, r: around.r,
        outline: encodeOutline(box));
    final jpeg = (await tester.runAsync(() async => encodeShareJpeg(
        await renderShareImage(
          photo:   jpegFixture(width: w, height: h),
          marks:   [held],
          caption: 'Pinch',
        ))))!;
    final out = img.decodeJpg(jpeg)!;
    bool hand(img.Pixel p) {
      final c = roleColors[Role.hand]!;
      return (p.r - c.r * 255).abs() < 40 && (p.g - c.g * 255).abs() < 40 &&
          (p.b - c.b * 255).abs() < 40;
    }
    expect(hand(out.getPixel(500, 300)), isTrue, reason: "the box's right edge");
    expect(hand(out.getPixel(400, 250)), isTrue, reason: 'its top edge');
    final circleRight = (400 + radiusPx(around.r, size)).round();
    expect(hand(out.getPixel(circleRight, 300)), isFalse,
        reason: 'not the circle around it');
  });

  group('Share in the problem view', () {
    late AppDatabase db;
    late String      wall;
    late String      layout;
    late String      whole;
    late String      kicker;
    late String      problem;
    late FakeShare   share;
    setUp(() async {
      db      = openTestDb();
      wall    = await seedWall(db, name: 'Home wall');
      layout  = await currentLayoutId(db, wall);
      whole   = await seedPhoto(db, layout, width: 320, height: 240);
      await seedPhoto(db, layout, label: 'Left', width: 200, height: 300);
      kicker  = await seedPhoto(db, layout, label: 'Kicker', width: 300, height: 100);
      problem = await seedProblem(db, layout, name: 'Arête', grade: '6B',
          marks: [(whole, Role.start), (kicker, Role.foot)]);
      share   = FakeShare();
    });
    tearDown(() => db.close());

    Future<List<String>> menu(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Problem menu'));
      await tester.pumpAndSettle();
      final items = [
        for (final i in tester.widgetList<PopupMenuItem<void>>(
            find.byType(PopupMenuItem<void>)))
          (i.child! as Text).data!,
      ];
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      return items;
    }

    testApp('one JPEG per photo with marks, at its size plus the caption '
        'bar, named for the problem and photo', (tester) async {
      await pumpApp(tester, db, share: share);
      await goTo(tester, '/walls/$wall/problems/$problem');
      expect(await menu(tester), ['Edit', 'Share', 'Retire', 'Delete']);

      await tester.tap(find.byTooltip('Problem menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share'));
      // Decoding and drawing run in the engine, in real time.
      for (var i = 0; i < 50 && share.calls == 0; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(share.calls, 1, reason: 'one share for all the images');
      expect([for (final f in share.files) f.name],
          ['Arête-Photo_1.jpg', 'Arête-Kicker.jpg'],
          reason: 'not the left photo: no marks there');
      expect(share.files.map((f) => f.mimeType), everyElement('image/jpeg'));
      final sizes = [
        for (final f in share.files)
          (img.decodeJpg(f.bytes)!.width, img.decodeJpg(f.bytes)!.height),
      ];
      expect(sizes, [(320, 240 + 48), (300, 100 + 48)]);
      expect(find.text('Preparing image 1 of 2'), findsNothing,
          reason: 'the progress dialog has gone');
    });

    testApp('retired and archived problems can be shared too',
        (tester) async {
      await db.retireProblem(problem);
      await pumpApp(tester, db, share: share);
      await goTo(tester, '/walls/$wall/problems/$problem');
      expect(await menu(tester), ['Share', 'Un-retire', 'Delete']);
    });

    testApp('an archived problem offers Share alone', (tester) async {
      await tester.runAsync(
          () => db.resetLayout(wall, startedOn: DateTime(2030)));
      await pumpApp(tester, db, share: share);
      await goTo(tester, '/walls/$wall/layouts/$layout/problems/$problem');
      expect(await menu(tester), ['Share']);
    });
  });
}
