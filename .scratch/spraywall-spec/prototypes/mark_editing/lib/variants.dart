// PROTOTYPE — throwaway. Four structurally different ways to mark holds.

import 'package:flutter/material.dart';

import 'viewer.dart';

const _bottomPad = 72.0; // clear the floating variant switcher

Widget _panel(Widget child) => Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, _bottomPad),
      child: Material(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(8), child: child),
      ),
    );

Widget _roleDot(Role r, {double size = 14}) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: roleColor[r]!, width: 3)),
    );

// ─── A: role palette (role first), tap to place, handles ───────────────────
class VariantA extends StatefulWidget {
  const VariantA({super.key});
  static const name = 'Role palette';
  @override
  State<VariantA> createState() => _VariantAState();
}

class _VariantAState extends State<VariantA> {
  final tc = TransformationController();
  bool pan = true;
  Role brush = Role.hand;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: marks,
      builder: (context, _) {
        final sel = marks.selected;
        return Stack(children: [
          PhotoViewer(
            controller: tc,
            panEnabled: pan,
            onTapEmpty: (p) {
              final m = marks.add(
                  brush, p.dx / photoW, p.dy / photoH, marks.lastR);
              marks.select(m.id);
            },
            overlay: (zoom) => [
              for (final m in marks.ordered)
                markWidget(m,
                    zoom: zoom,
                    selected: m.id == marks.selectedId,
                    onTap: () => marks.select(m.id),
                    onMove: m.id == marks.selectedId
                        ? (dx, dy) {
                            m.cx += dx;
                            m.cy += dy;
                            marks.changed();
                          }
                        : null,
                    onResize: (dr) {
                      m.r = (m.r + dr).clamp(0.003, 0.15);
                      marks.lastR = m.r;
                      marks.changed();
                    },
                    onHold: (h) => setState(() => pan = !h)),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _panel(Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final r in Role.values)
                  ChoiceChip(
                    avatar: _roleDot(r),
                    label: Text(r.name),
                    selected: (sel?.role ?? brush) == r,
                    onSelected: (_) {
                      setState(() => brush = r);
                      if (sel != null) {
                        sel.role = r;
                        marks.changed();
                      }
                    },
                  ),
                if (sel != null) ...[
                  IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => marks.remove(context, sel)),
                  IconButton(
                      tooltip: 'Done',
                      icon: const Icon(Icons.check),
                      onPressed: () => marks.select(null)),
                ],
              ],
            )),
          ),
        ]);
      },
    );
  }
}

// ─── B: tap places a hand mark, tap a mark cycles its role, zoom = size ────
class VariantB extends StatefulWidget {
  const VariantB({super.key});
  static const name = 'Tap to cycle, zoom sets size';
  @override
  State<VariantB> createState() => _VariantBState();
}

class _VariantBState extends State<VariantB> {
  final tc = TransformationController();
  bool pan = true;
  static const screenR = 18.0; // new marks are this many screen px
  // finish → (removed): the cycle ends by deleting the mark (with undo).
  static const cycle = {
    Role.hand: Role.foot,
    Role.foot: Role.start,
    Role.start: Role.finish,
  };

  @override
  void initState() {
    super.initState();
    marks.select(null);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: marks,
      builder: (context, _) => Stack(children: [
        PhotoViewer(
          controller: tc,
          panEnabled: pan,
          onTapEmpty: (p) {
            if (marks.selectedId != null) return marks.select(null);
            final zoom = tc.value.getMaxScaleOnAxis();
            marks.add(Role.hand, p.dx / photoW, p.dy / photoH,
                screenR / zoom / photoW);
          },
          overlay: (zoom) => [
            for (final m in marks.ordered)
              markWidget(m,
                  zoom: zoom,
                  selected: m.id == marks.selectedId,
                  onTap: () {
                    final next = cycle[m.role];
                    if (next == null) return marks.remove(context, m);
                    m.role = next;
                    marks.changed();
                  },
                  // Long-press / right-click: select to move & resize.
                  onLongPress: () => marks.select(m.id),
                  onMove: m.id == marks.selectedId
                      ? (dx, dy) {
                          m.cx += dx;
                          m.cy += dy;
                          marks.changed();
                        }
                      : null,
                  onResize: (dr) {
                    m.r = (m.r + dr).clamp(0.003, 0.15);
                    marks.changed();
                  },
                  onHold: (h) => setState(() => pan = !h)),
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _panel(Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              for (final r in [Role.hand, Role.foot, Role.start, Role.finish]) ...[
                _roleDot(r),
                const SizedBox(width: 4),
                Text(r.name),
                const Text('  →  '),
              ],
              const Icon(Icons.delete_outline, size: 16),
            ]),
            const SizedBox(height: 4),
            const Text(
                'Tap photo: add hand · Tap mark: next role (after finish: removed)\n'
                'Long-press / right-click mark: select to move & resize · '
                'New marks are 18 screen px: zoom in for small holds',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12)),
          ])),
        ),
      ]),
    );
  }
}

// ─── C: fixed crosshair; pan the wall under it, then drop a role ───────────
class VariantC extends StatefulWidget {
  const VariantC({super.key});
  static const name = 'Crosshair';
  @override
  State<VariantC> createState() => _VariantCState();
}

class _VariantCState extends State<VariantC> {
  final tc = TransformationController();
  Size vp = Size.zero;
  double reticleR = marks.lastR;
  int? carrying;

  Offset get centreScene => tc.toScene(vp.center(Offset.zero));

  @override
  void initState() {
    super.initState();
    marks.select(null);
    tc.addListener(_follow);
  }

  @override
  void dispose() {
    tc.removeListener(_follow);
    super.dispose();
  }

  // While carrying, the mark stays under the crosshair as the wall pans.
  void _follow() {
    final m = marks.selected;
    if (carrying == null || m == null) return;
    final c = centreScene;
    m.cx = c.dx / photoW;
    m.cy = c.dy / photoH;
    marks.changed();
  }

  void _pickUp(Mark m) {
    final s = tc.value.getMaxScaleOnAxis();
    tc.value = Matrix4.diagonal3Values(s, s, 1)
      ..setTranslationRaw(vp.width / 2 - m.cx * photoW * s,
          vp.height / 2 - m.cy * photoH * s, 0);
    setState(() {
      carrying = m.id;
      reticleR = m.r;
    });
    marks.select(m.id);
  }

  void _putDown() {
    setState(() => carrying = null);
    marks.select(null);
  }

  void _setSize(double r) {
    setState(() => reticleR = r);
    marks.lastR = r;
    final m = marks.selected;
    if (carrying != null && m != null) {
      m.r = r;
      marks.changed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      vp = box.biggest;
      return ListenableBuilder(
        listenable: marks,
        builder: (context, _) {
          final sel = carrying == null ? null : marks.selected;
          return Stack(children: [
            PhotoViewer(
              controller: tc,
              onTapEmpty: carrying == null ? null : (_) => _putDown(),
              overlay: (zoom) => [
                for (final m in marks.ordered)
                  markWidget(m,
                      zoom: zoom,
                      selected: m.id == carrying,
                      onTap: () =>
                          m.id == carrying ? _putDown() : _pickUp(m)),
              ],
            ),
            IgnorePointer(
              child: ListenableBuilder(
                listenable: tc,
                builder: (context, _) => CustomPaint(
                  size: vp,
                  painter: _Reticle(
                      reticleR * photoW * tc.value.getMaxScaleOnAxis(),
                      carrying == null),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _panel(Column(mainAxisSize: MainAxisSize.min, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.circle_outlined, size: 14),
                  SizedBox(
                    width: 220,
                    child: Slider(
                      min: 0.004,
                      max: 0.08,
                      value: reticleR.clamp(0.004, 0.08),
                      onChanged: _setSize,
                    ),
                  ),
                  const Icon(Icons.circle_outlined, size: 28),
                ]),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final r in Role.values)
                    sel == null
                        ? FilledButton.tonalIcon(
                            icon: _roleDot(r),
                            label: Text(r.name),
                            onPressed: () {
                              final c = centreScene;
                              marks.add(r, c.dx / photoW, c.dy / photoH,
                                  reticleR);
                            },
                          )
                        : ChoiceChip(
                            avatar: _roleDot(r),
                            label: Text(r.name),
                            selected: sel.role == r,
                            onSelected: (_) {
                              sel.role = r;
                              marks.changed();
                            }),
                  if (sel != null) ...[
                    IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          setState(() => carrying = null);
                          marks.remove(context, sel);
                        }),
                    IconButton(
                        tooltip: 'Put down',
                        icon: const Icon(Icons.check),
                        onPressed: _putDown),
                  ],
                ]),
                Text(
                    sel == null
                        ? 'Pan the hold under the crosshair, then drop a role · tap a mark to pick it up'
                        : 'Carrying: pan to move it, slider to resize',
                    style: const TextStyle(fontSize: 12)),
              ])),
            ),
          ]);
        },
      );
    });
  }
}

class _Reticle extends CustomPainter {
  _Reticle(this.rScreen, this.idle);
  final double rScreen;
  final bool idle;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final halo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = Colors.black54;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white;
    for (final p in [halo, line]) {
      if (idle) canvas.drawCircle(c, rScreen, p);
      const gap = 6.0, len = 14.0;
      final o = rScreen + gap;
      canvas.drawLine(c + Offset(o, 0), c + Offset(o + len, 0), p);
      canvas.drawLine(c - Offset(o, 0), c - Offset(o + len, 0), p);
      canvas.drawLine(c + Offset(0, o), c + Offset(0, o + len), p);
      canvas.drawLine(c - Offset(0, o), c - Offset(0, o + len), p);
    }
  }

  @override
  bool shouldRepaint(_Reticle o) => o.rScreen != rScreen || o.idle != idle;
}

// ─── D: long-press / right-click opens a radial role menu; taps never add ──
class VariantD extends StatefulWidget {
  const VariantD({super.key});
  static const name = 'Long-press radial menu';
  @override
  State<VariantD> createState() => _VariantDState();
}

class _VariantDState extends State<VariantD> {
  final tc = TransformationController();
  bool pan = true;
  Offset? menuAt; // photo px
  Role? hover;
  static const menuR = 72.0;
  // Mnemonic directions: finish up, foot down, start left, hand right.
  static const dirs = {
    Role.finish: Offset(0, -1),
    Role.foot: Offset(0, 1),
    Role.start: Offset(-1, 0),
    Role.hand: Offset(1, 0),
  };

  Offset _toScreen(Offset photoPx) =>
      MatrixUtils.transformPoint(tc.value, photoPx);

  void _place(Role r) {
    final p = menuAt!;
    final m = marks.add(r, p.dx / photoW, p.dy / photoH, marks.lastR);
    marks.select(m.id);
    setState(() {
      menuAt = null;
      hover = null;
    });
  }

  void _open(Offset p) {
    marks.select(null);
    setState(() {
      menuAt = p;
      hover = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: marks,
      builder: (context, _) {
        final sel = marks.selected;
        return Stack(children: [
          PhotoViewer(
            controller: tc,
            panEnabled: pan,
            onTapEmpty: (_) {
              setState(() => menuAt = null);
              marks.select(null);
            },
            onLongPressEmpty: _open,
            onSecondaryTapEmpty: _open,
            onLongPressMove: (p) {
              if (menuAt == null) return;
              final v = (p - menuAt!) * tc.value.getMaxScaleOnAxis();
              Role? h;
              if (v.distance > 28) {
                h = dirs.entries
                    .reduce((a, b) => _dot(a.value, v) > _dot(b.value, v) ? a : b)
                    .key;
              }
              if (h != hover) setState(() => hover = h);
            },
            onLongPressEnd: () {
              if (hover != null) _place(hover!);
            },
            overlay: (zoom) => [
              for (final m in marks.ordered)
                markWidget(m,
                    zoom: zoom,
                    selected: m.id == marks.selectedId,
                    onTap: () {
                      setState(() => menuAt = null);
                      marks.select(m.id);
                    },
                    onMove: m.id == marks.selectedId
                        ? (dx, dy) {
                            m.cx += dx;
                            m.cy += dy;
                            marks.changed();
                          }
                        : null,
                    onResize: (dr) {
                      m.r = (m.r + dr).clamp(0.003, 0.15);
                      marks.lastR = m.r;
                      marks.changed();
                    },
                    onHold: (h) => setState(() => pan = !h)),
              if (menuAt != null)
                Positioned(
                  left: menuAt!.dx - marks.lastR * photoW,
                  top: menuAt!.dy - marks.lastR * photoW,
                  width: marks.lastR * photoW * 2,
                  height: marks.lastR * photoW * 2,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white, width: 2 / zoom),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Screen-space overlays that follow the photo transform.
          ListenableBuilder(
            listenable: tc,
            builder: (context, _) {
              final kids = <Widget>[];
              if (menuAt != null) {
                final c = _toScreen(menuAt!);
                for (final e in dirs.entries) {
                  final p = c + e.value * menuR;
                  kids.add(Positioned(
                    left: p.dx - 30,
                    top: p.dy - 30,
                    width: 60,
                    height: 60,
                    child: Material(
                      shape: const CircleBorder(),
                      color: hover == e.key
                          ? roleColor[e.key]
                          : Colors.black.withValues(alpha: 0.8),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _place(e.key),
                        child: Center(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _roleDot(e.key),
                                Text(e.key.name,
                                    style: const TextStyle(fontSize: 11)),
                              ]),
                        ),
                      ),
                    ),
                  ));
                }
              }
              if (sel != null && menuAt == null) {
                final top =
                    _toScreen(Offset(sel.cx * photoW, sel.cy * photoH - sel.r * photoW));
                kids.add(Positioned(
                  left: top.dx - 110,
                  top: top.dy - 64,
                  width: 220,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final r in Role.values)
                            IconButton(
                              tooltip: r.name,
                              isSelected: sel.role == r,
                              icon: _roleDot(r, size: sel.role == r ? 22 : 16),
                              onPressed: () {
                                sel.role = r;
                                marks.changed();
                              },
                            ),
                          IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => marks.remove(context, sel)),
                        ]),
                  ),
                ));
              }
              return Stack(children: kids);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _panel(const Text(
                'Long-press / right-click photo: role menu (flick or tap) · '
                'Tap mark: select · Tap photo: deselect',
                style: TextStyle(fontSize: 12))),
          ),
        ]);
      },
    );
  }
}

double _dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

