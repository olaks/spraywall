import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/photos/photo_source.dart';

import 'helpers/app.dart';
import 'helpers/images.dart';
import 'helpers/test_db.dart';

/// Wall photos in the app: the first one from the wall screen, the Photos
/// screen's label, usage count and delete, and the full-screen viewer.
void main() {
  late AppDatabase db;
  late String      wall;
  late String      layout;
  setUp(() async {
    db     = openTestDb();
    wall   = await seedWall(db, name: 'Home wall');
    layout = await currentLayoutId(db, wall);
  });
  tearDown(() => db.close());

  Future<List<WallPhoto>> photos(WidgetTester tester) async =>
      (await tester.runAsync(() => db.watchPhotos(layout).first))!;

  group('wall screen', () {
    testApp('a layout without photos offers to add one, from a file '
        'where there is no camera', (tester) async {
      final source = FakePhotoSource(
          next: jpegFixture(width: 400, height: 300, orientation: 6, gps: true));
      await pumpApp(tester, db, photos: source);
      await goTo(tester, '/walls/$wall');
      expect(find.text('No wall photos yet'), findsOneWidget);

      await tester.tap(find.text('Add a wall photo'));
      await tester.pumpAndSettle();

      expect(source.picks, [PhotoFrom.file], reason: 'no camera, no question');
      final stored = await photos(tester);
      expect((stored.single.width, stored.single.height), (300, 400),
          reason: 'stored upright');
      expect(find.text('Add a wall photo'), findsNothing);
      expect(find.text('No problems yet'), findsOneWidget);
    });

    testApp('with a camera, it asks which', (tester) async {
      final source = FakePhotoSource(supportsCamera: true, next: jpegFixture());
      await pumpApp(tester, db, photos: source);
      await goTo(tester, '/walls/$wall');

      await tester.tap(find.text('Add a wall photo'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a photo'), findsOneWidget);
      await tester.tap(find.text('Take a photo'));
      await tester.pumpAndSettle();

      expect(source.picks, [PhotoFrom.camera]);
      expect(await photos(tester), hasLength(1));
    });

    testApp('backing out of the picker adds nothing', (tester) async {
      final source = FakePhotoSource();
      await pumpApp(tester, db, photos: source);
      await goTo(tester, '/walls/$wall');

      await tester.tap(find.text('Add a wall photo'));
      await tester.pumpAndSettle();
      expect(await photos(tester), isEmpty);
      expect(find.text('Add a wall photo'), findsOneWidget);
    });
  });

  testApp('a photo Android lost while the camera was open is added on '
      'the next start', (tester) async {
    final source = FakePhotoSource()..lost = (jpegFixture(), layout);
    await pumpApp(tester, db, photos: source);
    await tester.pumpAndSettle();
    expect(await photos(tester), hasLength(1));
    expect(find.textContaining('Added the wall photo you took'), findsOneWidget);
  });

  group('photos screen', () {
    testApp('shows how many problems use each photo, and labels',
        (tester) async {
      final used = await seedPhoto(db, layout, label: 'Whole wall');
      await seedPhoto(db, layout);
      await seedProblem(db, layout, marks: [(used, Role.start)]);
      await pumpApp(tester, db);
      await goTo(tester, '/walls/$wall/photos');

      expect(find.text('1 problem uses this photo'), findsOneWidget);
      expect(find.text('No problems use this photo'), findsOneWidget);
      expect(find.text('Photo 2'), findsOneWidget, reason: 'unlabelled');

      await tester.tap(find.byTooltip('Photo menu').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit label'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Kicker');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Kicker'), findsOneWidget);
    });

    testApp('an unused photo deletes, and undo brings it back',
        (tester) async {
      await seedPhoto(db, layout, label: 'Whole wall');
      await seedPhoto(db, layout, label: 'Kicker');
      await pumpApp(tester, db);
      await goTo(tester, '/walls/$wall/photos');

      await tester.tap(find.byTooltip('Photo menu').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Kicker'), findsNothing);
      expect(find.text('Deleted "Kicker"'), findsOneWidget);

      await tester.tap(find.text('UNDO'));
      await tester.pumpAndSettle();
      expect(find.text('Kicker'), findsOneWidget);
      expect((await photos(tester)).map((p) => p.label),
          ['Whole wall', 'Kicker']);
    });

    testApp('a photo with marks is refused, naming the problems',
        (tester) async {
      final photo = await seedPhoto(db, layout, label: 'Whole wall');
      await seedProblem(db, layout, marks: [(photo, Role.start)]);
      await pumpApp(tester, db);
      await goTo(tester, '/walls/$wall/photos');

      await tester.tap(find.byTooltip('Photo menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Can\'t delete "Whole wall"'), findsOneWidget);
      expect(find.textContaining('Arête'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(await photos(tester), hasLength(1));
    });

    testApp('dragging a photo by its handle reorders them',
        (tester) async {
      for (final label in ['A', 'B', 'C']) {
        await seedPhoto(db, layout, label: label);
      }
      await pumpApp(tester, db);
      await goTo(tester, '/walls/$wall/photos');

      final start   = tester.getCenter(find.byIcon(Icons.drag_handle).first);
      final target  = tester.getBottomLeft(find.widgetWithText(ListTile, 'C')).dy + 8;
      final gesture = await tester.startGesture(start);
      for (var i = 1; i <= 10; i++) {
        await gesture.moveTo(Offset(start.dx, start.dy + (target - start.dy) * i / 10));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect((await photos(tester)).map((p) => p.label), ['B', 'C', 'A']);
    });
  });

  testApp('the full-screen view fits the photo, and the zoom it reports '
      'is the fit factor', (tester) async {
    final photo = await seedPhoto(db, layout, width: 1600, height: 1200);
    await pumpApp(tester, db);
    await goTo(tester, '/walls/$wall/photos/$photo');

    final viewer   = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    final viewport = tester.getSize(find.byType(InteractiveViewer));
    final fit      = [viewport.width / 1600, viewport.height / 1200]
        .reduce((a, b) => a < b ? a : b);
    final matrix   = viewer.transformationController!.value;

    // Without any pinch: a fit that left z at 1 would report 1 here.
    expect(matrix.getMaxScaleOnAxis(), closeTo(fit, 1e-9));
    // Centred on the long axis.
    final shown = Size(1600 * fit, 1200 * fit);
    expect(matrix.getTranslation().x, closeTo((viewport.width - shown.width) / 2, 1e-6));
    expect(matrix.getTranslation().y, closeTo((viewport.height - shown.height) / 2, 1e-6));
  });
}
