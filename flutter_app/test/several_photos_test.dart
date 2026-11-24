import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/marks/mark_layer.dart';
import 'package:spraywall/widgets/zoomable_photo.dart';

import 'helpers/app.dart';
import 'helpers/test_db.dart';

/// A problem across several of the layout's photos: the strip that switches
/// between them in the editor and the view, each photo's own zoom, and which
/// photo each screen opens on.
void main() {
  late AppDatabase db;
  late String      wall;
  late String      layout;
  late String      whole;
  late String      left;
  late String      kicker;
  setUp(() async {
    db     = openTestDb();
    wall   = await seedWall(db, name: 'Home wall');
    layout = await currentLayoutId(db, wall);
    // Different sizes, so a test can tell which photo is on screen.
    whole  = await seedPhoto(db, layout, label: 'Whole wall', width: 1600, height: 1200);
    left   = await seedPhoto(db, layout, label: 'Left half',  width: 1200, height: 1600);
    kicker = await seedPhoto(db, layout, label: 'Kicker',     width: 1000, height: 500);
  });
  tearDown(() => db.close());

  String shown(WidgetTester tester) =>
      tester.widget<ZoomablePhoto>(find.byType(ZoomablePhoto)).photo.id;

  TransformationController controller(WidgetTester tester) =>
      tester.widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!;

  MarkLayer layer(WidgetTester tester) =>
      tester.widget<MarkLayer>(find.byType(MarkLayer));

  Future<void> pick(WidgetTester tester, String photoId) async {
    await tester.tap(find.byKey(ValueKey('strip-$photoId')));
    await tester.pumpAndSettle();
  }

  double opacity(WidgetTester tester, String photoId) => tester
      .widget<Opacity>(find.descendant(
          of: find.byKey(ValueKey('strip-$photoId')),
          matching: find.byType(Opacity)))
      .opacity;

  String count(WidgetTester tester, String photoId, Role role) => tester
      .widget<Text>(find.byKey(ValueKey('count-$photoId-${role.name}')))
      .data!;

  MarkInput mark(String photoId, Role role) =>
      (id: newId(), photoId: photoId, role: role, cx: 0.5, cy: 0.5, r: 0.02,
       outline: null);

  group('the editor', () {
    Future<void> openNew(WidgetTester tester) async {
      await pumpApp(tester, db);
      await goTo(tester, '/walls/$wall/problems/new');
    }

    testApp('a new problem opens on the first photo, with the strip in '
        'layout order', (tester) async {
      await openNew(tester);
      expect(shown(tester), whole);
      final xs = [for (final id in [whole, left, kicker])
                    tester.getCenter(find.byKey(ValueKey('strip-$id'))).dx];
      expect(xs, orderedEquals([...xs]..sort()));
      expect(find.text('Kicker'), findsOneWidget, reason: 'labels show');
    });

    testApp('switching clears the selection and keeps each photo\'s zoom',
        (tester) async {
      await openNew(tester);
      await tester.tapAt(tester.getCenter(find.byType(InteractiveViewer)));
      await tester.pump();
      expect(layer(tester).selectedId, isNotNull);

      final zoomed = Matrix4.diagonal3Values(2.5, 2.5, 2.5)
        ..setTranslationRaw(-700, -400, 0);
      controller(tester).value = zoomed;
      await tester.pump();

      await pick(tester, kicker);
      expect(shown(tester), kicker);
      expect(layer(tester).selectedId, isNull);
      expect(find.byKey(const ValueKey('resize-handle')), findsNothing);
      final kickerFit = controller(tester).value.clone();
      expect(kickerFit, isNot(zoomed), reason: 'the kicker has its own view');

      // A mark here belongs to the kicker, and its thumbnail counts it.
      await tester.tapAt(tester.getCenter(find.byType(InteractiveViewer)));
      await tester.pump();
      expect(layer(tester).marks.single.photoId, kicker);
      expect(count(tester, kicker, Role.hand), '1');
      expect(count(tester, whole,  Role.hand), '1');

      await pick(tester, whole);
      expect(controller(tester).value, zoomed, reason: 'zoom kept');
      expect(layer(tester).selectedId, isNull);
      await pick(tester, kicker);
      expect(controller(tester).value, kickerFit);
    });

    testApp('editing opens on the photo the view was showing',
        (tester) async {
      final problem = await db.createProblem(
          layoutId: layout, name: 'Arête', setOn: DateTime(2026, 11, 20),
          marks: [mark(kicker, Role.start)]);
      await pumpApp(tester, db);
      await goTo(tester, '/walls/$wall/problems/$problem');
      expect(shown(tester), kicker, reason: 'the start photo');

      await pick(tester, left);
      await tester.tap(find.byTooltip('Problem menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit details'), findsOneWidget);
      expect(shown(tester), left);
    });

    testApp('a single-photo layout has no strip', (tester) async {
      await db.deletePhoto(left);
      await db.deletePhoto(kicker);
      await openNew(tester);
      expect(find.byKey(ValueKey('strip-$whole')), findsNothing);
    });
  });

  group('the view', () {
    testApp('opens on the first photo with a start mark, and dims photos '
        'without marks but still shows them', (tester) async {
      final problem = await db.createProblem(
          layoutId: layout, name: 'Arête', setOn: DateTime(2026, 11, 20),
          marks: [mark(whole, Role.hand), mark(kicker, Role.start),
                  mark(kicker, Role.foot), mark(kicker, Role.foot)]);
      await pumpApp(tester, db);
      await goTo(tester, '/walls/$wall/problems/$problem');

      expect(shown(tester), kicker);
      expect(opacity(tester, left), lessThan(1));
      expect(opacity(tester, whole),  1);
      expect(opacity(tester, kicker), 1);
      expect(count(tester, kicker, Role.foot),  '2');
      expect(count(tester, kicker, Role.start), '1');

      await pick(tester, left);
      expect(shown(tester), left, reason: 'dimmed, but selectable');
      expect(layer(tester).marks, isEmpty);
    });
  });
}
