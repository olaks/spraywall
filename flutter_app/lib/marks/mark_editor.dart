import 'dart:ui' show Offset, Size;

import 'package:flutter/foundation.dart';
import '../database/database.dart';
import 'mark_geometry.dart';
import 'outline.dart';

/// A mark in the editor's working copy. Normalised like a stored [Mark]:
/// on an outline mark, [cx], [cy] and [r] are the circle around [outline].
@immutable
class EditMark {
  final String   id;
  final String   photoId;
  final Role     role;
  final double   cx;
  final double   cy;
  final double   r;
  final Outline? outline;

  const EditMark({
    required this.id,
    required this.photoId,
    required this.role,
    required this.cx,
    required this.cy,
    required this.r,
    this.outline,
  });

  EditMark.fromMark(Mark m)
      : id = m.id, photoId = m.photoId, role = m.role,
        cx = m.cx, cy = m.cy, r = m.r, outline = decodeOutline(m.outline);

  MarkInput get input => (
        id: id, photoId: photoId, role: role, cx: cx, cy: cy, r: r,
        outline: outline == null ? null : encodeOutline(outline!),
      );

  EditMark copyWith({Role? role, double? cx, double? cy, double? r,
          Outline? outline}) =>
      EditMark(
        id: id, photoId: photoId,
        role:    role    ?? this.role,
        cx:      cx      ?? this.cx,
        cy:      cy      ?? this.cy,
        r:       r       ?? this.r,
        outline: outline ?? this.outline,
      );
}

/// A mark taken out by trash, and where it was, so undo can put it back.
typedef TrashedMark = ({int index, EditMark mark});

/// The editor's working copy of a problem's marks, kept in memory until Save
/// (there are no drafts). Pure state, so its rules are unit-tested without
/// widgets.
class MarkEditorController extends ChangeNotifier {
  final List<EditMark> _marks;
  String? _selectedId;
  Role    _brush = Role.hand;
  bool    _dirty = false;

  /// The radius last placed or resized to on each photo, this session.
  final Map<String, double> _lastR = {};

  MarkEditorController([Iterable<EditMark> marks = const []])
      : _marks = [...marks];

  /// Marks in insertion order, which is the order they draw in.
  List<EditMark> get marks => List.unmodifiable(_marks);

  /// One photo's marks with the selected one last, so it paints on top and
  /// wins hit tests.
  List<EditMark> marksOn(String photoId) => [
        for (final m in _marks)
          if (m.photoId == photoId && m.id != _selectedId) m,
        for (final m in _marks)
          if (m.photoId == photoId && m.id == _selectedId) m,
      ];

  EditMark? get selected =>
      _marks.where((m) => m.id == _selectedId).firstOrNull;

  /// The role new marks get. Shown on the palette unless a mark is selected,
  /// in which case the palette shows that mark's role.
  Role get brush => _brush;

  /// Whether anything changed since the controller was made.
  bool get dirty => _dirty;

  bool get hasStart  => _marks.any((m) => m.role == Role.start);
  bool get hasFinish => _marks.any((m) => m.role == Role.finish);

  /// The radius a new mark on [photoId] gets.
  double nextRadius(String photoId) => _lastR[photoId] ?? kDefaultMarkR;

  /// Places a mark with the brush role at [cx], [cy] on [photoId] and selects
  /// it. Always places: a tap on empty photo never just deselects. With an
  /// [outline] (traced from the hold, on a photo of [photo] pixels) the mark
  /// is that outline, centred on its own circle; without, a circle at the tap.
  EditMark place(String photoId, double cx, double cy,
      {Outline? outline, Size? photo}) {
    final around = outline == null ? null : enclosingCircle(outline, photo!);
    final mark = EditMark(
      id: newId(), photoId: photoId, role: _brush,
      cx: around?.cx ?? cx.clamp(0.0, 1.0),
      cy: around?.cy ?? cy.clamp(0.0, 1.0),
      r:  around?.r  ?? nextRadius(photoId),
      outline: outline,
    );
    _marks.add(mark);
    _selectedId = mark.id;
    _changed();
    return mark;
  }

  void select(String? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  /// A palette chip: becomes the brush, and recolours the selected mark.
  void chooseRole(Role role) {
    _brush = role;
    final sel = selected;
    if (sel != null && sel.role != role) {
      _replace(sel.copyWith(role: role));
      _changed();
    } else {
      notifyListeners();
    }
  }

  /// Moves a mark by a drag of [dcx], [dcy] (normalised), keeping its centre
  /// on the photo. An outline moves with its centre, each point kept on the
  /// photo.
  void move(String id, double dcx, double dcy) {
    final m  = _byId(id);
    final cx = (m.cx + dcx).clamp(0.0, 1.0);
    final cy = (m.cy + dcy).clamp(0.0, 1.0);
    _replace(m.copyWith(
      cx: cx, cy: cy,
      outline: m.outline == null
          ? null
          : moveOutline(m.outline!, cx - m.cx, cy - m.cy),
    ));
    _changed();
  }

  /// Grows or shrinks a mark by [dr] within the limits; an outline scales
  /// about its centre to match. A circle's result becomes the size of the
  /// next circle on that photo; an outline's is the hold's own size.
  void resize(String id, double dr) {
    final m = _byId(id);
    final r = clampRadius(m.r + dr);
    final o = m.outline;
    _replace(m.copyWith(
      r: r,
      outline: o == null ? null : scaleOutline(o, r / m.r, m.cx, m.cy),
    ));
    if (o == null) _lastR[m.photoId] = r;
    _changed();
  }

  /// Moves point [index] of an outline mark by [dcx], [dcy] (normalised),
  /// kept on the photo. The mark's circle refits the new shape, on a photo
  /// of [photo] pixels.
  void movePoint(String id, int index, double dcx, double dcy, Size photo) {
    final m = _byId(id);
    final o = [...m.outline!];
    o[index] = Offset((o[index].dx + dcx).clamp(0.0, 1.0),
                      (o[index].dy + dcy).clamp(0.0, 1.0));
    _reshape(m, o, photo);
  }

  /// Adds a point [at] (normalised) to an outline mark on the edge after
  /// point [after], and returns its index.
  int insertPoint(String id, int after, Offset at, Size photo) {
    final m = _byId(id);
    _reshape(m, [...m.outline!]..insert(after + 1, at), photo);
    return after + 1;
  }

  /// Removes point [index] of an outline mark, which keeps at least three.
  void removePoint(String id, int index, Size photo) {
    final m = _byId(id);
    if (m.outline!.length <= 3) return;
    _reshape(m, [...m.outline!]..removeAt(index), photo);
  }

  void _reshape(EditMark m, Outline o, Size photo) {
    final around = enclosingCircle(o, photo);
    _replace(m.copyWith(
        outline: o, cx: around.cx, cy: around.cy, r: around.r));
    _changed();
  }

  /// Removes a mark; [untrash] puts it back.
  TrashedMark trash(String id) {
    final index = _marks.indexWhere((m) => m.id == id);
    final mark  = _marks.removeAt(index);
    if (_selectedId == id) _selectedId = null;
    _changed();
    return (index: index, mark: mark);
  }

  void untrash(TrashedMark t) {
    _marks.insert(t.index.clamp(0, _marks.length), t.mark);
    _changed();
  }

  EditMark _byId(String id) => _marks.firstWhere((m) => m.id == id);

  void _replace(EditMark m) =>
      _marks[_marks.indexWhere((x) => x.id == m.id)] = m;

  void _changed() {
    _dirty = true;
    notifyListeners();
  }
}
