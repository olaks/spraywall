import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import '../database/database.dart';
import '../utils/format_utils.dart';

/// The backup format this app writes. Import refuses a newer one.
const backupVersion = 1;

/// The zip's entries: the rows, and each photo by its id.
const backupJsonName = 'backup.json';
String backupPhotoName(String photoId) => 'photos/$photoId.jpg';

/// A backup of everything, or of the wall [wallId] with all its layouts: a
/// zip of [backupJsonName] and each photo's stored JPEG, uncompressed (a
/// JPEG doesn't shrink, and storing skips the work). No thumbnails.
Future<Uint8List> exportBackup(
  AppDatabase db, {
  String?   wallId,
  DateTime? now,
}) async {
  final rows    = await db.backupRows(wallId: wallId);
  final json    = backupJson(rows, now ?? DateTime.now());
  final archive = Archive()
    ..add(ArchiveFile.string(backupJsonName,
        const JsonEncoder.withIndent(' ').convert(json)));
  for (final p in rows.photos) {
    final data = rows.photoData[p.id]!;
    archive.add(ArchiveFile.noCompress(backupPhotoName(p.id), data.length, data));
  }
  return ZipEncoder().encodeBytes(archive);
}

/// The rows as `backup.json`: `version` and `exportedAt` on top, children
/// nested under their parents (wall → layouts → photos and problems,
/// problem → marks), every row with its id, enums by name, and fields that
/// are null left out. Marks keep their drawing order.
Map<String, Object?> backupJson(BackupRows rows, DateTime exportedAt) {
  Map<String, Object?> some(Map<String, Object?> m) =>
      {for (final e in m.entries) if (e.value != null) e.key: e.value};

  final layoutsOf  = _groupBy(rows.layouts,  (l) => l.wallId);
  final photosOf   = _groupBy(rows.photos,   (p) => p.layoutId);
  final problemsOf = _groupBy(rows.problems, (p) => p.layoutId);
  final marksOf    = _groupBy(rows.marks,    (m) => m.problemId);

  return {
    'version':    backupVersion,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'walls': [
      for (final w in rows.walls)
        {
          'id':         w.id,
          'name':       w.name,
          'gradeScale': w.gradeScale.name,
          'createdOn':  w.createdOn,
          'sortOrder':  w.sortOrder,
          'layouts': [
            for (final l in layoutsOf[w.id] ?? const <Layout>[])
              some({
                'id':        l.id,
                'name':      l.name,
                'startedOn': l.startedOn,
                'endedOn':   l.endedOn,
                'photos': [
                  for (final p in photosOf[l.id] ?? const <WallPhoto>[])
                    some({
                      'id':        p.id,
                      'sortOrder': p.sortOrder,
                      'width':     p.width,
                      'height':    p.height,
                      'addedOn':   p.addedOn,
                      'label':     p.label,
                    }),
                ],
                'problems': [
                  for (final p in problemsOf[l.id] ?? const <Problem>[])
                    some({
                      'id':          p.id,
                      'name':        p.name,
                      'grade':       p.grade,
                      'description': p.description,
                      'setOn':       p.setOn,
                      'retiredOn':   p.retiredOn,
                      'marks': [
                        for (final m in marksOf[p.id] ?? const <Mark>[])
                          {
                            'id':      m.id,
                            'photoId': m.photoId,
                            'role':    m.role.name,
                            'cx':      m.cx,
                            'cy':      m.cy,
                            'r':       m.r,
                          },
                      ],
                    }),
                ],
              }),
          ],
        },
    ],
  };
}

/// The file a backup is saved as: `spraywall-2026-11-22.zip`, or with the
/// wall's name for one wall, kept to characters every file system takes.
String backupFileName(DateTime now, {String? wallName}) {
  final wall = wallName == null ? '' : '-${fileSafe(wallName)}';
  return 'spraywall$wall-${dateStrFrom(now)}.zip';
}

Map<K, List<T>> _groupBy<T, K>(Iterable<T> items, K Function(T) key) {
  final out = <K, List<T>>{};
  for (final i in items) {
    (out[key(i)] ??= []).add(i);
  }
  return out;
}
