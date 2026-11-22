import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/backup/backup_export.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/providers/backup_provider.dart';

import 'helpers/test_db.dart';

/// The backup zip: `backup.json` with the rows nested and the photos beside
/// it, and the reminder that only a full export resets.
void main() {
  final now = DateTime.utc(2026, 11, 22, 9, 30);

  group('export', () {
    late AppDatabase db;
    late String      home;
    late String      first;
    late String      current;
    late String      photo;
    late String      labelled;
    late String      arete;
    setUp(() async {
      db       = openTestDb();
      home     = await seedWall(db, name: 'Home wall', today: DateTime(2026, 9, 1));
      first    = await currentLayoutId(db, home);
      photo    = await seedPhoto(db, first);
      labelled = await seedPhoto(db, first, label: 'Kicker');
      arete    = await seedProblem(db, first, name: 'Arête', grade: '6B',
          marks: [(labelled, Role.finish), (photo, Role.start), (photo, Role.hand)]);
      await seedProblem(db, first, name: 'Crimps', marks: [(photo, Role.foot)]);
      await db.retireProblem(arete, today: DateTime(2026, 10, 1));
      await db.resetLayout(home, name: 'Winter', startedOn: DateTime(2026, 11, 1));
      current  = await currentLayoutId(db, home);
      await seedWall(db, name: 'Gym', gradeScale: GradeScale.v);
    });
    tearDown(() => db.close());

    Future<(Map<String, dynamic>, Archive)> open({String? wallId}) async {
      final zip  = ZipDecoder().decodeBytes(
          await exportBackup(db, wallId: wallId, now: now));
      final json = jsonDecode(utf8.decode(
          zip.findFile(backupJsonName)!.content as List<int>));
      return (json as Map<String, dynamic>, zip);
    }

    test('backup.json: version, exportedAt, and walls in list order', () async {
      final (json, _) = await open();
      expect(json['version'], 1);
      expect(json['exportedAt'], '2026-11-22T09:30:00.000Z');
      expect([for (final w in json['walls']) w['name']], ['Home wall', 'Gym']);
    });

    test('rows nest under their parents, with ids, enums by name, and null '
        'fields left out', () async {
      final (json, _) = await open();
      final wall = json['walls'][0];
      expect(wall, containsPair('id', home));
      expect(wall['gradeScale'], 'font');
      expect(json['walls'][1]['gradeScale'], 'v');

      final layouts = wall['layouts'] as List;
      expect([for (final l in layouts) l['id']], [first, current],
          reason: 'archived first, by start date');
      expect(layouts[0]['endedOn'], '2026-11-01');
      expect(layouts[0].containsKey('name'), isFalse, reason: 'null: left out');
      expect(layouts[1]['name'], 'Winter');
      expect(layouts[1].containsKey('endedOn'), isFalse);

      final photos = layouts[0]['photos'] as List;
      expect([for (final p in photos) p['id']], [photo, labelled]);
      expect(photos[0].containsKey('label'), isFalse);
      expect(photos[1]['label'], 'Kicker');
      expect(photos[0].keys, containsAll(['sortOrder', 'width', 'height', 'addedOn']));

      final problems = layouts[0]['problems'] as List;
      final a = problems.firstWhere((p) => p['id'] == arete);
      expect(a['grade'], '6B');
      expect(a['retiredOn'], '2026-10-01', reason: 'retired problems go too');
      expect(a['description'], '');
      final c = problems.firstWhere((p) => p['name'] == 'Crimps');
      expect(c.containsKey('grade'), isFalse);
      expect(c.containsKey('retiredOn'), isFalse);

      final marks = a['marks'] as List;
      expect([for (final m in marks) m['role']], ['finish', 'start', 'hand'],
          reason: 'drawing order, roles by name');
      expect(marks[0], allOf(containsPair('photoId', labelled),
          contains('id'), contains('cx'), contains('cy'), contains('r')));
    });

    test('each photo is stored byte for byte, uncompressed, and nothing '
        'else: no thumbnails', () async {
      final (_, zip) = await open();
      expect([for (final f in zip.files) f.name]..sort(),
          [backupJsonName, backupPhotoName(photo), backupPhotoName(labelled)]
            ..sort());
      for (final id in [photo, labelled]) {
        final f = zip.findFile(backupPhotoName(id))!;
        expect(f.compression, CompressionType.none);
        expect(Uint8List.fromList(f.content as List<int>),
            (await db.photoImage(id))!.data);
      }
    });

    test('one wall: only it, with all its layouts', () async {
      final (json, zip) = await open(wallId: home);
      expect([for (final w in json['walls']) w['name']], ['Home wall']);
      expect(json['walls'][0]['layouts'], hasLength(2));
      expect(zip.files, hasLength(3));

      final gym = (await db.watchWalls().first).last.id;
      final (gymJson, gymZip) = await open(wallId: gym);
      expect(gymJson['walls'][0]['layouts'][0]['photos'], isEmpty);
      expect(gymZip.files, hasLength(1));
    });
  });

  test('reading a backup runs no more statements for 200 marks than for 5',
      () async {
    Future<int> statements(int marks) async {
      final counter = StatementCounter();
      final db      = openTestDb(interceptor: counter);
      final wall    = await seedWall(db);
      final layout  = await currentLayoutId(db, wall);
      final photo   = await seedPhoto(db, layout);
      for (var i = 0; i < marks ~/ 5; i++) {
        await seedProblem(db, layout, name: 'P$i',
            marks: [for (var j = 0; j < 5; j++) (photo, Role.hand)]);
      }
      counter.count = 0;
      await exportBackup(db, now: now);
      await db.close();
      return counter.count;
    }

    expect(await statements(200), await statements(5));
  });

  test('file names: the date, and the wall name kept to safe characters', () {
    expect(backupFileName(now), 'spraywall-2026-11-22.zip');
    expect(backupFileName(now, wallName: 'Home wall'),
        'spraywall-Home_wall-2026-11-22.zip');
    expect(backupFileName(now, wallName: ' Arête / Ø '),
        'spraywall-Arête_Ø-2026-11-22.zip');
  });

  group('reminder', () {
    final today = DateTime(2026, 11, 22);
    String daysAgo(int n) {
      final d = today.subtract(Duration(days: n));
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    }

    test('nudges when never backed up, or a month or more ago', () {
      expect(const BackupStatus().needsReminder(today), isTrue);
      expect(BackupStatus(lastBackup: daysAgo(29)).needsReminder(today), isFalse);
      expect(BackupStatus(lastBackup: daysAgo(30)).needsReminder(today), isTrue);
    });

    test('a dismissal keeps it quiet for a week', () {
      expect(BackupStatus(snoozedOn: daysAgo(6)).needsReminder(today), isFalse);
      expect(BackupStatus(snoozedOn: daysAgo(7)).needsReminder(today), isTrue);
    });

    test('the status in plain words', () {
      String text(String? last, {bool hasData = true}) => backupStatusText(
          BackupStatus(lastBackup: last), today, hasData: hasData);
      expect(text(null), startsWith('Never backed up.'));
      expect(text(null, hasData: false), 'No walls yet: nothing to back up.');
      expect(text(daysAgo(0)),  'Backed up today.');
      expect(text(daysAgo(1)),  'Backed up yesterday.');
      expect(text(daysAgo(12)), 'Backed up 12 days ago.');
      expect(text(daysAgo(40)), startsWith('Last backup was 40 days ago.'));
    });
  });
}
