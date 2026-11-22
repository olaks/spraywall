import '../database/database.dart';

/// The photo a problem view opens on: the first photo (in the layout's
/// order) with a start mark, else the first with any of the problem's marks,
/// else the layout's first photo. Null only when [photos] is empty.
WallPhoto? openingPhoto(List<WallPhoto> photos, List<Mark> marks) {
  bool has(WallPhoto p, bool Function(Mark) test) =>
      marks.any((m) => m.photoId == p.id && test(m));
  return photos.where((p) => has(p, (m) => m.role == Role.start)).firstOrNull ??
         photos.where((p) => has(p, (_) => true)).firstOrNull ??
         photos.firstOrNull;
}
