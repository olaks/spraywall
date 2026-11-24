import 'dart:io';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spraywall/database/database.dart';

import 'generated_migrations/schema.dart';
import 'helpers/test_db.dart';

/// The migration chain is the one place a bug destroys data that no backup
/// inside the app can recover. The checks start at v1, so the first migration
/// already has a dumped schema to be tested against.
void main() {
  late Directory dir;
  late File file;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    dir  = Directory.systemTemp.createTempSync('spraywall_schema');
    file = File('${dir.path}/db.sqlite');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('a fresh database matches what the generated code expects', () async {
    final db = AppDatabase.forTesting(NativeDatabase(file));
    await db.validateDatabaseSchema();
    await db.close();
  });

  test('the dumped v1 schema matches a fresh install, indexes included',
      () async {
    // If this fails, the tables changed without a version bump and a dump:
    // schema v1 is frozen once a release carries it.
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema   = await verifier.schemaAt(1);
    final db       = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 1);
    await db.close();
  });

  test('the dumped v2 schema matches a fresh install', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema   = await verifier.schemaAt(2);
    final db       = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);
    await db.close();
  });

  test('v1 to v2 keeps every mark, as a circle', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final schema   = await verifier.schemaAt(1);
    schema.rawDatabase.execute('''
      INSERT INTO walls VALUES ('w', 'Home', 0, '2026-01-01', 0);
      INSERT INTO layouts VALUES ('l', 'w', NULL, '2026-01-01', NULL);
      INSERT INTO wall_photos VALUES ('p', 'l', 0, 2560, 1920, '2026-01-01', NULL);
      INSERT INTO wall_photo_bytes VALUES ('p', x'00', x'00');
      INSERT INTO problems VALUES ('q', 'l', 'Arête', '6B', '', '2026-01-02', NULL);
      INSERT INTO marks VALUES ('m1', 'q', 'p', 0, 0.25, 0.5, 0.02);
      INSERT INTO marks VALUES ('m2', 'q', 'p', 3, 0.75, 0.1, 0.03);
    ''');
    final db = AppDatabase.forTesting(schema.newConnection());
    await verifier.migrateAndValidate(db, 2);
    final marks = await db.marksOf('q');
    expect([for (final m in marks) (m.id, m.role, m.cx, m.cy, m.r, m.outline)], [
      ('m1', Role.start,  0.25, 0.5, 0.02, null),
      ('m2', Role.finish, 0.75, 0.1, 0.03, null),
    ]);
    await db.close();
  });

  test('a wall can have only one current layout', () async {
    final db     = openTestDb();
    final wallId = await seedWall(db);
    await expectLater(
      db.into(db.layouts).insert(
          LayoutsCompanion.insert(wallId: wallId, startedOn: '2026-11-22')),
      throwsA(isA<SqliteException>()),
    );
    // An archived one beside it is fine.
    await db.into(db.layouts).insert(LayoutsCompanion.insert(
        wallId: wallId, startedOn: '2026-01-01',
        endedOn: const Value('2026-11-21')));
    await db.close();
  });

  test('problem names are unique within a layout, ignoring ASCII case',
      () async {
    final db     = openTestDb();
    final wallId = await seedWall(db);
    final layout = await db.watchCurrentLayout(wallId).first;
    Future<void> add(String name) => db.into(db.problems).insert(
        ProblemsCompanion.insert(
            layoutId: layout!.id, name: name, setOn: '2026-11-22'));
    await add('Crimpy');
    await expectLater(add('CRIMPY'), throwsA(isA<SqliteException>()));
    await db.close();
  });
}
