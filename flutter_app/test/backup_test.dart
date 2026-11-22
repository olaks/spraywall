import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/backup/backup_export.dart';
import 'package:spraywall/database/database.dart';

import 'helpers/app.dart';
import 'helpers/test_db.dart';

/// Exporting from Settings and from Edit wall, and the reminder on the wall
/// list, with the clock injected.
void main() {
  late AppDatabase db;
  late String      wall;
  late FakeShare   share;
  late DateTime    now;
  setUp(() async {
    db    = openTestDb();
    wall  = await seedWall(db, name: 'Home wall');
    await seedPhoto(db, await currentLayoutId(db, wall));
    share = FakeShare();
    now   = DateTime(2026, 11, 22, 10);
  });
  tearDown(() => db.close());

  Future<void> start(WidgetTester tester) =>
      pumpApp(tester, db, share: share, clock: () => now);

  /// Moves the clock on and reopens the app, over what it stored.
  Future<void> later(WidgetTester tester, int days) async {
    now = now.add(Duration(days: days));
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, db, share: share, clock: () => now, keepPrefs: true);
  }

  final nudge = find.byKey(const ValueKey('backup-nudge'));
  String status(WidgetTester tester) => tester
      .widget<Text>(find.descendant(
          of: find.byKey(const ValueKey('backup-status')),
          matching: find.byType(Text)))
      .data!;

  Map<String, dynamic> backupIn(FakeShare share) => jsonDecode(utf8.decode(
      ZipDecoder().decodeBytes(share.files.single.bytes)
          .findFile(backupJsonName)!.content as List<int>)) as Map<String, dynamic>;

  testApp('never backed up: the wall list nudges, and Remind me later '
      'quiets it for a week', (tester) async {
    await start(tester);
    expect(nudge, findsOneWidget);
    expect(find.text('Your walls have never been backed up.'), findsOneWidget);

    await tester.tap(find.byTooltip('Remind me later'));
    await tester.pumpAndSettle();
    expect(nudge, findsNothing);

    await later(tester, 6);
    expect(nudge, findsNothing, reason: 'six days on');
    await later(tester, 1);
    expect(nudge, findsOneWidget, reason: 'a week on');
  });

  testApp('Export everything hands over a zip of every wall and resets the '
      'reminder for a month', (tester) async {
    await seedWall(db, name: 'Gym');
    await start(tester);
    await goTo(tester, '/settings');
    expect(status(tester), startsWith('Never backed up.'));

    await tester.tap(find.text('Export everything'));
    await tester.pumpAndSettle();
    final file = share.files.single;
    expect((file.name, file.mimeType),
        ('spraywall-2026-11-22.zip', 'application/zip'));
    expect([for (final w in backupIn(share)['walls']) w['name']],
        ['Home wall', 'Gym']);
    expect(find.text('Backup exported'), findsOneWidget);
    expect(status(tester), 'Backed up today.');

    await goTo(tester, '/');
    expect(nudge, findsNothing);
    await later(tester, 29);
    expect(nudge, findsNothing);
    await later(tester, 1);
    expect(find.text('Last backup was 30 days ago.'), findsOneWidget);
  });

  testApp('backing out of the save dialog or share sheet is no backup',
      (tester) async {
    share.backOut = true;
    await start(tester);
    await goTo(tester, '/settings');
    await tester.tap(find.text('Export everything'));
    await tester.pumpAndSettle();
    expect(share.files, hasLength(1));
    expect(find.text('Backup exported'), findsNothing);
    expect(status(tester), startsWith('Never backed up.'));
  });

  testApp("Export this wall hands over that wall alone, and doesn't reset "
      'the reminder', (tester) async {
    await seedWall(db, name: 'Gym');
    await start(tester);
    await goTo(tester, '/walls/$wall');
    await tester.tap(find.byTooltip('Wall menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit wall'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export this wall'));
    await tester.pumpAndSettle();

    expect(share.files.single.name, 'spraywall-Home_wall-2026-11-22.zip');
    expect([for (final w in backupIn(share)['walls']) w['name']], ['Home wall']);
    expect(find.text('Exported "Home wall"'), findsOneWidget);

    await goTo(tester, '/');
    expect(nudge, findsOneWidget, reason: 'the other walls are unprotected');
  });

  testApp('with no walls there is nothing to back up or nudge about',
      (tester) async {
    final empty = openTestDb();
    addTearDown(empty.close);
    await pumpApp(tester, empty, share: share, clock: () => now);
    expect(nudge, findsNothing);
    await goTo(tester, '/settings');
    expect(status(tester), 'No walls yet: nothing to back up.');
    expect(tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Export everything')).enabled, isFalse);
  });
}
