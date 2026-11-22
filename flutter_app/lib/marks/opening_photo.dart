import '../database/database.dart';

/// The photo a problem screen opens on.
///
/// The editor passes [shown], the photo the view was showing, and opens on it
/// while it is still in the layout. Otherwise (the view, a new problem, a
/// reloaded editor URL): the first photo in the layout's order with a start
/// mark, else the first with any of [marks], else the layout's first photo.
/// Null only when [photos] is empty.
WallPhoto? openingPhoto(List<WallPhoto> photos, List<Mark> marks,
    {String? shown}) {
  bool has(WallPhoto p, bool Function(Mark) test) =>
      marks.any((m) => m.photoId == p.id && test(m));
  return photos.where((p) => p.id == shown).firstOrNull ??
         photos.where((p) => has(p, (m) => m.role == Role.start)).firstOrNull ??
         photos.where((p) => has(p, (_) => true)).firstOrNull ??
         photos.firstOrNull;
}
