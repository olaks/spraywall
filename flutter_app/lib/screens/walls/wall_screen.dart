import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../database/database.dart';
import '../../providers/app_providers.dart';
import '../../utils/undo_snackbar.dart';
import '../not_found_screen.dart';
import 'edit_wall_dialog.dart';

/// A wall's current layout. For now only its frame: photos and the problem
/// list arrive in later slices.
class WallScreen extends ConsumerWidget {
  final String wallId;
  const WallScreen({super.key, required this.wallId});

  Future<void> _editWall(BuildContext context, WidgetRef ref, Wall wall) async {
    // Captured up front: the undo can be tapped after this screen is gone.
    final db        = ref.read(dbProvider);
    final messenger = ScaffoldMessenger.of(context);
    final hasGrades = await db.wallHasGrades(wall.id);
    if (!context.mounted) return;
    final result = await showDialog<EditWallResult>(
      context: context,
      builder: (_) => EditWallDialog(db: db, wall: wall, hasGrades: hasGrades),
    );
    if (result != EditWallResult.deleted || !context.mounted) return;

    // Leave before deleting, so this screen never shows the wall as missing.
    context.go('/');
    final deleted = await db.deleteWall(wall.id);
    showUndoSnackBar(messenger,
        message: 'Deleted "${wall.name}"',
        onUndo:  () => db.restoreWall(deleted));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wall   = ref.watch(wallProvider(wallId));
    final layout = ref.watch(currentLayoutProvider(wallId));

    if (wall.isLoading || layout.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final w = wall.value;
    final l = layout.value;
    if (w == null || l == null) return const NotFoundScreen();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(l.name ?? 'Since ${l.startedOn}',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          PopupMenuButton<void>(
            tooltip: 'Wall menu',
            itemBuilder: (_) => [
              PopupMenuItem(
                onTap: () => _editWall(context, ref, w),
                child: const Text('Edit wall'),
              ),
            ],
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No wall photos yet', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
