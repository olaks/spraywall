import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/marks/mark_layer.dart';

import 'helpers/app.dart';
import 'helpers/test_db.dart';

/// The same screens on a wide window (≥ 600 dp): the strip as a left column,
/// the palette or the details as a right side bar, lists capped at 720.
void main() {
  late AppDatabase db;
  late String      wall;
  late String      layout;
  late String      whole;
  late String      kicker;
  late String      problem;
  setUp(() async {
    db      = openTestDb();
    wall    = await seedWall(db, name: 'Home wall');
    layout  = await currentLayoutId(db, wall);
    whole   = await seedPhoto(db, layout, label: 'Whole wall', width: 1600, height: 1200);
    kicker  = await seedPhoto(db, layout, label: 'Kicker',     width: 1000, height: 500);
    problem = await db.createProblem(
      layoutId: layout, name: 'Arête', grade: '6B',
      description: 'Sit start, arête is in.', setOn: DateTime(2026, 11, 20),
      marks: [
        (id: newId(), photoId: whole, role: Role.start, cx: 0.3, cy: 0.8, r: 0.02),
      ],
    );
  });
  tearDown(() => db.close());

  const wide      = Size(800, 600);
  const landscape = Size(800, 360);   // a phone on its side

  Rect photo(WidgetTester tester) =>
      tester.getRect(find.byType(InteractiveViewer));
  Rect strip(WidgetTester tester) =>
      tester.getRect(find.byKey(ValueKey('strip-$kicker')));
  MarkLayer layer(WidgetTester tester) =>
      tester.widget<MarkLayer>(find.byType(MarkLayer));

  group('the editor', () {
    Future<void> openNew(WidgetTester tester, Size size) async {
      await pumpApp(tester, db, size: size);
      await goTo(tester, '/walls/$wall/problems/new');
    }

    Future<void> placeMark(WidgetTester tester) async {
      await tester.tapAt(photo(tester).center);
      await tester.pump();
      expect(layer(tester).marks, hasLength(1));
      expect(layer(tester).selectedId, isNotNull);
    }

    testApp('at 400 dp: strip under the photo, palette under the strip',
        (tester) async {
      await openNew(tester, phone);
      final chip = tester.getRect(find.byKey(const ValueKey('role-start')));
      expect(strip(tester).top, greaterThanOrEqualTo(photo(tester).bottom));
      expect(chip.top, greaterThanOrEqualTo(strip(tester).bottom));
      await placeMark(tester);
    });

    testApp('at 800 dp: strip on the left, palette on the right',
        (tester) async {
      await openNew(tester, wide);
      expect(strip(tester).right, lessThanOrEqualTo(photo(tester).left));
      for (final r in Role.values) {
        expect(tester.getRect(find.byKey(ValueKey('role-${r.name}'))).left,
            greaterThanOrEqualTo(photo(tester).right));
      }
      expect(tester.getRect(find.byTooltip('Delete mark')).left,
          greaterThanOrEqualTo(photo(tester).right));
      expect(photo(tester).height, greaterThan(500),
          reason: 'the photo fills the height');
      await placeMark(tester);

      // The strip still switches photos, and the palette still recolours.
      await tester.tap(find.byKey(ValueKey('strip-$kicker')));
      await tester.pumpAndSettle();
      await placeMark(tester);
      await tester.tap(find.byKey(const ValueKey('role-finish')));
      await tester.pump();
      expect(layer(tester).marks.single.role, Role.finish);
    });

    testApp('the switch is at 600 dp exactly', (tester) async {
      await openNew(tester, const Size(599, 700));
      expect(strip(tester).top, greaterThanOrEqualTo(photo(tester).bottom),
          reason: 'narrow at 599');
      tester.view.physicalSize = const Size(600, 700);
      await tester.pumpAndSettle();
      expect(strip(tester).right, lessThanOrEqualTo(photo(tester).left),
          reason: 'wide at 600');
    });

    testApp('a landscape phone gets the wide layout, with nothing '
        'overflowing', (tester) async {
      await openNew(tester, landscape);
      expect(strip(tester).right, lessThanOrEqualTo(photo(tester).left));
      expect(tester.takeException(), isNull);
      await placeMark(tester);
    });

    testApp('resizing the window keeps the marks being placed',
        (tester) async {
      await openNew(tester, phone);
      await placeMark(tester);
      tester.view.physicalSize = wide;
      await tester.pumpAndSettle();
      expect(strip(tester).right, lessThanOrEqualTo(photo(tester).left));
      expect(layer(tester).marks, hasLength(1));
    });
  });

  group('the view', () {
    Future<void> openView(WidgetTester tester, Size size) async {
      await pumpApp(tester, db, size: size);
      await goTo(tester, '/walls/$wall/problems/$problem');
    }

    testApp('at 400 dp: strip under the photo, description sheet under '
        'that, no panel', (tester) async {
      await openView(tester, phone);
      expect(strip(tester).top, greaterThanOrEqualTo(photo(tester).bottom));
      expect(tester.getRect(find.text('Sit start, arête is in.')).top,
          greaterThanOrEqualTo(strip(tester).bottom));
      expect(find.byKey(const ValueKey('details-panel')), findsNothing);
    });

    testApp('at 800 dp: strip on the left, details panel on the right',
        (tester) async {
      await openView(tester, wide);
      final panel = find.byKey(const ValueKey('details-panel'));
      expect(strip(tester).right, lessThanOrEqualTo(photo(tester).left));
      expect(tester.getRect(panel).left,
          greaterThanOrEqualTo(photo(tester).right));
      for (final text in ['Set 2026-11-20', 'Sit start, arête is in.']) {
        expect(find.descendant(of: panel, matching: find.text(text)),
            findsOneWidget);
      }
      expect(find.byIcon(Icons.expand_more), findsNothing,
          reason: 'the panel never folds');

      // Photos without marks are still dimmed in the column.
      final dim = tester.widget<Opacity>(find.descendant(
          of: find.byKey(ValueKey('strip-$kicker')),
          matching: find.byType(Opacity)));
      expect(dim.opacity, lessThan(1));
    });
  });

  group('lists are capped at 720 and centred', () {
    const desktop = Size(1200, 800);

    void capped(WidgetTester tester, Finder row, double window) {
      final r = tester.getRect(row);
      expect(r.width, window > 720 ? 720 : window);
      expect(r.center.dx, window / 2);
    }

    for (final width in [400.0, 1200.0]) {
      testApp('at $width dp: the wall list and the wall screen',
          (tester) async {
        await pumpApp(tester, db, size: Size(width, desktop.height));
        capped(tester, find.widgetWithText(ListTile, 'Home wall'), width);

        await goTo(tester, '/walls/$wall');
        capped(tester, find.byKey(ValueKey('problem-$problem')), width);
        final search = tester.getRect(
            find.byKey(const ValueKey('problem-search')));
        expect(search.left, tester.getRect(
                find.byKey(ValueKey('problem-$problem'))).left + 12,
            reason: 'the filter bar lines up with the rows');
      });
    }

    testApp('the scroll view stays window-wide, so the wheel works beside '
        'the column', (tester) async {
      await pumpApp(tester, db, size: desktop);
      expect(tester.getSize(find.byType(Scrollable).first).width, 1200);
    });
  });
}
