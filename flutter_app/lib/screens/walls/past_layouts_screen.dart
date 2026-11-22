import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../database/database.dart';
import '../../providers/app_providers.dart';
import '../../utils/undo_snackbar.dart';
import '../not_found_screen.dart';
import '../../widgets/wide.dart';

/// A wall's archived layouts, newest first: dates, name, and what each
/// holds. Tap opens one read-only; the menu deletes one, with undo.
class PastLayoutsScreen extends ConsumerWidget {
  final String wallId;
  const PastLayoutsScreen({super.key, required this.wallId});

  static String _title(Layout l) =>
      l.name ?? '${l.startedOn} – ${l.endedOn}';

  static String _count(int n, String one) => '$n $one${n == 1 ? '' : 's'}';

  Future<void> _delete(BuildContext context, WidgetRef ref, Layout l) async {
    final db        = ref.read(dbProvider);
    final messenger = ScaffoldMessenger.of(context);
    final deleted   = await db.deleteLayout(l.id);
    showUndoSnackBar(messenger,
        message: 'Deleted "${_title(l)}"',
        onUndo:  () => db.restoreLayout(deleted));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wall = ref.watch(wallProvider(wallId));
    final past = ref.watch(pastLayoutsProvider(wallId));
    if (wall.isLoading || past.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final w = wall.value;
    if (w == null) return const NotFoundScreen();
    final list = past.value!;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Past layouts'),
            Text(w.name, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      body: list.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No past layouts yet. Reset archives the '
                    'current one here.', textAlign: TextAlign.center),
              ),
            )
          : ReadableWidth(builder: (context, sides) => ListView(
              padding: sides,
              children: [
              for (final p in list)
                ListTile(
                  onTap: () =>
                      context.go('/walls/$wallId/layouts/${p.layout.id}'),
                  title: Text(_title(p.layout)),
                  subtitle: Text([
                    if (p.layout.name != null)
                      '${p.layout.startedOn} – ${p.layout.endedOn}',
                    '${_count(p.problems, 'problem')} · '
                        '${_count(p.photos, 'photo')}',
                  ].join('\n')),
                  isThreeLine: p.layout.name != null,
                  trailing: PopupMenuButton<void>(
                    tooltip: 'Layout menu',
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        onTap: () => _delete(context, ref, p.layout),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ),
            ])),
    );
  }
}
