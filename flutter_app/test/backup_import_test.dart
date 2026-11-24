import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show BooleanExpressionOperators, Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:spraywall/backup/backup_export.dart';
import 'package:spraywall/backup/backup_import.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/photos/photo_import.dart';

import 'helpers/test_db.dart';

/// Import: the backup checked in full before anything is written, then
/// merged by id with the device winning, in one transaction.
void main() {
  final now = DateTime.utc(2026, 11, 22, 9, 30);

  /// Checks and merges [zip] into [db], as Settings does.
  Future<ImportSummary> import(AppDatabase db, Uint8List zip) async {
    final rows  = parseBackup(zip);
    final fresh = await db.newPhotoIds([for (final p in rows.photos) p.id]);
    return db.importBackup(rows, {
      for (final id in fresh) id: makeThumb(rows.photoData[id]!),
    });
  }

  /// Every row of every table, thumbnails aside (import makes its own).
  Future<Set<Object>> rows(AppDatabase db) async => {
        ...await db.select(db.walls).get(),
        ...await db.select(db.layouts).get(),
        ...await db.select(db.wallPhotos).get(),
        for (final b in await db.select(db.wallPhotoBytes).get())
          (b.photoId, base64.encode(b.data)),
        ...await db.select(db.problems).get(),
        ...await db.select(db.marks).get(),
      };

  /// [zip] with its backup.json changed by [edit], an entry [drop]ped, and
  /// entries [add]ed.
  Uint8List rezip(Uint8List zip, {
    void Function(Map<String, dynamic> json)? edit,
    String?                                   drop,
    Map<String, List<int>>                    add = const {},
  }) {
    final from = ZipDecoder().decodeBytes(zip);
    final json = jsonDecode(utf8.decode(
        from.findFile(backupJsonName)!.content)) as Map<String, dynamic>;
    edit?.call(json);
    final out = Archive()
      ..add(ArchiveFile.string(backupJsonName, jsonEncode(json)));
    for (final f in from.files) {
      if (f.name != backupJsonName && f.name != drop) {
        out.add(ArchiveFile.noCompress(f.name, f.size, f.content));
      }
    }
    for (final MapEntry(key: name, value: bytes) in add.entries) {
      out.add(ArchiveFile.noCompress(name, bytes.length, bytes));
    }
    return ZipEncoder().encodeBytes(out);
  }

  const outline = '0.1000 0.2000 0.3000 0.2000 0.2000 0.4000';

  late AppDatabase source;
  late String      home;
  late String      first;
  late String      photo;
  late String      arete;
  late Uint8List   backup;
  setUp(() async {
    source = openTestDb();
    home   = await seedWall(source, name: 'Home wall', today: DateTime(2026, 9, 1));
    first  = await currentLayoutId(source, home);
    // Bigger than a thumbnail, so a regenerated one is visibly smaller.
    photo  = await seedPhoto(source, first, width: 1000, height: 750);
    final kicker = await seedPhoto(source, first, label: 'Kicker');
    arete  = await seedProblem(source, first, name: 'Arête', grade: '6B',
        marks: [(kicker, Role.finish), (photo, Role.start), (photo, Role.hand)]);
    await seedProblem(source, first, name: 'Crimps', marks: [(photo, Role.foot)]);
    // One mark is a hold's outline (backup version 2).
    await source.customStatement('UPDATE marks SET outline = ? WHERE id = '
        '(SELECT id FROM marks ORDER BY rowid LIMIT 1)', [outline]);
    await source.retireProblem(arete, today: DateTime(2026, 10, 1));
    await source.resetLayout(home, name: 'Winter', startedOn: DateTime(2026, 11, 1));
    final winter = await currentLayoutId(source, home);
    await seedProblem(source, winter, name: 'Slab');
    await seedWall(source, name: 'Gym', gradeScale: GradeScale.v);
    backup = await exportBackup(source, now: now);
  });
  tearDown(() => source.close());

  group('round trip', () {
    late AppDatabase target;
    setUp(() => target = openTestDb());
    tearDown(() => target.close());

    test('into an empty app: identical rows and byte-identical photos, '
        'marks in drawing order, thumbnails made', () async {
      final summary = await import(target, backup);
      expect(await rows(target), await rows(source));
      expect((await target.watchLayoutMarks(first).first).map((m) => m.id),
          (await source.watchLayoutMarks(first).first).map((m) => m.id));

      final thumb = img.decodeJpg((await target.photoImage(photo))!.thumb)!;
      expect((thumb.width, thumb.height), (kThumbLongEdge, 288),
          reason: 'made again from the photo');
      expect((summary.added.walls, summary.added.layouts, summary.added.photos,
              summary.added.problems), (2, 3, 3, 3));
      expect(summary.renamed, isEmpty);
    });

    test('importing it again changes nothing', () async {
      await import(target, backup);
      final before = await rows(target);
      final again  = await import(target, backup);
      expect(await rows(target), before);
      expect(importSummaryLines(again).first,
          'Nothing new: everything in it was already here.');
      expect(again.alreadyHere.problems, 3);
    });
  });

  group('version 1, from before hold outlines', () {
    test('imports, every mark a circle', () async {
      final v1 = rezip(backup, edit: (j) {
        j['version'] = 1;
        for (final w in j['walls']) {
          for (final l in w['layouts']) {
            for (final p in l['problems']) {
              for (final m in p['marks']) {
                (m as Map).remove('outline');
              }
            }
          }
        }
      });
      final target = openTestDb();
      addTearDown(target.close);
      await import(target, v1);
      final marks = await target.select(target.marks).get();
      expect(marks, hasLength((await source.select(source.marks).get()).length));
      expect(marks.map((m) => m.outline), everyElement(isNull));
    });
  });

  test('an outline is written as numbers, and a circle has none', () async {
    final json = jsonDecode(utf8.decode(ZipDecoder().decodeBytes(backup)
        .findFile(backupJsonName)!.content)) as Map<String, dynamic>;
    final marks = [
      for (final w in json['walls'])
        for (final l in w['layouts'])
          for (final p in l['problems'])
            for (final m in p['marks']) m as Map<String, dynamic>,
    ];
    expect(marks.where((m) => m.containsKey('outline')).single['outline'],
        [0.1, 0.2, 0.3, 0.2, 0.2, 0.4]);
  });

  test('200 marks cost no more statements than 5', () async {
    Future<int> statements(int marks) async {
      final from   = openTestDb();
      final wall   = await seedWall(from);
      final layout = await currentLayoutId(from, wall);
      final p      = await seedPhoto(from, layout);
      for (var i = 0; i < marks ~/ 5; i++) {
        await seedProblem(from, layout, name: 'P$i',
            marks: [for (var j = 0; j < 5; j++) (p, Role.hand)]);
      }
      final zip = await exportBackup(from, now: now);
      await from.close();

      final counter = StatementCounter();
      final to      = openTestDb(interceptor: counter);
      final rows    = parseBackup(zip);
      final thumbs  = {for (final p in rows.photos) p.id: makeThumb(rows.photoData[p.id]!)};
      await to.importBackup(rows, thumbs);
      await to.close();
      return counter.count;
    }

    expect(await statements(200), await statements(5));
  });

  group('checked before anything is written', () {
    void refused(Uint8List zip, String message) =>
        expect(() => parseBackup(zip), throwsA(isA<BackupError>()
            .having((e) => e.message, 'message', contains(message))));

    Map<String, dynamic> firstProblem(Map<String, dynamic> json) =>
        json['walls'][0]['layouts'][0]['problems'][0] as Map<String, dynamic>;

    test('not a zip, or no backup.json', () {
      // A decoder that finds no zip in it sees an empty one.
      refused(Uint8List.fromList(utf8.encode('hello')),
          "isn't a Spraywall backup");
      refused(ZipEncoder().encodeBytes(Archive()
          ..add(ArchiveFile.string('other.txt', 'x'))), 'has no backup.json');
    });

    test('bad JSON', () {
      final zip = ZipEncoder().encodeBytes(Archive()
        ..add(ArchiveFile.string(backupJsonName, '{"version": 1, "walls": [')));
      refused(zip, "isn't valid JSON");
    });

    test('a newer version is refused clearly; an unknown one is damage', () {
      refused(rezip(backup, edit: (j) => j['version'] = 3),
          'made by a newer version of Spraywall (format 3)');
      refused(rezip(backup, edit: (j) => j['version'] = 0), 'damaged');
      refused(rezip(backup, edit: (j) => j.remove('version')),
          'backup has no version');
    });

    test('a missing photo', () {
      refused(rezip(backup, drop: backupPhotoName(photo)),
          'the photo photos/$photo.jpg is missing');
    });

    test("a dangling id, or a mark on another layout's photo", () {
      refused(rezip(backup, edit: (j) =>
              firstProblem(j)['marks'][0]['photoId'] = newId()),
          "not in its problem's layout");
      final other = rezip(backup, edit: (j) {
        final layouts = j['walls'][0]['layouts'];
        final there   = layouts[1]['problems'][0]['marks'][0];
        there['photoId'] = layouts[0]['photos'][0]['id'];
      });
      refused(other, "not in its problem's layout");
    });

    test('wrong kinds, unknown enums, ids twice, two current layouts', () {
      refused(rezip(backup, edit: (j) => firstProblem(j)['name'] = 7),
          'problems[0] has a name of the wrong kind');
      refused(rezip(backup, edit: (j) =>
          firstProblem(j)['marks'][0]['role'] = 'crimp'), 'unknown role "crimp"');
      refused(rezip(backup, edit: (j) =>
          j['walls'][1]['id'] = j['walls'][0]['id']), 'appears twice');
      refused(rezip(backup, edit: (j) =>
          j['walls'][0]['layouts'][0].remove('endedOn')), 'two current layouts');
      for (final bad in <Object>[[0.1, 0.2, 0.3, 0.4], [0.1, 0.2, 0.3, 0.4, 0.5],
                                 [0.1, 0.2, 0.3, 0.4, 0.5, 1.5], 'x']) {
        refused(rezip(backup, edit: (j) =>
                firstProblem(j)['marks'][0]['outline'] = bad),
            bad is String ? 'outline of the wrong kind' : 'not a list of points');
      }
    });

    test('an id here under another parent rolls everything back', () async {
      final target = openTestDb();
      addTearDown(target.close);
      final wall   = await seedWall(target, name: 'Mine');
      // The backup's photo id, here in a different layout.
      await target.into(target.wallPhotos).insert(WallPhotosCompanion.insert(
          id: Value(photo), layoutId: await currentLayoutId(target, wall),
          sortOrder: 0, width: 4, height: 3, addedOn: '2026-11-22'));
      final before = await rows(target);
      await expectLater(import(target, backup), throwsA(isA<BackupClash>()));
      expect(await rows(target), before);
    });
  });

  group('merge', () {
    late AppDatabase target;
    setUp(() async {
      target = openTestDb();
      await import(target, backup);
    });
    tearDown(() => target.close());

    test('the device wins, and the problem is the unit', () async {
      // Edited here since: renamed, and down to one mark.
      await (target.update(target.problems)..where((p) => p.id.equals(arete)))
          .write(const ProblemsCompanion(name: Value('Arête sit')));
      final keep = (await target.marksOf(arete)).first;
      await (target.delete(target.marks)..where((m) => m.id.equals(keep.id).not()
          & m.problemId.equals(arete))).go();

      final summary = await import(target, backup);
      expect((await target.select(target.problems)
              .get()).firstWhere((p) => p.id == arete).name, 'Arête sit');
      expect((await target.marksOf(arete)).map((m) => m.id), [keep.id],
          reason: "an existing problem's marks are skipped");
      expect(summary.added.problems, 0);
    });

    test("new walls with a taken name become (2), (3), and go after the "
        "device's", () async {
      final other = openTestDb();
      addTearDown(other.close);
      await seedWall(other, name: 'HOME WALL');
      final zip = rezip(await exportBackup(other, now: now), edit: (j) {
        j['walls'].add({...j['walls'][0], 'id': newId(), 'name': 'home wall',
            'layouts': <Object>[]});
      });
      final summary = await import(target, zip);
      expect([for (final w in await target.watchWalls().first) w.name],
          ['Home wall', 'Gym', 'HOME WALL (2)', 'home wall (3)']);
      expect(summary.renamed, [('HOME WALL', 'HOME WALL (2)'),
                               ('home wall', 'home wall (3)')]);
    });

    test("a new problem in a layout that's here: renamed if taken, and its "
        'photos go after the layout\'s own', () async {
      final newPhoto = newId();
      final jpeg     = (await source.photoImage(photo))!.data;
      final zip = rezip(backup, add: {backupPhotoName(newPhoto): jpeg}, edit: (j) {
        final layout = j['walls'][0]['layouts'][0];
        layout['photos'] = [{...layout['photos'][0], 'id': newPhoto, 'sortOrder': 0}];
        layout['problems'] = [{
          'id': newId(), 'name': 'arête', 'description': '', 'setOn': '2026-11-22',
          'marks': [{'id': newId(), 'photoId': newPhoto, 'role': 'hand',
                     'cx': 0.5, 'cy': 0.5, 'r': 0.02}],
        }];
      });

      final summary = await import(target, zip);
      expect(summary.renamed, [('arête', 'arête (2)')]);
      final orders = [for (final p in await target.watchPhotos(first).first) p.sortOrder];
      expect(orders, [0, 1, 2], reason: 'after the two already here');
    });

    group('two current layouts on one wall', () {
      Uint8List current(String startedOn) => rezip(backup, edit: (j) {
            final wall = j['walls'][0];
            wall['layouts'] = [{
              'id': newId(), 'startedOn': startedOn,
              'photos': <Object>[], 'problems': <Object>[],
            }];
          });
      Future<List<Layout>> layoutsOfHome() =>
          (target.select(target.layouts)..where((l) => l.wallId.equals(home))).get();

      test('the later one stays current, the other ends on its date',
          () async {
        final here    = await currentLayoutId(target, home);
        final summary = await import(target, current('2026-12-01'));
        final now     = await currentLayoutId(target, home);
        expect(now, isNot(here));
        expect((await layoutsOfHome()).firstWhere((l) => l.id == here).endedOn,
            '2026-12-01');
        expect(summary.archived, 1);
      });

      test("an earlier one, or the same day, is archived and the device's "
          'stays current', () async {
        final here = await currentLayoutId(target, home);
        for (final day in ['2026-10-01', '2026-11-01']) {
          final summary = await import(target, current(day));
          expect(await currentLayoutId(target, home), here);
          expect(summary.archived, 1);
        }
        final ended = (await layoutsOfHome())
            .where((l) => l.id != here && l.id != first);
        expect(ended.map((l) => l.endedOn), everyElement('2026-11-01'),
            reason: "ended on the date the device's started");
      });
    });

    test("a grade off the wall's scale imports ungraded", () async {
      // Here, the wall has moved to V grades since the backup.
      await (target.update(target.walls)..where((w) => w.id.equals(home)))
          .write(const WallsCompanion(gradeScale: Value(GradeScale.v)));
      final zip = rezip(backup, edit: (j) {
        final layout = j['walls'][0]['layouts'][1];
        layout['problems'].add({
          ...layout['problems'][0], 'id': newId(), 'name': 'Graded',
          'grade': '6B', 'marks': <Object>[],
        });
      });
      final summary = await import(target, zip);
      final graded = (await target.select(target.problems).get())
          .firstWhere((p) => p.name == 'Graded');
      expect(graded.grade, isNull);
      expect(summary.ungraded, 1);
    });
  });

  test('the summary in plain words', () {
    expect(importSummaryLines(const ImportSummary(
      added:       BackupCounts(walls: 1, layouts: 2, photos: 1, problems: 12),
      alreadyHere: BackupCounts(problems: 3),
      renamed:     [('Home wall', 'Home wall (2)')],
      ungraded:    2,
      archived:    1,
    )), [
      'Added 1 wall, 2 layouts, 1 photo and 12 problems.',
      'Already here, so left as they are: 3 problems.',
      'Renamed "Home wall" to "Home wall (2)": the name was taken.',
      "Made 2 problems ungraded: their grades aren't on the wall's grade scale.",
      'Archived 1 layout: a wall had two current layouts, and the later one '
          'stays current.',
    ]);
  });
}
