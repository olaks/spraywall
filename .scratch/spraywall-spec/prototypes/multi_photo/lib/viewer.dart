// PROTOTYPE — throwaway. One zoomable wall photo with Variant A marks from
// ticket 05 (role palette), plus a static marked photo for thumbnails/lists.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'model.dart';

/// Per-photo zoom state, kept across photo switches.
final controllers = <String, TransformationController>{};
TransformationController controllerFor(String id) =>
    controllers.putIfAbsent(id, TransformationController.new);

/// Which photos are currently zoomed past "fit" (blocks page swipes in A).
final zoomedIn = ValueNotifier<Set<String>>({});

/// The fit scale last applied to each photo; "zoomed in" is measured from it.
final _lastFit = <String, double>{};

/// True while a finger/button is down on the selected mark or its handle.
final holding = ValueNotifier<bool>(false);

/// Zoomable photo with this photo's marks. Editable when [editable].
class MarkCanvas extends StatefulWidget {
  const MarkCanvas({super.key, required this.photo, required this.editable});
  final Photo photo;
  final bool editable;

  @override
  State<MarkCanvas> createState() => _MarkCanvasState();
}

class _MarkCanvasState extends State<MarkCanvas> {
  late final tc = controllerFor(widget.photo.id);
  double _fit = 0.2;
  Size? _vp;

  Photo get p => widget.photo;

  void _onZoom() {
    final z = tc.value.getMaxScaleOnAxis() > (_lastFit[p.id] ?? _fit) * 1.05;
    final set = zoomedIn.value;
    if (z == set.contains(p.id)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      zoomedIn.value = z ? ({...set, p.id}) : (set.difference({p.id}));
    });
  }

  @override
  void initState() {
    super.initState();
    tc.addListener(_onZoom);
  }

  @override
  void dispose() {
    tc.removeListener(_onZoom);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final vp = box.biggest;
      _fit = math.min(vp.width / p.w, vp.height / p.h);
      // Fit on first show, or on resize while not zoomed in. Keeps the user's
      // zoom when coming back to a photo.
      final last = _lastFit[p.id];
      final userZoomed =
          last != null && tc.value.getMaxScaleOnAxis() > last * 1.05;
      if (last == null || (_vp != vp && !userZoomed)) {
        _lastFit[p.id] = _fit;
        tc.value = Matrix4.diagonal3Values(_fit, _fit, _fit)
          ..setTranslationRaw(
              (vp.width - p.w * _fit) / 2, (vp.height - p.h * _fit) / 2, 0);
      }
      _vp = vp;
      return ColoredBox(
        color: Colors.black,
        child: ValueListenableBuilder(
          valueListenable: holding,
          builder: (context, hold, _) => InteractiveViewer(
            transformationController: tc,
            constrained: false,
            panEnabled: !hold,
            minScale: _fit * 0.8,
            maxScale: 4,
            boundaryMargin: const EdgeInsets.all(1500),
            child: SizedBox(
              width: p.w,
              height: p.h,
              child: ListenableBuilder(
                listenable: Listenable.merge([tc, store]),
                builder: (context, _) {
                  final zoom = tc.value.getMaxScaleOnAxis();
                  return Stack(clipBehavior: Clip.none, children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: widget.editable
                            ? (d) => store.add(
                                store.brush,
                                p.id,
                                d.localPosition.dx / p.w,
                                d.localPosition.dy / p.h)
                            : null,
                        child: Image.asset(p.asset,
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.medium),
                      ),
                    ),
                    for (final m in store.orderedOn(p.id))
                      _markWidget(m, p, zoom, widget.editable),
                  ]);
                },
              ),
            ),
          ),
        ),
      );
    });
  }
}

Widget _markWidget(Mark m, Photo p, double zoom, bool editable) {
  final selected = editable && m.id == store.selectedId;
  final rPx = m.r * p.w;
  final hitR = math.max(rPx, 20 / zoom);
  final handle = 26 / zoom;
  final half = math.max(hitR, rPx + handle);
  void hold(bool h) => holding.value = h;

  return Positioned(
    key: ValueKey(m.id),
    left: m.cx * p.w - half,
    top: m.cy * p.h - half,
    width: half * 2,
    height: half * 2,
    child: IgnorePointer(
      ignoring: !editable,
      child: Stack(children: [
        Positioned.fill(
          child: Listener(
            onPointerDown: selected ? (_) => hold(true) : null,
            onPointerUp: selected ? (_) => hold(false) : null,
            onPointerCancel: selected ? (_) => hold(false) : null,
            child: GestureDetector(
              onTap: () => store.select(m.id),
              onPanUpdate: selected
                  ? (d) {
                      m.cx += d.delta.dx / p.w;
                      m.cy += d.delta.dy / p.h;
                      store.changed();
                    }
                  : null,
              child: CustomPaint(
                  painter: _MarkPainter(m.role, rPx, hitR, zoom, selected, half)),
            ),
          ),
        ),
        if (selected)
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
                onPanUpdate: (d) {
                  m.r = (m.r + d.delta.dx / p.w).clamp(0.003, 0.15);
                  store.lastR[p.id] = m.r;
                  store.changed();
                },
                child: Center(
                  child: Container(
                    width: handle * 0.6,
                    height: handle * 0.6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: Colors.black, width: 1.5 / zoom),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ]),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(
      this.role, this.rPx, this.hitR, this.zoom, this.selected, this.half);
  final Role role;
  final double rPx, hitR, zoom, half;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final s = (selected ? 3.5 : 2.5) / zoom;
    paintMark(canvas, c, rPx, role, s);
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
  bool hitTest(Offset position) =>
      (position - Offset(half, half)).distance <= hitR;

  @override
  bool shouldRepaint(_MarkPainter o) =>
      o.role != role || o.rPx != rPx || o.zoom != zoom || o.selected != selected;
}

void paintMark(Canvas canvas, Offset c, double r, Role role, double stroke) {
  canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 2.2
        ..color = Colors.black54);
  canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = roleColor[role]!);
}

/// Non-interactive photo with its marks, sized by its parent's width.
class StaticPhoto extends StatelessWidget {
  const StaticPhoto(this.photo, {super.key, this.thumb = false});
  final Photo photo;
  final bool thumb;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: photo.w / photo.h,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => CustomPaint(
          foregroundPainter: _StaticMarks(store.marksOn(photo.id), photo, thumb),
          child: Image.asset(photo.asset,
              fit: BoxFit.fill,
              cacheWidth: thumb ? 384 : null,
              filterQuality: FilterQuality.medium),
        ),
      ),
    );
  }
}

class _StaticMarks extends CustomPainter {
  _StaticMarks(this.marks, this.photo, this.thumb);
  final List<Mark> marks;
  final Photo photo;
  final bool thumb;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / photo.w;
    for (final m in marks) {
      paintMark(canvas, Offset(m.cx * size.width, m.cy * size.height),
          math.max(m.r * photo.w * k, thumb ? 3 : 4), m.role, thumb ? 1.5 : 2.5);
    }
  }

  @override
  bool shouldRepaint(_StaticMarks o) => true;
}

/// Role palette from ticket 05. Horizontal on phones, vertical at ≥ 600 dp.
class RolePalette extends StatelessWidget {
  const RolePalette({super.key, this.vertical = false});
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final sel = store.selected;
        final children = [
          for (final r in Role.values)
            ChoiceChip(
              avatar: roleDot(r),
              label: Text(r.name),
              selected: (sel?.role ?? store.brush) == r,
              onSelected: (_) {
                store.brush = r;
                if (sel != null) sel.role = r;
                store.changed();
              },
            ),
          IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: sel == null ? null : () => store.remove(context, sel)),
          IconButton(
              tooltip: 'Done',
              icon: const Icon(Icons.check),
              onPressed: sel == null ? null : () => store.select(null)),
        ];
        return Material(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: vertical
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final c in children)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: c),
                    ],
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: children),
          ),
        );
      },
    );
  }
}

Widget roleDot(Role r, {double size = 14}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: roleColor[r]!, width: 3)),
    );

/// Little per-role counts, e.g. for a thumbnail badge.
Widget markCounts(String photoId, {double size = 8}) {
  final ms = store.marksOn(photoId);
  if (ms.isEmpty) {
    return const Text('no marks', style: TextStyle(fontSize: 11));
  }
  return Row(mainAxisSize: MainAxisSize.min, children: [
    for (final r in Role.values)
      if (ms.any((m) => m.role == r)) ...[
        roleDot(r, size: size),
        Text(' ${ms.where((m) => m.role == r).length} ',
            style: const TextStyle(fontSize: 11)),
      ],
  ]);
}

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 600;
