// PROTOTYPE — throwaway (wayfinder ticket 09). In-memory photos, marks and
// the editor/view state shared by every variant. Not production code.
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A wall photo of the current layout. Crops of `sample/` stand in for three
/// separate shots: Top and Bottom overlap by a band of holds, and Kicker is a
/// close-up of the bottom of Bottom.
class Photo {
  const Photo(this.id, this.label, this.asset, this.w, this.h, this.crop);
  final String id, label, asset;
  final double w, h; // display-copy px
  final Rect crop; // where this shot sits in the 3120×4160 sample
}

const photos = [
  Photo('top', 'Top', 'assets/top.jpg', 2560, 1969,
      Rect.fromLTWH(0, 0, 3120, 2400)),
  Photo('bottom', 'Bottom', 'assets/bottom.jpg', 2560, 1936,
      Rect.fromLTWH(0, 1800, 3120, 2360)),
  Photo('kicker', 'Kicker', 'assets/kicker.jpg', 2320, 1160,
      Rect.fromLTWH(400, 3000, 2320, 1160)),
];

Photo photoById(String id) => photos.firstWhere((p) => p.id == id);

enum Role { start, hand, foot, finish }

const roleColor = {
  Role.start: Color(0xFF00E676),
  Role.hand: Color(0xFF00B0FF),
  Role.foot: Color(0xFFD500F9),
  Role.finish: Color(0xFFFF1744),
};

class Mark {
  Mark(this.id, this.photoId, this.role, this.cx, this.cy, this.r);
  final int id;
  final String photoId;
  Role role;
  double cx, cy, r; // cx, cy: 0..1 of photo w/h; r: fraction of photo width
}

enum Mode { view, edit, create }

/// Opening rule for the problem view.
enum OpenRule { startMarks, firstMarked }

class Store extends ChangeNotifier {
  Store() {
    setMode(Mode.view);
  }

  final marks = <Mark>[];
  int _next = 1;
  int? selectedId;
  Role brush = Role.hand;
  final lastR = <String, double>{}; // per photo: photos differ in scale
  Mode mode = Mode.view;
  OpenRule openRule = OpenRule.startMarks;
  bool hideUnmarked = true; // view only
  late String current;
  String openedWhy = '';

  Mark? get selected => marks.where((m) => m.id == selectedId).firstOrNull;
  bool get editing => mode != Mode.view;

  List<Mark> marksOn(String photoId) =>
      marks.where((m) => m.photoId == photoId).toList();

  /// Selected mark last, so it paints on top and wins hit tests.
  List<Mark> orderedOn(String photoId) => [
        ...marksOn(photoId).where((m) => m.id != selectedId),
        ...marksOn(photoId).where((m) => m.id == selectedId),
      ];

  List<Photo> get marked =>
      photos.where((p) => marks.any((m) => m.photoId == p.id)).toList();

  /// Photos the current screen moves between.
  List<Photo> get visible {
    if (editing || !hideUnmarked) return photos;
    final m = marked;
    return m.isEmpty ? photos : m;
  }

  void setMode(Mode m) {
    final from = mode;
    mode = m;
    selectedId = null;
    switch (m) {
      case Mode.view:
        if (from == Mode.create || marks.isEmpty) _seed();
        _openView();
      case Mode.edit:
        if (from == Mode.create || marks.isEmpty) {
          _seed();
          _openView();
          openedWhy += ' (as if opened from the view)';
        } else {
          openedWhy = 'kept the photo the view was showing';
        }
      case Mode.create:
        marks.clear();
        current = photos.first.id;
        openedWhy = 'new problem: first photo of the layout';
    }
    notifyListeners();
  }

  void _openView() {
    final withStart = photos.where((p) =>
        marks.any((m) => m.photoId == p.id && m.role == Role.start));
    if (openRule == OpenRule.startMarks && withStart.isNotEmpty) {
      current = withStart.first.id;
      openedWhy = 'view: first photo with start marks';
    } else {
      current = (marked.firstOrNull ?? photos.first).id;
      openedWhy = 'view: first photo (in layout order) with marks';
    }
  }

  void reopen() {
    selectedId = null;
    if (mode == Mode.view) _openView();
    notifyListeners();
  }

  void show(String photoId) {
    if (current == photoId) return;
    current = photoId;
    selectedId = null;
    notifyListeners();
  }

  Mark add(Role role, String photoId, double cx, double cy) {
    final p = photoById(photoId);
    final r = lastR[photoId] ?? 50 / p.w; // ~50 display px to start
    final m = Mark(_next++, photoId, role, cx, cy, r);
    marks.add(m);
    selectedId = m.id;
    notifyListeners();
    return m;
  }

  void select(int? id) {
    selectedId = id;
    notifyListeners();
  }

  void changed() => notifyListeners();

  void remove(BuildContext context, Mark m) {
    final i = marks.indexOf(m);
    marks.removeAt(i);
    if (selectedId == m.id) selectedId = null;
    notifyListeners();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      content: Text('Deleted ${m.role.name} mark'),
      action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            marks.insert(math.min(i, marks.length), m);
            notifyListeners();
          }),
    ));
  }

  /// "Red crimps": start and low hands on Bottom, upper hands and finish on
  /// Top, feet on Bottom. Kicker carries nothing, though the two low hands
  /// also show on Top and the feet also show on Kicker.
  void _seed() {
    marks.clear();
    // Positions in a 780×1040 preview of the sample (×4 = sample px).
    void s(Role r, String photoId, double px, double py) {
      final p = photoById(photoId);
      final c = p.crop;
      marks.add(Mark(_next++, photoId, r, (px * 4 - c.left) / c.width,
          (py * 4 - c.top) / c.height, 60 / c.width));
    }

    s(Role.start, 'bottom', 237, 622);
    s(Role.start, 'bottom', 182, 624);
    s(Role.hand, 'bottom', 345, 568);
    s(Role.hand, 'bottom', 455, 515);
    s(Role.foot, 'bottom', 312, 942);
    s(Role.foot, 'bottom', 408, 905);
    s(Role.hand, 'top', 455, 394);
    s(Role.hand, 'top', 334, 200);
    s(Role.finish, 'top', 522, 192);
  }
}

final store = Store();
