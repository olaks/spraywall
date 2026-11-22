import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../database/database.dart';
import '../../providers/app_providers.dart';
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
            : ListView(
                children: [
                  for (final w in list)
                    ListTile(
                      title:    Text(w.name),
                      subtitle: Text(gradeScaleLabel(w.gradeScale)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap:    () => context.go('/walls/${w.id}'),
                    ),
                ],
              ),
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
