import 'package:flutter/foundation.dart';
import '../database/database.dart';
import 'mark_geometry.dart';

/// A mark in the editor's working copy. Normalised like a stored [Mark].
@immutable
class EditMark {
  final String id;
  final String photoId;
  final Role   role;
  final double cx;
  final double cy;
  final double r;

  const EditMark({
    required this.id,
    required this.photoId,
    required this.role,
    required this.cx,
    required this.cy,
    required this.r,
  });

  EditMark.fromMark(Mark m)
      : id = m.id, photoId = m.photoId, role = m.role,
        cx = m.cx, cy = m.cy, r = m.r;

  MarkInput get input =>
      (id: id, photoId: photoId, role: role, cx: cx, cy: cy, r: r);

  EditMark copyWith({Role? role, double? cx, double? cy, double? r}) => EditMark(
        id: id, photoId: photoId,
        role: role ?? this.role,
        cx:   cx   ?? this.cx,
        cy:   cy   ?? this.cy,
        r:    r    ?? this.r,
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
  /// it. Always places: a tap on empty photo never just deselects.
  EditMark place(String photoId, double cx, double cy) {
    final mark = EditMark(
      id: newId(), photoId: photoId, role: _brush,
      cx: cx.clamp(0.0, 1.0), cy: cy.clamp(0.0, 1.0),
      r:  nextRadius(photoId),
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
  /// on the photo.
  void move(String id, double dcx, double dcy) {
    final m = _byId(id);
    _replace(m.copyWith(
        cx: (m.cx + dcx).clamp(0.0, 1.0), cy: (m.cy + dcy).clamp(0.0, 1.0)));
    _changed();
  }

  /// Grows or shrinks a mark by [dr] within the limits. The result becomes
  /// the size of the next mark on that photo.
  void resize(String id, double dr) {
    final m = _byId(id);
    final r = clampRadius(m.r + dr);
    _replace(m.copyWith(r: r));
    _lastR[m.photoId] = r;
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
