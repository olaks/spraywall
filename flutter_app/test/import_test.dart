import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/backup/backup_export.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/photos/photo_import.dart';

import 'helpers/app.dart';
import 'helpers/test_db.dart';

/// Import from Settings: the picked backup merged in, and a summary of what
/// happened, or why nothing did.
void main() {
  late AppDatabase db;
  late Uint8List   backup;
  setUp(() async {
    final source = openTestDb();
    final wall   = await seedWall(source, name: 'Gym');
    final layout = await currentLayoutId(source, wall);
    await seedProblem(source, layout, name: 'Arête');
    backup = await exportBackup(source);
    await source.close();

    db = openTestDb();
    await seedWall(db, name: 'Home wall');
  });
  tearDown(() => db.close());

  final result = find.byKey(const ValueKey('import-result'));

  Future<void> importFrom(WidgetTester tester, Uint8List? file) async {
    await pumpApp(tester, db, pickedFile: file);
    await goTo(tester, '/settings');
    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();
  }

  testApp('merges the backup and says what it added', (tester) async {
    await importFrom(tester, backup);
    expect(find.descendant(of: result, matching: find.text('Backup imported')),
        findsOneWidget);
    expect(find.text('Added 1 wall, 1 layout, 1 photo and 1 problem.'),
        findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(result, findsNothing);
    await goTo(tester, '/');
    expect(find.text('Gym'), findsOneWidget);
    expect(find.text('Home wall'), findsOneWidget);
  });

  testApp('thumbnails are made with progress showing', (tester) async {
    final held = Completer<void>();
    await pumpApp(tester, db, pickedFile: backup, thumbMaker: (data) async {
      await held.future;
      return makeThumb(data);
    });
    await goTo(tester, '/settings');
    await tester.tap(find.text('Import backup'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Making thumbnails (1 of 1)'), findsOneWidget);
    expect(tester.widget<LinearProgressIndicator>(find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(LinearProgressIndicator))).value, 0);

    held.complete();
    await tester.pumpAndSettle();
    expect(find.text('Making thumbnails (1 of 1)'), findsNothing);
    expect(find.text('Backup imported'), findsOneWidget);
  });

  testApp('a file that is not a backup: a readable error, and nothing '
      'changed', (tester) async {
    await importFrom(tester, Uint8List.fromList(utf8.encode('hello')));
    expect(find.descendant(of: result, matching: find.text('Import failed')),
        findsOneWidget);
    expect(find.textContaining("isn't a Spraywall backup"), findsOneWidget);
    expect(find.textContaining('Nothing was changed.'), findsOneWidget);
    expect(await tester.runAsync(() => db.watchWalls().first), hasLength(1));
  });

  testApp('backing out of the picker does nothing', (tester) async {
    await importFrom(tester, null);
    expect(result, findsNothing);
    expect(find.text('Importing backup'), findsNothing);
  });
}
