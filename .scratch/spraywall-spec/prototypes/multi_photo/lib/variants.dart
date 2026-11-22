// PROTOTYPE — throwaway. Three structurally different ways to move between
// a layout's wall photos, in the problem view and in the editor.
import 'package:flutter/material.dart';

import 'model.dart';
import 'viewer.dart';

// ─── A: swipe between full-screen photos (PageView) ────────────────────────
// Swipe is off while the photo is zoomed in, while a mark is selected, and
// with a mouse (Flutter doesn't drag-scroll with a mouse); the ‹ › arrows
// always work. View hides photos without marks (menu toggle).
class VariantA extends StatefulWidget {
  const VariantA({super.key});
  static const name = 'Swipe pages';
  @override
  State<VariantA> createState() => _VariantAState();
}

class _VariantAState extends State<VariantA> {
  late PageController pc = PageController(initialPage: _index);
  String _shown = store.current;
  List<String> _ids = store.visible.map((p) => p.id).toList();

  int get _index =>
      store.visible.indexWhere((p) => p.id == store.current).clamp(0, 99);

  void _onStore() {
    final ids = store.visible.map((p) => p.id).toList();
    final listChanged = ids.join() != _ids.join();
    _ids = ids;
    // Jump when the store moved the photo itself (mode switch, reopen).
    if ((store.current != _shown || listChanged) && pc.hasClients) {
      _shown = store.current;
      pc.jumpToPage(_index);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    store.addListener(_onStore);
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    pc.dispose();
    super.dispose();
  }

  void _step(int d) {
    final i = (_index + d).clamp(0, store.visible.length - 1);
    pc.animateToPage(i,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final ps = store.visible;
    final wide = isWide(context);
    final pages = ListenableBuilder(
      listenable: Listenable.merge([zoomedIn, holding]),
      builder: (context, _) {
        final locked = zoomedIn.value.contains(store.current) ||
            holding.value ||
            (store.editing && store.selectedId != null);
        return Stack(children: [
          PageView(
            controller: pc,
            physics: locked
                ? const NeverScrollableScrollPhysics()
                : const PageScrollPhysics(),
            onPageChanged: (i) {
              _shown = ps[i].id;
              store.show(ps[i].id);
            },
            children: [
              for (final p in ps)
                MarkCanvas(
                    key: ValueKey(p.id), photo: p, editable: store.editing),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.black.withValues(alpha: 0.7),
                shape: const StadiumBorder(),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _index > 0 ? () => _step(-1) : null),
                  for (final p in ps)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                          p.id == store.current
                              ? Icons.circle
                              : Icons.circle_outlined,
                          size: 10,
                          color: store.marksOn(p.id).isEmpty
                              ? Colors.white38
                              : Colors.white),
                    ),
                  const SizedBox(width: 6),
                  Text(
                      '${photoById(store.current).label} · ${_index + 1}/${ps.length}'
                      '${locked ? '  🔒' : ''}'),
                  IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed:
                          _index < ps.length - 1 ? () => _step(1) : null),
                ]),
              ),
            ),
          ),
        ]);
      },
    );
    if (!store.editing) return pages;
    return wide
        ? Row(children: [
            const SizedBox(width: 150, child: RolePalette(vertical: true)),
            Expanded(child: pages),
          ])
        : Column(children: [
            Expanded(child: pages),
            const RolePalette(),
          ]);
  }
}

// ─── B: thumbnail strip ─────────────────────────────────────────────────────
// One photo at a time, picked from a strip of marked thumbnails. No swipe.
// View dims (doesn't hide) photos without marks.
class VariantB extends StatelessWidget {
  const VariantB({super.key});
  static const name = 'Thumbnail strip';

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final canvas = MarkCanvas(
            key: ValueKey(store.current),
            photo: photoById(store.current),
            editable: store.editing);
        final strip = _Strip(vertical: wide);
        if (wide) {
          return Row(children: [
            SizedBox(width: 130, child: strip),
            Expanded(child: canvas),
            if (store.editing)
              const SizedBox(width: 150, child: RolePalette(vertical: true)),
          ]);
        }
        return Column(children: [
          Expanded(child: canvas),
          SizedBox(height: 92, child: strip),
          if (store.editing) const RolePalette(),
        ]);
      },
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.vertical});
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerLow,
      child: ListView(
        scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
        padding: const EdgeInsets.all(6),
        children: [
          for (final p in photos)
            Opacity(
              opacity:
                  !store.editing && store.marksOn(p.id).isEmpty ? 0.35 : 1,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: InkWell(
                  onTap: () => store.show(p.id),
                  child: Container(
                    width: vertical ? null : 104,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      border: Border.all(
                          width: 2.5,
                          color: p.id == store.current
                              ? scheme.primary
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: StaticPhoto(p, thumb: true)),
                        const SizedBox(height: 2),
                        Text(p.label, style: const TextStyle(fontSize: 11)),
                        FittedBox(child: markCounts(p.id, size: 7)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── C: overview first ──────────────────────────────────────────────────────
// View: the marked photos stacked in one scrolling column, whole and
// unzoomed; tap one to open it zoomable. Editor: a grid of all photos with
// their marks; tap one to edit it full screen, back to return.
class VariantC extends StatelessWidget {
  const VariantC({super.key});
  static const name = 'Overview first';

  void _open(BuildContext context, Photo p) {
    store.show(p.id);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => _SinglePhoto(p),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (!store.editing) {
          final shown = store.visible;
          final hidden = photos.where((p) => !shown.contains(p)).toList();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(padding: const EdgeInsets.all(8), children: [
                for (final p in shown)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _open(context, p),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(p.label,
                                style: Theme.of(context).textTheme.titleSmall),
                            const Spacer(),
                            markCounts(p.id),
                            const Icon(Icons.zoom_in, size: 18),
                          ]),
                          const SizedBox(height: 4),
                          StaticPhoto(p),
                        ],
                      ),
                    ),
                  ),
                if (hidden.isNotEmpty)
                  Text('Not on: ${hidden.map((p) => p.label).join(', ')}',
                      style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          );
        }
        final cols = MediaQuery.sizeOf(context).width >= 600 ? 3 : 2;
        return Column(children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
                store.mode == Mode.create
                    ? 'Pick a photo to start marking'
                    : 'Tap a photo to edit its marks',
                style: Theme.of(context).textTheme.titleSmall),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: cols,
              padding: const EdgeInsets.all(8),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (final p in photos)
                  InkWell(
                    onTap: () => _open(context, p),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(children: [
                        Expanded(
                            child: Center(child: StaticPhoto(p, thumb: true))),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Row(children: [
                            Text(p.label),
                            const SizedBox(width: 6),
                            Expanded(
                              child: FittedBox(
                                  alignment: Alignment.centerRight,
                                  fit: BoxFit.scaleDown,
                                  child: markCounts(p.id)),
                            ),
                          ]),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ]);
      },
    );
  }
}

class _SinglePhoto extends StatelessWidget {
  const _SinglePhoto(this.p);
  final Photo p;

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final canvas = MarkCanvas(photo: p, editable: store.editing);
    return Scaffold(
      appBar: AppBar(title: Text(p.label)),
      body: !store.editing
          ? canvas
          : wide
              ? Row(children: [
                  const SizedBox(width: 150, child: RolePalette(vertical: true)),
                  Expanded(child: canvas),
                ])
              : Column(children: [Expanded(child: canvas), const RolePalette()]),
    );
  }
}
