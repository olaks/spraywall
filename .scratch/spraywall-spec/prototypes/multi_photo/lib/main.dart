// PROTOTYPE — throwaway (wayfinder ticket 09: a problem across several wall
// photos). Three ways to move between photos, each in the problem view, the
// editor for an existing problem and the editor for a new problem.
// Switch variants with the bottom bar, ←/→, `?variant=A..C` (web) or
// `--dart-define=VARIANT=B`.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'model.dart';
import 'variants.dart';
import 'viewer.dart';

void main() => runApp(const ProtoApp());

const variantKeys = ['A', 'B', 'C'];
const variantNames = {
  'A': VariantA.name,
  'B': VariantB.name,
  'C': VariantC.name,
};

class ProtoApp extends StatelessWidget {
  const ProtoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
        home: const Shell(),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late String variant = () {
    final v = (Uri.base.queryParameters['variant'] ??
            const String.fromEnvironment('VARIANT', defaultValue: 'A'))
        .toUpperCase();
    return variantKeys.contains(v) ? v : 'A';
  }();

  void _go(int step) {
    final i = variantKeys.indexOf(variant);
    final next = variantKeys[(i + step) % variantKeys.length];
    setState(() => variant = next);
    store.select(null);
    SystemNavigator.routeInformationUpdated(
        uri: Uri(path: '/', queryParameters: {'variant': next}),
        replace: true);
  }

  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _go(-1);
      return true;
    }
    if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
      _go(1);
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (variant) {
      'B' => const VariantB(),
      'C' => const VariantC(),
      _ => const VariantA(),
    };
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(switch (store.mode) {
            Mode.view => 'Red crimps · 6B',
            Mode.edit => 'Edit: Red crimps',
            Mode.create => 'New problem',
          }),
          actions: [
            SegmentedButton<Mode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: Mode.view,
                    icon: Icon(Icons.visibility_outlined),
                    tooltip: 'Problem view'),
                ButtonSegment(
                    value: Mode.edit,
                    icon: Icon(Icons.edit_outlined),
                    tooltip: 'Editor (existing problem)'),
                ButtonSegment(
                    value: Mode.create,
                    icon: Icon(Icons.add),
                    tooltip: 'Editor (new problem)'),
              ],
              selected: {store.mode},
              onSelectionChanged: (s) => store.setMode(s.first),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'rule':
                    store.openRule = store.openRule == OpenRule.startMarks
                        ? OpenRule.firstMarked
                        : OpenRule.startMarks;
                    store.reopen();
                  case 'hide':
                    store.hideUnmarked = !store.hideUnmarked;
                    store.reopen();
                  case 'reopen':
                    store.reopen();
                }
              },
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                    value: 'rule',
                    checked: store.openRule == OpenRule.startMarks,
                    child: const Text('View opens on the start marks')),
                CheckedPopupMenuItem(
                    value: 'hide',
                    checked: store.hideUnmarked,
                    child: const Text('View hides photos without marks')),
                const PopupMenuItem(
                    value: 'reopen', child: Text('Reopen the view')),
              ],
            ),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: Stack(children: [
              KeyedSubtree(key: ValueKey(variant), child: body),
              const StatePanel(),
            ]),
          ),
          if (!kReleaseMode) _switcher(),
        ]),
      ),
    );
  }

  Widget _switcher() => ColoredBox(
        color: Colors.black,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Center(
              child: Material(
                color: Colors.white,
                elevation: 8,
                shape: const StadiumBorder(),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      color: Colors.black,
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _go(-1)),
                  Text('$variant (${variantNames[variant]})',
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  IconButton(
                      color: Colors.black,
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _go(1)),
                ]),
              ),
            ),
          ),
        ),
      );
}

/// Full state, top-left. Tap to collapse.
class StatePanel extends StatefulWidget {
  const StatePanel({super.key});
  @override
  State<StatePanel> createState() => _StatePanelState();
}

class _StatePanelState extends State<StatePanel> {
  bool open = true;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ListenableBuilder(
          listenable: Listenable.merge([store, zoomedIn, holding]),
          builder: (context, _) {
            final s = store.selected;
            final text = open
                ? [
                    'mode ${store.mode.name} · showing ${store.current}',
                    'opened: ${store.openedWhy}',
                    'moves between: ${store.visible.map((p) => p.id).join(', ')}',
                    for (final p in photos)
                      '  ${p.id.padRight(6)} ${Role.values.map((r) => '${r.name[0]}${store.marksOn(p.id).where((m) => m.role == r).length}').join(' ')}',
                    'selected: ${s == null ? 'none' : '#${s.id} ${s.role.name} on ${s.photoId}'}',
                    'zoomed in: ${zoomedIn.value.join(', ')}${holding.value ? ' · holding' : ''}',
                  ].join('\n')
                : 'state ▸';
            return Material(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => setState(() => open = !open),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(text,
                      style: const TextStyle(
                          fontSize: 10, fontFamily: 'monospace')),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
