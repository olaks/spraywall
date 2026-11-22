import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../database/database.dart';
import '../../providers/app_providers.dart';
import '../../providers/backup_provider.dart';
import '../../widgets/wide.dart';
import 'new_wall_dialog.dart';

/// The root screen: every wall, in the user's order. Shown even with a single
/// wall, so there is always one obvious place to add another.
class WallListScreen extends ConsumerWidget {
  const WallListScreen({super.key});

  Future<void> _newWall(BuildContext context, WidgetRef ref) async {
    final id = await showDialog<String>(
      context: context,
      builder: (_) => NewWallDialog(db: ref.read(dbProvider)),
    );
    // Straight into the new wall: the next thing to do there is add a photo.
    if (id != null && context.mounted) context.go('/walls/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walls = ref.watch(wallsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walls', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon:      const Icon(Icons.settings),
            tooltip:   'Settings',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      floatingActionButton: (walls.value?.isNotEmpty ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => _newWall(context, ref),
              icon:      const Icon(Icons.add),
              label:     const Text('New wall'),
            )
          : null,
      body: walls.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('$e')),
        data:    (list) => list.isEmpty
            ? _FirstRun(onCreate: () => _newWall(context, ref))
            : Column(children: [
                const _BackupNudge(),
                Expanded(child: _WallList(walls: list)),
              ]),
      ),
    );
  }
}

/// The walls with drag handles. Dropping one writes the whole order.
class _WallList extends ConsumerWidget {
  final List<Wall> walls;
  const _WallList({required this.walls});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ReadableWidth(
      builder: (context, sides) => ReorderableListView(
        buildDefaultDragHandles: false,
        // Room for the FAB under the last row.
        padding: sides + const EdgeInsets.only(bottom: 88),
        onReorder: (from, to) {
          final ids = [for (final w in walls) w.id];
          final id  = ids.removeAt(from);
          ids.insert(to > from ? to - 1 : to, id);
          ref.read(dbProvider).reorderWalls(ids);
        },
        children: [
          for (final (i, w) in walls.indexed)
            ListTile(
              key:      ValueKey(w.id),
              title:    Text(w.name),
              subtitle: Text(gradeScaleLabel(w.gradeScale)),
              trailing: ReorderableDragStartListener(
                index: i,
                child: const Icon(Icons.drag_handle),
              ),
              onTap:    () => context.go('/walls/${w.id}'),
            ),
        ],
      ));
}

/// Nothing here syncs anywhere, so this is the one reminder the app gives: a
/// quiet line once the last full export is a month behind (or never
/// happened), dismissable for a week at a time.
class _BackupNudge extends ConsumerWidget {
  const _BackupNudge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(backupProvider);
    final now    = ref.watch(clockProvider)();
    if (!status.needsReminder(now)) return const SizedBox.shrink();

    final days  = status.daysSinceBackup(now);
    final color = Theme.of(context).colorScheme.error;
    return Material(
      key:   const ValueKey('backup-nudge'),
      color: color.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: Row(children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(days == null
                ? 'Your walls have never been backed up.'
                : 'Last backup was $days days ago.'),
          ),
          TextButton(
            onPressed: () => context.go('/settings'),
            child: const Text('Back up'),
          ),
          IconButton(
            tooltip:   'Remind me later',
            icon:      const Icon(Icons.close, size: 18),
            onPressed: () =>
                ref.read(backupProvider.notifier).snoozeReminder(now),
          ),
        ]),
      ),
    );
  }
}

String gradeScaleLabel(GradeScale s) => switch (s) {
      GradeScale.font => 'Font grades',
      GradeScale.v    => 'V grades',
    };

class _FirstRun extends StatelessWidget {
  final VoidCallback onCreate;
  const _FirstRun({required this.onCreate});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.landscape_outlined,
                  size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              const Text(
                'Set problems on your spray wall by marking holds on photos of it.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCreate,
                icon:      const Icon(Icons.add),
                label:     const Text('Create your first wall'),
              ),
            ],
          ),
        ),
      );
}
