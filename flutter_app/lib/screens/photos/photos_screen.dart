import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../database/database.dart';
import '../../photos/add_photo.dart';
import '../../providers/app_providers.dart';
import '../../utils/undo_snackbar.dart';
import '../not_found_screen.dart';

/// The current layout's wall photos: add, label, reorder, delete, and open
/// one full-screen. A list rather than a grid: Flutter has no reorderable
/// grid, and a layout holds a handful of photos.
class PhotosScreen extends ConsumerWidget {
  final String wallId;
  const PhotosScreen({super.key, required this.wallId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = ref.watch(currentLayoutProvider(wallId));
    if (layout.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final l = layout.value;
    if (l == null) return const NotFoundScreen();

    final photos = ref.watch(photosProvider(l.id));
    final usage  = ref.watch(photoUsageProvider(l.id)).value ?? const {};

    return Scaffold(
      appBar: AppBar(title: const Text('Wall photos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => addWallPhoto(context, ref, l.id),
        icon:      const Icon(Icons.add_a_photo_outlined),
        label:     const Text('Add a wall photo'),
      ),
      body: photos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('$e')),
        data:    (list) => list.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Photograph the whole wall, then close-ups of anything '
                    'too small to tap: the kicker, a corner.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ReorderableListView(
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.only(bottom: 88),
                onReorder: (from, to) {
                  final ids = [for (final p in list) p.id];
                  final id  = ids.removeAt(from);
                  ids.insert(to > from ? to - 1 : to, id);
                  ref.read(dbProvider).reorderPhotos(ids);
                },
                children: [
                  for (final (i, p) in list.indexed)
                    _PhotoRow(
                      key:    ValueKey(p.id),
                      wallId: wallId,
                      photo:  p,
                      index:  i,
                      users:  usage[p.id] ?? 0,
                    ),
                ],
              ),
      ),
    );
  }
}

/// The name a photo goes by: its label, or its place in the list.
String photoTitle(WallPhoto p, int index) => p.label ?? 'Photo ${index + 1}';

class _PhotoRow extends ConsumerWidget {
  final String    wallId;
  final WallPhoto photo;
  final int       index;
  final int       users;

  const _PhotoRow({
    super.key,
    required this.wallId,
    required this.photo,
    required this.index,
    required this.users,
  });

  Future<void> _editLabel(BuildContext context, WidgetRef ref) async {
    final label = await showDialog<String>(
      context: context,
      builder: (_) => _LabelDialog(initial: photo.label ?? ''),
    );
    if (label != null) await ref.read(dbProvider).setPhotoLabel(photo.id, label);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    // Captured up front: the undo can be tapped after this screen is gone.
    final db        = ref.read(dbProvider);
    final messenger = ScaffoldMessenger.of(context);
    final title     = photoTitle(photo, index);
    try {
      final deleted = await db.deletePhoto(photo.id);
      showUndoSnackBar(messenger,
          message: 'Deleted "$title"',
          onUndo:  () => db.restorePhoto(deleted));
    } on PhotoInUse catch (e) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title:   Text("Can't delete \"$title\""),
          content: Text('${e.problems.length == 1 ? 'This problem has' : 'These problems have'} '
              'marks on it:\n\n${e.problems.join('\n')}\n\n'
              'Move or remove those marks first.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumb = ref.watch(photoImageProvider(photo.id)).value?.thumb;
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 96, height: 72,
          child: thumb == null
              ? const ColoredBox(color: Colors.black26)
              : Image.memory(thumb, fit: BoxFit.cover, gaplessPlayback: true),
        ),
      ),
      title:    Text(photoTitle(photo, index)),
      subtitle: Text(switch (users) {
        0 => 'No problems use this photo',
        1 => '1 problem uses this photo',
        _ => '$users problems use this photo',
      }),
      onTap: () => context.go('/walls/$wallId/photos/${photo.id}'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        PopupMenuButton<void>(
          tooltip: 'Photo menu',
          itemBuilder: (_) => [
            PopupMenuItem(
              onTap: () => _editLabel(context, ref),
              child: const Text('Edit label'),
            ),
            PopupMenuItem(
              onTap: () => _delete(context, ref),
              child: const Text('Delete'),
            ),
          ],
        ),
        ReorderableDragStartListener(
          index: index,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.drag_handle),
          ),
        ),
      ]),
    );
  }
}

class _LabelDialog extends StatefulWidget {
  final String initial;
  const _LabelDialog({required this.initial});

  @override
  State<_LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends State<_LabelDialog> {
  late final _label = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Photo label'),
        content: TextField(
          controller: _label,
          autofocus:  true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
              hintText: 'Whole wall, Left half, Kicker…'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _label.text),
            child: const Text('Save'),
          ),
        ],
      );
}
