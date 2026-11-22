import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';

import 'helpers/test_db.dart';

/// A layout's wall photos: added in order, labelled, reordered, counted by
/// the problems that use them, and deleted only while no mark sits on them.
void main() {
  late AppDatabase db;
  late String      layout;
  setUp(() async {
    db     = openTestDb();
    layout = await currentLayoutId(db, await seedWall(db));
  });
  tearDown(() => db.close());

  Future<List<String?>> labels() async =>
      (await db.watchPhotos(layout).first).map((p) => p.label).toList();

  test('a photo stores its size and bytes, and goes to the end', () async {
    await seedPhoto(db, layout, label: 'Whole wall', width: 40, height: 30);
    final id = await seedPhoto(db, layout, label: 'Kicker', width: 30, height: 40);
    expect(await labels(), ['Whole wall', 'Kicker']);

    final photo = (await db.watchPhotos(layout).first).last;
    expect((photo.width, photo.height), (30, 40));
    final image = (await db.photoImage(id))!;
    expect(image.data, isNotEmpty);
    expect(image.thumb, isNotEmpty);
  });

  test('the thumbnail reads alone, and is the stored one', () async {
    final id = await seedPhoto(db, layout);
    expect(await db.photoThumb(id), (await db.photoImage(id))!.thumb);
    expect(await db.photoThumb('gone'), isNull);
  });

  test('labels are trimmed, and blank clears them', () async {
    final id = await seedPhoto(db, layout);
    await db.setPhotoLabel(id, '  Left half ');
    expect(await labels(), ['Left half']);
    await db.setPhotoLabel(id, '   ');
    expect(await labels(), [null]);
  });

  test('reordering persists', () async {
    final a = await seedPhoto(db, layout, label: 'A');
    final b = await seedPhoto(db, layout, label: 'B');
    final c = await seedPhoto(db, layout, label: 'C');
    await db.reorderPhotos([c, a, b]);
    expect(await labels(), ['C', 'A', 'B']);
  });

  test('usage counts problems, not marks', () async {
    final used   = await seedPhoto(db, layout);
    final unused = await seedPhoto(db, layout);
    await seedProblem(db, layout, name: 'Arête',
        marks: [(used, Role.start), (used, Role.hand)]);
    await seedProblem(db, layout, name: 'Crimps', marks: [(used, Role.foot)]);

    final usage = await db.watchPhotoUsage(layout).first;
    expect(usage[used], 2);
    expect(usage.containsKey(unused), isFalse);
  });

  test('an unused photo deletes, and undo restores identical rows', () async {
    await seedPhoto(db, layout, label: 'A');
    final b = await seedPhoto(db, layout, label: 'B');
    await seedPhoto(db, layout, label: 'C');
    final photosBefore = await db.select(db.wallPhotos).get();
    final bytesBefore  = await db.select(db.wallPhotoBytes).get();

    final deleted = await db.deletePhoto(b);
    expect(await labels(), ['A', 'C']);
    expect(await db.photoImage(b), isNull);

    await db.restorePhoto(deleted);
    expect(await labels(), ['A', 'B', 'C']);
    expect((await db.select(db.wallPhotos).get()).toSet(),
        photosBefore.toSet());
    expect((await db.select(db.wallPhotoBytes).get()).toSet(),
        bytesBefore.toSet());
  });

  test('a photo with marks is refused, naming the problems', () async {
    final photo = await seedPhoto(db, layout);
    await seedProblem(db, layout, name: 'Crimps', marks: [(photo, Role.hand)]);
    await seedProblem(db, layout, name: 'Arête',  marks: [(photo, Role.hand)]);
    final retired = await seedProblem(db, layout, name: 'Old one',
        marks: [(photo, Role.hand)]);
    // Retiring has no API until ticket 08.
    await (db.update(db.problems)..where((p) => p.id.equals(retired)))
        .write(const ProblemsCompanion(retiredOn: Value('2026-11-01')));

    await expectLater(
        db.deletePhoto(photo),
        throwsA(isA<PhotoInUse>().having((e) => e.problems, 'problems',
            ['Arête', 'Crimps', 'Old one'])));
    expect(await labels(), hasLength(1), reason: 'nothing was deleted');
  });
}
