import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import '../database/database.dart';
import '../marks/hold_trace.dart';
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

/// Decodes a wall photo's JPEG to pixels for tracing holds: the engine's
/// decoder, native on every platform. Overridden in widget tests with
/// [decodePixels], since an engine decode needs real time.
final pixelDecoderProvider = Provider<Future<PhotoPixels> Function(Uint8List)>(
    (ref) => _decodeWithEngine);

Future<PhotoPixels> _decodeWithEngine(Uint8List jpeg) async {
  final codec = await ui.instantiateImageCodec(jpeg);
  final image = (await codec.getNextFrame()).image;
  final data  = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final px    = PhotoPixels(image.width, image.height, data.buffer.asUint8List());
  image.dispose();
  codec.dispose();
  return px;
}

/// A photo's pixels at full size, for tracing holds while the editor shows
/// it. Auto-disposed: about 20 MB for a 2560 px photo.
final photoPixelsProvider =
    FutureProvider.autoDispose.family<PhotoPixels?, String>((ref, id) async {
  final image = await ref.watch(photoImageProvider(id).future);
  return image == null ? null : ref.watch(pixelDecoderProvider)(image.data);
});

/// Every mark of a layout's problems, for the list's thumbnails.
final layoutMarksProvider = StreamProvider.family<List<Mark>, String>(
    (ref, layoutId) => ref.watch(dbProvider).watchLayoutMarks(layoutId));

/// The wall screen's filters and sort, per layout (so an archived layout's
/// list keeps its own). In memory for the app run: they survive opening a
/// problem and coming back, but not a restart.
final problemQueryProvider =
    NotifierProvider.family<ProblemQueryNotifier, ProblemQuery, String>(
        ProblemQueryNotifier.new);

class ProblemQueryNotifier extends Notifier<ProblemQuery> {
  ProblemQueryNotifier(String _);

  @override
  ProblemQuery build() => const ProblemQuery();

  void set(ProblemQuery query) => state = query;
}

/// A wall's archived layouts, newest first, with their counts.
final pastLayoutsProvider = StreamProvider.family<List<PastLayout>, String>(
    (ref, wallId) => ref.watch(dbProvider).watchPastLayouts(wallId));

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
