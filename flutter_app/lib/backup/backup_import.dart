import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../photos/photo_import.dart';
import 'backup_export.dart';

/// Why a backup can't be imported, in words for the user. Nothing has been
/// written when it is thrown.
class BackupError implements Exception {
  final String message;
  const BackupError(this.message);

  @override
  String toString() => message;
}

/// Reads and checks a whole backup before anything is written: a zip with
/// `backup.json`, a format version this app knows, every field of the right
/// type, no id twice, at most one current layout per wall, every photo's
/// JPEG in the zip, and every mark on a photo of its own problem's layout.
/// Returns the rows as [BackupRows], marks in drawing order. Throws
/// [BackupError].
BackupRows parseBackup(Uint8List bytes) {
  final Archive zip;
  try {
    zip = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw const BackupError("That file isn't a Spraywall backup: it isn't a "
        '.zip file.');
  }
  final jsonFile = zip.findFile(backupJsonName);
  if (jsonFile == null) {
    throw const BackupError("That file isn't a Spraywall backup: it has no "
        '$backupJsonName.');
  }
  final Object? root;
  try {
    root = jsonDecode(utf8.decode(jsonFile.content));
  } catch (_) {
    throw const BackupError('This backup is damaged: its $backupJsonName '
        "isn't valid JSON.");
  }

  final r       = _Reader(root, 'backup');
  final version = r.integer('version');
  if (version > backupVersion) {
    throw BackupError('This backup was made by a newer version of Spraywall '
        '(format $version). Update the app to import it.');
  }
  if (version < 1) throw _damaged('version $version is not a format');

  final walls    = <Wall>[];
  final layouts  = <Layout>[];
  final photos   = <WallPhoto>[];
  final problems = <Problem>[];
  final marks    = <Mark>[];
  final photoData = <String, Uint8List>{};
  final ids      = <String>{};
  String id(_Reader r) {
    final v = r.text('id');
    if (!ids.add(v)) throw _damaged('the id $v appears twice');
    return v;
  }

  for (final w in r.list('walls')) {
    final wallId = id(w);
    walls.add(Wall(
      id:         wallId,
      name:       w.text('name'),
      gradeScale: w.byName('gradeScale', GradeScale.values),
      createdOn:  w.text('createdOn'),
      sortOrder:  w.integer('sortOrder'),
    ));
    var current = 0;
    for (final l in w.list('layouts')) {
      final layoutId = id(l);
      final layout   = Layout(
        id:        layoutId,
        wallId:    wallId,
        name:      l.textOrNull('name'),
        startedOn: l.text('startedOn'),
        endedOn:   l.textOrNull('endedOn'),
      );
      layouts.add(layout);
      if (layout.endedOn == null && ++current > 1) {
        throw _damaged('a wall has two current layouts');
      }

      final here = <String>{};
      for (final p in l.list('photos')) {
        final photoId = id(p);
        final jpeg    = zip.findFile(backupPhotoName(photoId));
        if (jpeg == null) {
          throw _damaged('the photo ${backupPhotoName(photoId)} is missing');
        }
        photoData[photoId] = Uint8List.fromList(jpeg.content);
        here.add(photoId);
        photos.add(WallPhoto(
          id:        photoId,
          layoutId:  layoutId,
          sortOrder: p.integer('sortOrder'),
          width:     p.integer('width'),
          height:    p.integer('height'),
          addedOn:   p.text('addedOn'),
          label:     p.textOrNull('label'),
        ));
      }

      for (final p in l.list('problems')) {
        final problemId = id(p);
        problems.add(Problem(
          id:          problemId,
          layoutId:    layoutId,
          name:        p.text('name'),
          grade:       p.textOrNull('grade'),
          description: p.textOrNull('description') ?? '',
          setOn:       p.text('setOn'),
          retiredOn:   p.textOrNull('retiredOn'),
        ));
        for (final m in p.list('marks')) {
          final markId  = id(m);
          final photoId = m.text('photoId');
          if (!here.contains(photoId)) {
            throw _damaged('a mark is on a photo that is not in its '
                "problem's layout ($photoId)");
          }
          marks.add(Mark(
            id:        markId,
            problemId: problemId,
            photoId:   photoId,
            role:      m.byName('role', Role.values),
            cx:        m.number('cx'),
            cy:        m.number('cy'),
            r:         m.number('r'),
          ));
        }
      }
    }
  }
  return BackupRows(
    walls: walls, layouts: layouts, photos: photos, problems: problems,
    marks: marks, photoData: photoData,
  );
}

BackupError _damaged(String what) =>
    BackupError('This backup is damaged: $what.');

/// Typed reads from one JSON object, naming the field that's wrong.
class _Reader {
  final Map<String, Object?> _m;
  final String               _where;

  _Reader(Object? value, String where)
      : _where = where,
        _m     = value is Map<String, Object?>
            ? value
            : throw _damaged('$where is not an object');

  T _get<T>(String key) {
    final v = _m[key];
    if (v is T) return v;
    throw _damaged(v == null
        ? '$_where has no $key'
        : '$_where has a $key of the wrong kind');
  }

  String  text(String key)       => _get<String>(key);
  String? textOrNull(String key) => _get<String?>(key);
  int     integer(String key)    => _get<int>(key);
  double  number(String key)     => _get<num>(key).toDouble();

  T byName<T extends Enum>(String key, List<T> values) {
    final name = text(key);
    for (final v in values) {
      if (v.name == name) return v;
    }
    throw _damaged('$_where has an unknown $key "$name"');
  }

  List<_Reader> list(String key) => [
        for (final (i, v) in _get<List<Object?>>(key).indexed)
          _Reader(v, '$key[$i]'),
      ];
}

/// The summary dialog's lines, in plain words.
List<String> importSummaryLines(ImportSummary s) {
  String count(int n, String one) => '$n $one${n == 1 ? '' : 's'}';
  String listOf(List<String> parts) => switch (parts.length) {
        0 => '',
        1 => parts.single,
        _ => '${parts.sublist(0, parts.length - 1).join(', ')} and '
            '${parts.last}',
      };
  List<String> counts(BackupCounts c) => [
        if (c.walls    > 0) count(c.walls,    'wall'),
        if (c.layouts  > 0) count(c.layouts,  'layout'),
        if (c.photos   > 0) count(c.photos,   'photo'),
        if (c.problems > 0) count(c.problems, 'problem'),
      ];

  final added = counts(s.added);
  final here  = counts(s.alreadyHere);
  return [
    added.isEmpty
        ? 'Nothing new: everything in it was already here.'
        : 'Added ${listOf(added)}.',
    if (added.isNotEmpty && here.isNotEmpty)
      'Already here, so left as they are: ${listOf(here)}.',
    for (final (from, to) in s.renamed) 'Renamed "$from" to "$to": the name was taken.',
    if (s.ungraded > 0)
      'Made ${count(s.ungraded, 'problem')} ungraded: '
          "${s.ungraded == 1 ? 'its grade isn' : 'their grades aren'}'t on the "
          "wall's grade scale.",
    if (s.archived > 0)
      'Archived ${count(s.archived, 'layout')}: a wall had two current '
          'layouts, and the later one stays current.',
  ];
}

/// [parseBackup] off the UI thread. Overridden in widget tests, where an
/// isolate never finishes under fake time.
final backupParserProvider = Provider<Future<BackupRows> Function(Uint8List)>(
    (ref) => (bytes) => compute(parseBackup, bytes));

/// [makeThumb] off the UI thread; overridden like [backupParserProvider].
final thumbMakerProvider = Provider<Future<Uint8List> Function(Uint8List)>(
    (ref) => (data) => compute(makeThumb, data));
