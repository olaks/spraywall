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
