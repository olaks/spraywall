import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/widgets/marked_thumb.dart';

import 'helpers/app.dart';
import 'helpers/test_db.dart';

/// The wall screen's problem list: rows, filters and sort, and the layout in
/// the app bar. The rules themselves are unit-tested in browse_test.dart;
/// these check the screen applies them and keeps them.
void main() {
  late AppDatabase db;
  late String      wall;
  late String      layout;
  late String      whole;
  late String      kicker;
  setUp(() async {
    db     = openTestDb();
    wall   = await seedWall(db, name: 'Home wall');
    layout = await currentLayoutId(db, wall);
    whole  = await seedPhoto(db, layout, label: 'Whole wall');
    kicker = await seedPhoto(db, layout, label: 'Kicker');
    await seedProblem(db, layout, name: 'Arête', grade: '7A',
        setOn: DateTime(2026, 11, 20), marks: [(kicker, Role.start)]);
    await seedProblem(db, layout, name: 'crimps', grade: '6B',
        setOn: DateTime(2026, 11, 2),
        marks: [(kicker, Role.start), (whole, Role.finish)]);
    await seedProblem(db, layout, name: 'Project',
        setOn: DateTime(2026, 11, 21), marks: [(whole, Role.hand)]);
  });
  tearDown(() => db.close());

  Future<void> openWall(WidgetTester tester) async {
    await pumpApp(tester, db);
    await goTo(tester, '/walls/$wall');
  }

  /// Problem names, top to bottom.
  List<String> rows(WidgetTester tester) => [
        for (final tile in tester.widgetList<ListTile>(find.byType(ListTile)))
          (tile.title! as Text).data!,
      ];

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const ValueKey('problem-search')), text);
    await tester.pump();
  }

  testApp('rows show name, grade, set date and the first marked photo, with '
      'its marks', (tester) async {
    await openWall(tester);
    final row = find.ancestor(
        of: find.text('crimps'), matching: find.byType(ListTile));
    expect(find.descendant(of: row, matching: find.text('6B')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('Set 2026-11-02')),
        findsOneWidget);

    final thumb = tester.widget<MarkedThumb>(
        find.descendant(of: row, matching: find.byType(MarkedThumb)));
    expect(thumb.photo.id, whole, reason: 'first in the layout order');
    expect(thumb.marks.map((m) => m.role), [Role.finish],
        reason: "only that photo's marks");

    final project = find.ancestor(
        of: find.text('Project'), matching: find.byType(ListTile));
    expect(find.descendant(of: project, matching: find.text('–')),
        findsOneWidget, reason: 'ungraded');
  });

  testApp('the app bar shows an unnamed layout\'s start date',
      (tester) async {
    final started = (await db.layout(layout))!.startedOn;
    await openWall(tester);
    expect(find.text('Since $started'), findsOneWidget);
  });

  testApp("the app bar shows the layout's name when it has one",
      (tester) async {
    // Naming a layout has no API until ticket 09.
    await (db.update(db.layouts)..where((l) => l.id.equals(layout)))
        .write(const LayoutsCompanion(name: Value('Autumn set')));
    await openWall(tester);
    expect(find.text('Autumn set'), findsOneWidget);
    expect(find.textContaining('Since'), findsNothing);
  });

  testApp('sorts by grade with ungraded last, or by newest', (tester) async {
    await openWall(tester);
    expect(rows(tester), ['crimps', 'Arête', 'Project']);
    await tester.tap(find.text('Newest'));
    await tester.pumpAndSettle();
    expect(rows(tester), ['Project', 'Arête', 'crimps']);
  });

  testApp('the name filter, and a search with no match offers to clear',
      (tester) async {
    await openWall(tester);
    await search(tester, 'RIM');
    expect(rows(tester), ['crimps']);

    await search(tester, 'zzz');
    expect(find.text('No problems match'), findsOneWidget);
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(rows(tester), hasLength(3));
    expect(find.widgetWithText(TextField, 'zzz'), findsNothing,
        reason: 'the field empties too');
  });

  testApp('a grade range hides ungraded problems; the whole scale is any '
      'grade', (tester) async {
    await openWall(tester);
    await tester.tap(find.text('Any grade'));
    await tester.pumpAndSettle();
    // Set the range directly, like zoom: dragging slider thumbs to an exact
    // grade is a test of Flutter's slider, not of this screen.
    final slider = tester.widget<RangeSlider>(
        find.byKey(const ValueKey('grade-range')));
    slider.onChanged!(const RangeValues(7, 11)); // 6B – 7A on Font
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('6B – 7A'), findsOneWidget, reason: 'the chip says so');
    expect(rows(tester), ['crimps', 'Arête']);

    await tester.tap(find.text('6B – 7A'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Any grade'));
    await tester.pumpAndSettle();
    expect(rows(tester), hasLength(3));
  });

  testApp('filters and sort are kept in memory, not the URL, across opening '
      'a problem', (tester) async {
    await openWall(tester);
    await tester.tap(find.text('Newest'));
    await tester.pumpAndSettle();
    await search(tester, 'r');
    expect(rows(tester), ['Project', 'Arête', 'crimps']);

    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    expect(router.state.uri.toString(), '/walls/$wall');

    await tester.tap(find.text('Arête'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await search(tester, 'rim');
    expect(rows(tester), ['crimps']);
    await search(tester, '');
    expect(rows(tester), ['Project', 'Arête', 'crimps'],
        reason: 'still sorted by newest');
  });
}
