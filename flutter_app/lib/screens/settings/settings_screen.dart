import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

/// Things that apply to the whole app. Backup export, import and the backup
/// reminder join the theme here in later slices.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeIdx = ref.watch(themeIndexProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const _SectionLabel('APPEARANCE'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: AccentPicker(
              selected: themeIdx,
              onSelect: (i) =>
                  ref.read(themeIndexProvider.notifier).setTheme(i),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary)),
      );
}

/// The four accent colours, as a row of swatches.
class AccentPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const AccentPicker({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(themeAccents.length, (i) {
          final accent = themeAccents[i];
          final isSelected = selected == i;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.15),
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.black, size: 22)
                      : null,
                ),
                const SizedBox(height: 6),
                Text(accent.name,
                    style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5))),
              ],
            ),
          );
        }),
      );
}
