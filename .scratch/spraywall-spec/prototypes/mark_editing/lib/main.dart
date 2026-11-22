// PROTOTYPE — throwaway (wayfinder ticket 05: mark-editing interaction).
// Four interaction variants on the real wall photo, switchable from the
// floating bottom bar, ←/→ keys, `?variant=A..D` (web) or
// `--dart-define=VARIANT=B` (desktop/Android).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'variants.dart';
import 'viewer.dart';

void main() => runApp(const ProtoApp());

const variantKeys = ['A', 'B', 'C', 'D'];
const variantNames = {
  'A': VariantA.name,
  'B': VariantB.name,
  'C': VariantC.name,
  'D': VariantD.name,
};

class ProtoApp extends StatelessWidget {
  const ProtoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark),
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
    marks.select(null);
    // Updates the browser URL on web (shareable, reload-stable); no-op elsewhere.
    SystemNavigator.routeInformationUpdated(
        uri: Uri(path: '/', queryParameters: {'variant': next}), replace: true);
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
      'D' => const VariantD(),
      _ => const VariantA(),
    };
    return Scaffold(
      body: Stack(children: [
        KeyedSubtree(key: ValueKey(variant), child: body),
        const SafeArea(child: StatePanel()),
        if (!kReleaseMode)
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
      ]),
    );
  }
}

/// Full mark state, top-left. Tap to collapse.
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
          listenable: Listenable.merge([marks, zoomNote]),
          builder: (context, _) {
            final counts = {
              for (final r in Role.values)
                r: marks.list.where((m) => m.role == r).length
            };
            final s = marks.selected;
            final text = open
                ? [
                    'marks ${marks.list.length} · '
                        '${Role.values.map((r) => '${r.name} ${counts[r]}').join(' · ')}',
                    s == null
                        ? 'selected: none'
                        : 'selected #${s.id} ${s.role.name}  cx ${s.cx.toStringAsFixed(3)} '
                            'cy ${s.cy.toStringAsFixed(3)} r ${s.r.toStringAsFixed(4)} '
                            '(${(s.r * photoW).toStringAsFixed(0)} photo px, '
                            '${(s.r * photoW * zoomNote.value).toStringAsFixed(0)} screen px)',
                    'zoom ${zoomNote.value.toStringAsFixed(2)} screen px / photo px',
                  ].join('\n')
                : 'state ▸';
            return Material(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => setState(() => open = !open),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(text,
                        style: const TextStyle(
                            fontSize: 11, fontFamily: 'monospace')),
                    if (open)
                      IconButton(
                          tooltip: 'Clear all marks',
                          iconSize: 18,
                          icon: const Icon(Icons.delete_sweep_outlined),
                          onPressed: marks.clear),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
