// PROTOTYPE — throwaway. Shared wall-photo viewer, mark model and mark widget
// for the mark-editing prototype (ticket 05). Not production code.
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Display copy size: sample is 3120×4160, downscaled to 2560 px long edge
/// (the import decision from ticket 01).
const photoW = 1920.0;
const photoH = 2560.0;
const photo = ResizeImage(AssetImage('assets/wall.jpg'),
    width: 1920, height: 2560, policy: ResizeImagePolicy.fit);

enum Role { start, hand, foot, finish }

const roleColor = {
  Role.start: Color(0xFF00E676),
  Role.hand: Color(0xFF00B0FF),
  Role.foot: Color(0xFFD500F9),
  Role.finish: Color(0xFFFF1744),
};

class Mark {
  Mark(this.id, this.role, this.cx, this.cy, this.r);
  final int id;
  Role role;
  double cx, cy, r; // cx, cy: 0..1 of photo w/h; r: fraction of photo width
}

/// In-memory marks, shared across variants so the same problem can be
/// compared in each.
class Marks extends ChangeNotifier {
  final list = <Mark>[];
  int _next = 1;
  int? selectedId;
  double lastR = 0.018;

  Mark? get selected =>
      list.where((m) => m.id == selectedId).firstOrNull;

  /// Selected mark last, so it paints on top and wins hit tests.
  List<Mark> get ordered => [
        ...list.where((m) => m.id != selectedId),
        ...list.where((m) => m.id == selectedId),
      ];

  Mark add(Role role, double cx, double cy, double r) {
    final m = Mark(_next++, role, cx, cy, r.clamp(0.003, 0.15));
    list.add(m);
    notifyListeners();
    return m;
  }

  void select(int? id) {
    selectedId = id;
    notifyListeners();
  }

  void changed() => notifyListeners();

  void clear() {
    list.clear();
    selectedId = null;
    notifyListeners();
  }

  void remove(BuildContext context, Mark m) {
    final i = list.indexOf(m);
    list.removeAt(i);
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
            list.insert(math.min(i, list.length), m);
            notifyListeners();
          }),
    ));
  }
}

final marks = Marks();
final zoomNote = ValueNotifier<double>(1);

/// Zoomable wall photo. Gesture callbacks report photo-pixel positions.
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({
    super.key,
    required this.controller,
    required this.overlay,
    this.panEnabled = true,
    this.onTapEmpty,
    this.onLongPressEmpty,
    this.onLongPressMove,
    this.onLongPressEnd,
    this.onSecondaryTapEmpty,
  });

  final TransformationController controller;
  final List<Widget> Function(double zoom) overlay;
  final bool panEnabled;
  final ValueChanged<Offset>? onTapEmpty;
  final ValueChanged<Offset>? onLongPressEmpty;
  final ValueChanged<Offset>? onLongPressMove;
  final VoidCallback? onLongPressEnd;
  final ValueChanged<Offset>? onSecondaryTapEmpty;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  bool _fitted = false;
  double _fit = 0.2;

  void _onZoom() => zoomNote.value = widget.controller.value.getMaxScaleOnAxis();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onZoom);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onZoom);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final vp = box.biggest;
      if (!_fitted) {
        _fitted = true;
        _fit = math.min(vp.width / photoW, vp.height / photoH);
        widget.controller.value = Matrix4.diagonal3Values(_fit, _fit, 1)
          ..setTranslationRaw((vp.width - photoW * _fit) / 2,
              (vp.height - photoH * _fit) / 2, 0);
        zoomNote.value = _fit;
      }
      return ColoredBox(
        color: Colors.black,
        child: InteractiveViewer(
          transformationController: widget.controller,
          constrained: false,
          panEnabled: widget.panEnabled,
          minScale: _fit * 0.8,
          maxScale: 4, // up to 4 screen px per display-copy px
          boundaryMargin: const EdgeInsets.all(1500),
          child: SizedBox(
            width: photoW,
            height: photoH,
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final zoom = widget.controller.value.getMaxScaleOnAxis();
                return Stack(clipBehavior: Clip.none, children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: widget.onTapEmpty == null
                          ? null
                          : (d) => widget.onTapEmpty!(d.localPosition),
                      onLongPressStart: widget.onLongPressEmpty == null
                          ? null
                          : (d) => widget.onLongPressEmpty!(d.localPosition),
                      onLongPressMoveUpdate: widget.onLongPressMove == null
                          ? null
                          : (d) => widget.onLongPressMove!(d.localPosition),
                      onLongPressEnd: widget.onLongPressEnd == null
                          ? null
                          : (_) => widget.onLongPressEnd!(),
                      onSecondaryTapUp: widget.onSecondaryTapEmpty == null
                          ? null
                          : (d) => widget.onSecondaryTapEmpty!(d.localPosition),
                      child: const Image(
                          image: photo,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.medium),
                    ),
                  ),
                  ...widget.overlay(zoom),
                ]);
              },
            ),
          ),
        ),
      );
    });
  }
}

/// One mark, positioned in photo px. Unselected marks get a minimum hit
/// radius of ~20 screen px. Only pass [onMove]/[onResize] for the selected mark.
Widget markWidget(
  Mark m, {
  required double zoom,
  bool selected = false,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
  void Function(double dx, double dy)? onMove,
  ValueChanged<double>? onResize,
  ValueChanged<bool>? onHold,
}) {
  final rPx = m.r * photoW;
  final hitR = math.max(rPx, 20 / zoom);
  final handle = 26 / zoom;
  final half = math.max(hitR, rPx + handle);
  void hold(bool h) => onHold?.call(h);

  return Positioned(
    key: ValueKey(m.id),
    left: m.cx * photoW - half,
    top: m.cy * photoH - half,
    width: half * 2,
    height: half * 2,
    child: Stack(children: [
      Positioned.fill(
        child: Listener(
          onPointerDown: onMove != null ? (_) => hold(true) : null,
          onPointerUp: onMove != null ? (_) => hold(false) : null,
          onPointerCancel: onMove != null ? (_) => hold(false) : null,
          child: GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            onSecondaryTap: onLongPress,
            onPanUpdate: onMove == null
                ? null
                : (d) => onMove(d.delta.dx / photoW, d.delta.dy / photoH),
            child: CustomPaint(
                painter: MarkPainter(m.role, rPx, hitR, zoom, selected)),
          ),
        ),
      ),
      if (selected && onResize != null)
        Positioned(
          left: half + rPx - handle / 2,
          top: half - handle / 2,
          width: handle,
          height: handle,
          child: Listener(
            onPointerDown: (_) => hold(true),
            onPointerUp: (_) => hold(false),
            onPointerCancel: (_) => hold(false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) => onResize(d.delta.dx / photoW),
              child: Center(
                child: Container(
                  width: handle * 0.6,
                  height: handle * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1.5 / zoom),
                  ),
                ),
              ),
            ),
          ),
        ),
    ]),
  );
}

class MarkPainter extends CustomPainter {
  MarkPainter(this.role, this.rPx, this.hitR, this.zoom, this.selected);
  final Role role;
  final double rPx, hitR, zoom;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final s = (selected ? 3.5 : 2.5) / zoom;
    canvas.drawCircle(
        c,
        rPx,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 2.2
          ..color = Colors.black54);
    canvas.drawCircle(
        c,
        rPx,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s
          ..color = roleColor[role]!);
    if (selected) {
      canvas.drawCircle(
          c,
          rPx + 4 / zoom,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 / zoom
            ..color = Colors.white);
    }
  }

  @override
  bool hitTest(Offset position) => (position - _centre).distance <= hitR;

  Offset get _centre => Offset(_half, _half);
  double get _half => math.max(hitR, rPx + 26 / zoom);

  @override
  bool shouldRepaint(MarkPainter o) =>
      o.role != role || o.rPx != rPx || o.zoom != zoom || o.selected != selected;
}
