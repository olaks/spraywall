import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../database/tables.dart' show Role;
import 'mark_editor.dart';
import 'mark_geometry.dart';
import 'outline.dart';

/// Draws marks (circles and hold outlines) over a photo inside a
/// `ZoomablePhoto`, in photo pixels, and
/// takes the editor's gestures: a tap on empty photo, a tap on a mark,
/// drags of the selected mark and its resize handle, and on a selected
/// outline its point handles. Without callbacks it only draws (the problem
/// view).
///
/// Strokes and handles are divided by the zoom, so they stay the same size
/// on screen; unselected marks stay at least [kMinHitScreenPx] to hit.
class MarkLayer extends StatelessWidget {
  final Size                     photo;
  final TransformationController controller;
  final List<EditMark>           marks;
  final String?                  selectedId;

  /// A tap on the photo away from every mark, in photo pixels.
  final ValueChanged<Offset>? onTapEmpty;
  final ValueChanged<String>? onTapMark;

  /// The selected mark dragged by a delta in photo pixels.
  final void Function(String id, Offset delta)? onMove;

  /// The selected mark's handle dragged by a horizontal delta in photo px.
  final void Function(String id, double delta)? onResize;

  /// A point of the selected outline dragged by a delta in photo pixels.
  final void Function(String id, int index, Offset delta)? onMovePoint;

  /// A midpoint of the selected outline tapped: a point to add on the edge
  /// after point `after`, at `at` in photo pixels.
  final void Function(String id, int after, Offset at)? onAddPoint;

  /// A point of the selected outline double-tapped, to remove it.
  final void Function(String id, int index)? onRemovePoint;

  /// True while the selected mark or one of its handles is pressed.
  final ValueChanged<bool>? onHold;

  const MarkLayer({
    super.key,
    required this.photo,
    required this.controller,
    required this.marks,
    this.selectedId,
    this.onTapEmpty,
    this.onTapMark,
    this.onMove,
    this.onResize,
    this.onMovePoint,
    this.onAddPoint,
    this.onRemovePoint,
    this.onHold,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final zoom = controller.value.getMaxScaleOnAxis();
          return Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                // Only a tap: no double-tap handler, which would delay
                // every tap while it waits for a second one.
                onTapUp: onTapEmpty == null
                    ? null
                    : (d) => onTapEmpty!(d.localPosition),
              ),
            ),
            // Selected last: it paints on top and wins hit tests.
            for (final m in marks) _markWidget(m, zoom),
          ]);
        },
      );

  Widget _markWidget(EditMark m, double zoom) {
    final selected = m.id == selectedId;
    final centre   = centrePx(m.cx, m.cy, photo);
    final rPx      = radiusPx(m.r, photo);
    final hitR     = hitRadiusPx(rPx, zoom);
    final handle   = kHandleScreenPx / zoom;
    final half     = math.max(hitR, rPx + handle);
    final canMove  = selected && onMove != null;

    void hold(bool h) => onHold?.call(h);

    return Positioned(
      key:    ValueKey(m.id),
      left:   centre.dx - half,
      top:    centre.dy - half,
      width:  half * 2,
      height: half * 2,
      child: Stack(children: [
        Positioned.fill(
          child: Listener(
            onPointerDown:   canMove ? (_) => hold(true)  : null,
            onPointerUp:     canMove ? (_) => hold(false) : null,
            onPointerCancel: canMove ? (_) => hold(false) : null,
            child: GestureDetector(
              onTap: onTapMark == null ? null : () => onTapMark!(m.id),
              // From the pointer-down, so the drag doesn't lose the slop
              // and the mark ends where the finger does.
              dragStartBehavior: DragStartBehavior.down,
              onPanUpdate: canMove ? (d) => onMove!(m.id, d.delta) : null,
              child: CustomPaint(
                painter: _MarkPainter(
                    m.role,
                    // The shape in this box's own coordinates.
                    markPath(m.cx, m.cy, m.r, m.outline, photo)
                        .shift(Offset(half, half) - centre),
                    rPx, half, zoom,
                    outline:  m.outline,
                    selected: selected),
              ),
            ),
          ),
        ),
        if (selected && m.outline != null && onMovePoint != null)
          ..._pointHandles(m, Offset(half, half) - centre, zoom, hold),
        if (selected && onResize != null)
          Positioned(
            left:   half + rPx - handle / 2,
            top:    half - handle / 2,
            width:  handle,
            height: handle,
            child: Listener(
              onPointerDown:   (_) => hold(true),
              onPointerUp:     (_) => hold(false),
              onPointerCancel: (_) => hold(false),
              child: GestureDetector(
                key: const ValueKey('resize-handle'),
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onPanUpdate: (d) => onResize!(m.id, d.delta.dx),
                child: Center(
                  child: Container(
                    width:  handle * 0.6,
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
}

extension on MarkLayer {
  /// The selected outline's point handles, and a midpoint dot on each edge
  /// long enough to hold one, placed by [shift] from photo pixels into the
  /// mark's box. A point closer than a handle (on screen) to the last one
  /// shown has none: at fit zoom a traced outline's points would crowd, and
  /// zooming in gives more of them handles.
  List<Widget> _pointHandles(
      EditMark m, Offset shift, double zoom, void Function(bool) hold) {
    final pts  = outlinePx(m.outline!, photo);
    final size = kPointScreenPx / zoom;
    final shown = <int>[];
    for (var i = 0; i < pts.length; i++) {
      if (shown.isEmpty ||
          ((pts[i] - pts[shown.last]).distance >= size &&
           (pts[i] - pts[shown.first]).distance >= size)) {
        shown.add(i);
      }
    }

    // Keyed, so a handle keeps its drag while the dots around it come and
    // go as edges grow and shrink.
    Widget box(Key key, Offset at, Widget child) => Positioned(
          key:    key,
          left:   at.dx + shift.dx - size / 2,
          top:    at.dy + shift.dy - size / 2,
          width:  size,
          height: size,
          child:  child,
        );
    Widget dot(double d, Color fill) => Center(
          child: Container(
            width:  d / zoom,
            height: d / zoom,
            decoration: BoxDecoration(
              color:  fill,
              shape:  BoxShape.circle,
              border: Border.all(color: Colors.black, width: 1.5 / zoom),
            ),
          ),
        );

    return [
      // Midpoints first, so a point wins where they meet.
      for (var k = 0; k < shown.length; k++)
        if (onAddPoint != null &&
            shown[(k + 1) % shown.length] == (shown[k] + 1) % pts.length &&
            (pts[(shown[k] + 1) % pts.length] - pts[shown[k]]).distance >=
                2 * size)
          box(
            ValueKey('mid-${shown[k]}'),
            (pts[shown[k]] + pts[(shown[k] + 1) % pts.length]) / 2,
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onAddPoint!(m.id, shown[k],
                  (pts[shown[k]] + pts[(shown[k] + 1) % pts.length]) / 2),
              child: dot(8, Colors.white70),
            ),
          ),
      for (final i in shown)
        box(
          ValueKey('point-$i'),
          pts[i],
          Listener(
            onPointerDown:   (_) => hold(true),
            onPointerUp:     (_) => hold(false),
            onPointerCancel: (_) => hold(false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              dragStartBehavior: DragStartBehavior.down,
              onPanUpdate: (d) => onMovePoint!(m.id, i, d.delta),
              onDoubleTap: onRemovePoint == null || pts.length <= 3
                  ? null
                  : () => onRemovePoint!(m.id, i),
              child: dot(11, Colors.white),
            ),
          ),
        ),
    ];
  }
}

class _MarkPainter extends CustomPainter {
  final Role     role;
  final Path     path;
  final double   rPx;
  final double   half;
  final double   zoom;
  final Outline? outline;
  final bool     selected;

  _MarkPainter(this.role, this.path, this.rPx, this.half, this.zoom,
      {required this.outline, required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = (selected ? 3.5 : 2.5) / zoom;
    if (selected) {
      // A white rim outside the halo: around a circle, a ring just outside
      // it; around an outline, a wider stroke under the halo.
      if (outline == null) {
        canvas.drawCircle(Offset(half, half), rPx + 4 / zoom, Paint()
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 1.5 / zoom
          ..color       = Colors.white);
      } else {
        canvas.drawPath(path, Paint()
          ..style       = PaintingStyle.stroke
          ..strokeWidth = stroke * 2.2 + 3 / zoom
          ..strokeJoin  = StrokeJoin.round
          ..color       = Colors.white);
      }
    }
    strokeMark(canvas, path, roleColors[role]!, stroke);
  }

  /// Inside the shape, or near enough its centre that a small mark stays
  /// [kMinHitScreenPx] easy to hit.
  @override
  bool hitTest(Offset position) => outline == null
      ? hitsMark(position, Offset(half, half), rPx, zoom)
      : path.contains(position) ||
          hitsMark(position, Offset(half, half), 0, zoom);

  @override
  bool shouldRepaint(_MarkPainter o) =>
      o.role != role || o.rPx != rPx || o.zoom != zoom ||
      o.selected != selected || o.half != half || o.outline != outline;
}
