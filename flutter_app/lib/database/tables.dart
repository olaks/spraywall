import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Every primary key is a UUIDv7 string made on the device, so a row keeps its
/// id across backups and any later sync (docs/adr/0001-uuid-v7-ids.md).
String newId() => const Uuid().v7();

/// The system a wall's problems are graded in. Stored by index, written to
/// backups by name, so the order here is append-only.
enum GradeScale { font, v }

/// What a marked hold is for in its problem. Append-only, like [GradeScale].
enum Role { start, hand, foot, finish }

// Dates are `yyyy-MM-dd` text throughout: problems are set on a day, never at
// a time, and the text sorts the same way the dates do.
//
// No table cascades its deletes. Each delete clears the children itself and
// hands back a snapshot for undo (CODING_STANDARDS.md); a cascade would remove
// rows the snapshot never saw.

/// A physical wall. Names are unique ignoring case; the index only folds
/// ASCII, so the database layer also checks in Dart.
@TableIndex.sql('CREATE UNIQUE INDEX walls_name ON walls (name COLLATE NOCASE)')
class Walls extends Table {
  TextColumn get id         => text().clientDefault(newId)();
  TextColumn get name       => text()();
  IntColumn  get gradeScale => intEnum<GradeScale>()();
  TextColumn get createdOn  => text()();
  IntColumn  get sortOrder  => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A wall between two resets. `endedOn` null means current, and a wall has
/// exactly one current layout.
@TableIndex(name: 'layouts_wall', columns: {#wallId})
@TableIndex.sql('CREATE UNIQUE INDEX layouts_one_current ON layouts (wall_id) '
    'WHERE ended_on IS NULL')
class Layouts extends Table {
  TextColumn get id        => text().clientDefault(newId)();
  TextColumn get wallId    => text().references(Walls, #id)();
  TextColumn get name      => text().nullable()();
  TextColumn get startedOn => text()();
  TextColumn get endedOn   => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A photo's metadata, read by every list. The bytes live in
/// [WallPhotoBytes] so that only the widgets drawing a photo load them.
@TableIndex(name: 'wall_photos_layout', columns: {#layoutId})
class WallPhotos extends Table {
  TextColumn get id        => text().clientDefault(newId)();
  TextColumn get layoutId  => text().references(Layouts, #id)();
  IntColumn  get sortOrder => integer()();
  IntColumn  get width     => integer()();
  IntColumn  get height    => integer()();
  TextColumn get addedOn   => text()();
  TextColumn get label     => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The JPEG (2560 px long edge) and its 384 px thumbnail.
@DataClassName('WallPhotoImage')
class WallPhotoBytes extends Table {
  TextColumn get photoId => text().references(WallPhotos, #id)();
  BlobColumn get data    => blob()();
  BlobColumn get thumb   => blob()();

  @override
  Set<Column> get primaryKey => {photoId};
}

/// A named problem on a layout. Names are unique ignoring case within the
/// layout, retired problems included. `grade` is text from the wall's scale,
/// null while ungraded.
@TableIndex(name: 'problems_layout', columns: {#layoutId})
@TableIndex.sql('CREATE UNIQUE INDEX problems_name ON problems '
    '(layout_id, name COLLATE NOCASE)')
class Problems extends Table {
  TextColumn get id          => text().clientDefault(newId)();
  TextColumn get layoutId    => text().references(Layouts, #id)();
  TextColumn get name        => text()();
  TextColumn get grade       => text().nullable()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get setOn       => text()();
  TextColumn get retiredOn   => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A hold marked on one wall photo: a circle, or the hold's outline.
/// `cx`/`cy` are 0..1 of the photo's width and height; `r` is a fraction of
/// its **width**, so a circle stays round on a portrait photo. On an outline
/// mark they are the circle around the outline (docs/adr/0002-hold-outlines.md).
/// `outline` is null for a circle, otherwise its points as `x y x y …`, each
/// 0..1 of width or height (`lib/marks/outline.dart`). Marks draw in
/// insertion order.
@TableIndex(name: 'marks_problem', columns: {#problemId})
@TableIndex(name: 'marks_photo',   columns: {#photoId})
class Marks extends Table {
  TextColumn get id        => text().clientDefault(newId)();
  TextColumn get problemId => text().references(Problems, #id)();
  TextColumn get photoId   => text().references(WallPhotos, #id)();
  IntColumn  get role      => intEnum<Role>()();
  RealColumn get cx        => real()();
  RealColumn get cy        => real()();
  RealColumn get r         => real()();
  TextColumn get outline   => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
