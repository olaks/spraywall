import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../database/tables.dart' show Role;
import 'mark_editor.dart';
import 'mark_geometry.dart';

/// Draws marks over a photo inside a `ZoomablePhoto`, in photo pixels, and
/// takes the editor's gestures: a tap on empty photo, a tap on a mark, and
/// drags of the selected mark and its resize handle. Without callbacks it
/// only draws (the problem view).
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

  /// True while the selected mark or its handle is pressed.
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
                    m.role, rPx, half, zoom, selected: selected),
              ),
            ),
          ),
        ),
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

class _MarkPainter extends CustomPainter {
  final Role   role;
  final double rPx;
  final double half;
  final double zoom;
  final bool   selected;

  _MarkPainter(this.role, this.rPx, this.half, this.zoom,
      {required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final c      = Offset(half, half);
    final stroke = (selected ? 3.5 : 2.5) / zoom;
    // A dark halo first, so the colour reads on beige wood and plywood alike.
    canvas.drawCircle(c, rPx, Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = stroke * 2.2
      ..color       = Colors.black54);
    canvas.drawCircle(c, rPx, Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color       = roleColors[role]!);
    if (selected) {
      canvas.drawCircle(c, rPx + 4 / zoom, Paint()
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.5 / zoom
        ..color       = Colors.white);
    }
  }

  @override
  bool hitTest(Offset position) =>
      hitsMark(position, Offset(half, half), rPx, zoom);

  @override
  bool shouldRepaint(_MarkPainter o) =>
      o.role != role || o.rPx != rPx || o.zoom != zoom ||
      o.selected != selected || o.half != half;
}
