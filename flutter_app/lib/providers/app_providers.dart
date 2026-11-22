import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';

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
