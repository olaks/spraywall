import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/marks/mark_layer.dart';
import 'package:spraywall/marks/overlap.dart';

import 'helpers/app.dart';
import 'helpers/test_db.dart';

/// The overlap view: every problem in use drawn on the full-screen photo,
/// and a tapped mark's overlapping problems listed.
void main() {
  group('overlap', () {
    Mark mark(String problem, double cx, double cy,
            {double r = 0.05, String photo = 'p'}) =>
        Mark(id: newId(), problemId: problem, photoId: photo, role: Role.hand,
            cx: cx, cy: cy, r: r);
    // Wide, so x and y scale differently: r = 0.05 is 100 px.
    const photo = Size(2000, 1000);

    test('circles that cross or touch, compared in photo pixels', () {
      final a = mark('a', 0.5, 0.5);
      expect(marksOverlap(a, mark('b', 0.55, 0.5), photo), isTrue,
          reason: '100 px apart, radii 200');
      expect(marksOverlap(a, mark('b', 0.6, 0.5), photo), isTrue,
          reason: '200 px apart: touching');
      expect(marksOverlap(a, mark('b', 0.6001, 0.5), photo), isFalse);
      // 0.2 of the height is 200 px: touching, though 0.2 > 0.05 + 0.05.
      expect(marksOverlap(a, mark('b', 0.5, 0.7), photo), isTrue);
      expect(marksOverlap(a, mark('b', 0.5, 0.71), photo), isFalse);
      expect(marksOverlap(a, mark('b', 0.5, 0.5, r: 0.01), photo), isTrue,
          reason: 'one inside the other');
    });

    test('only on the same photo', () {
      expect(marksOverlap(mark('a', .5, .5), mark('b', .5, .5, photo: 'q'),
          photo), isFalse);
    });

    test("the other problems, each once, never the tapped mark's own", () {
      final tapped = mark('a', 0.5, 0.5);
      final marks  = [
        tapped,
        mark('a', 0.52, 0.5),   // its own problem's other mark
        mark('b', 0.53, 0.5),
        mark('b', 0.47, 0.5),   // b again
        mark('c', 0.9, 0.9),    // far away
        mark('d', 0.45, 0.45),
      ];
      expect(overlappingProblems(tapped, marks, photo), ['b', 'd']);
    });
  });

  group('the full-screen photo', () {
    late AppDatabase db;
    late String      wall;
    late String      photo;
    late Map<String, String> ids;   // problem name → id
    setUp(() async {
      db   = openTestDb();
      wall = await seedWall(db);
      final layout = await currentLayoutId(db, wall);
      photo = await seedPhoto(db, layout, width: 1600, height: 1200);
      final other = await seedPhoto(db, layout, label: 'Kicker');
      Future<String> problem(String name, String? grade, double cx, double cy,
              {String? on}) =>
          db.createProblem(
            layoutId: layout, name: name, grade: grade,
            setOn: DateTime(2026, 11, 22),
            marks: [(id: newId(), photoId: on ?? photo, role: Role.hand,
                     cx: cx, cy: cy, r: 0.02)],
          );
      ids = {
        'Arête':     await problem('Arête', '6B', 0.5,   0.5),
        // 56 px right of it, radii 32 + 32: overlapping.
        'Crimps':    await problem('Crimps', null, 0.535, 0.5),
        'Far':       await problem('Far', '5', 0.1, 0.1),
        'Retired':   await problem('Retired', '7A', 0.5, 0.5),
        'Elsewhere': await problem('Elsewhere', '6A', 0.5, 0.5, on: other),
      };
      await db.retireProblem(ids['Retired']!);
    });
    tearDown(() => db.close());

    MarkLayer? layer(WidgetTester tester) {
      final f = find.byType(MarkLayer);
      return f.evaluate().isEmpty ? null : tester.widget<MarkLayer>(f);
    }

    /// Zooms to 1:1 around photo pixel [at], where neighbouring marks'
    /// touch targets no longer overlap, and taps [by] pixels from it.
    Future<void> tapPhoto(WidgetTester tester, Offset at,
        {Offset by = Offset.zero}) async {
      final viewer = find.byType(InteractiveViewer);
      final centre = tester.getSize(viewer).center(Offset.zero);
      tester.widget<InteractiveViewer>(viewer).transformationController!.value =
          Matrix4.translationValues(centre.dx - at.dx, centre.dy - at.dy, 0);
      await tester.pump();
      await tester.tapAt(tester.getTopLeft(viewer) + centre + by);
      await tester.pumpAndSettle();
    }

    Future<void> open(WidgetTester tester) async {
      await pumpApp(tester, db);
      await goTo(tester, '/walls/$wall/photos/$photo');
    }

    testApp('Show problems draws the marks of problems in use on this photo',
        (tester) async {
      await open(tester);
      expect(layer(tester), isNull, reason: 'off to start with');

      await tester.tap(find.byTooltip('Show problems'));
      await tester.pumpAndSettle();
      expect(layer(tester)!.marks, hasLength(3),
          reason: 'not the retired one, nor the one on the kicker');
      expect(find.ancestor(of: find.byType(MarkLayer),
          matching: find.byType(Opacity)), findsOneWidget, reason: 'faint');

      await tester.tap(find.byTooltip('Hide problems'));
      await tester.pumpAndSettle();
      expect(layer(tester), isNull);
    });

    testApp('a tapped mark lists its problem and the overlapping ones, with '
        'grades; tapping one opens it', (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip('Show problems'));
      await tester.pumpAndSettle();
      // Arête's left side, clear of Crimps.
      await tapPhoto(tester, const Offset(800, 600), by: const Offset(-20, 0));

      expect(find.text('This mark'), findsOneWidget);
      final mine = find.byKey(ValueKey('overlap-${ids['Arête']}'));
      expect(find.descendant(of: mine, matching: find.text('6B')), findsOneWidget);
      expect(find.text('Overlapping marks'), findsOneWidget);
      final crimps = find.byKey(ValueKey('overlap-${ids['Crimps']}'));
      expect(find.descendant(of: crimps, matching: find.text('–')), findsOneWidget,
          reason: 'ungraded');
      for (final name in ['Far', 'Retired', 'Elsewhere']) {
        expect(find.text(name), findsNothing);
      }

      await tester.tap(crimps);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Problem menu'), findsOneWidget);
      expect(find.text('Crimps'), findsOneWidget);
    });

    testApp('a mark nothing else shares says so', (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip('Show problems'));
      await tester.pumpAndSettle();
      await tapPhoto(tester, const Offset(160, 120));
      expect(find.byKey(ValueKey('overlap-${ids['Far']}')), findsOneWidget);
      expect(find.text('No other problem has a mark here'), findsOneWidget);
    });
  });
}
