import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import '../database/database.dart';
import '../problems/browse.dart';

// ── Database singleton ─────────────────────────────────────────────────────

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── Streams ────────────────────────────────────────────────────────────────

final wallsProvider = StreamProvider<List<Wall>>((ref) =>
    ref.watch(dbProvider).watchWalls());

final wallProvider = StreamProvider.family<Wall?, String>((ref, id) =>
    ref.watch(dbProvider).watchWall(id));

final currentLayoutProvider = StreamProvider.family<Layout?, String>(
    (ref, wallId) => ref.watch(dbProvider).watchCurrentLayout(wallId));

final photosProvider = StreamProvider.family<List<WallPhoto>, String>(
    (ref, layoutId) => ref.watch(dbProvider).watchPhotos(layoutId));

final photoProvider = StreamProvider.family<WallPhoto?, String>(
    (ref, id) => ref.watch(dbProvider).watchPhoto(id));

/// Problems using each photo of a layout, by photo id.
final photoUsageProvider = StreamProvider.family<Map<String, int>, String>(
    (ref, layoutId) => ref.watch(dbProvider).watchPhotoUsage(layoutId));

/// A photo's bytes. Auto-disposed, so only photos on screen stay in memory;
/// bytes never change after import, so a one-shot read is enough.
final photoImageProvider =
    FutureProvider.autoDispose.family<WallPhotoImage?, String>(
        (ref, id) => ref.watch(dbProvider).photoImage(id));

/// A photo's thumbnail, for lists and the photo strip.
final photoThumbProvider = FutureProvider.autoDispose.family<Uint8List?, String>(
    (ref, id) => ref.watch(dbProvider).photoThumb(id));

/// Every mark of a layout's problems, for the list's thumbnails.
final layoutMarksProvider = StreamProvider.family<List<Mark>, String>(
    (ref, layoutId) => ref.watch(dbProvider).watchLayoutMarks(layoutId));

/// The wall screen's filters and sort, per wall. In memory for the app run:
/// they survive opening a problem and coming back, but not a restart.
final problemQueryProvider =
    NotifierProvider.family<ProblemQueryNotifier, ProblemQuery, String>(
        ProblemQueryNotifier.new);

class ProblemQueryNotifier extends Notifier<ProblemQuery> {
  ProblemQueryNotifier(String _);

  @override
  ProblemQuery build() => const ProblemQuery();

  void set(ProblemQuery query) => state = query;
}

/// A layout's problems, retired ones included, by name.
final problemsProvider = StreamProvider.family<List<Problem>, String>(
    (ref, layoutId) => ref.watch(dbProvider).watchProblems(layoutId));

final problemProvider = StreamProvider.family<Problem?, String>(
    (ref, id) => ref.watch(dbProvider).watchProblem(id));

/// A problem's marks in drawing order.
final problemMarksProvider = StreamProvider.family<List<Mark>, String>(
    (ref, problemId) => ref.watch(dbProvider).watchMarksOf(problemId));

/// One layout, current or archived. A layout never changes walls, so a
/// one-shot read is enough to place a problem.
final layoutProvider = FutureProvider.family<Layout?, String>(
    (ref, id) => ref.watch(dbProvider).layout(id));
