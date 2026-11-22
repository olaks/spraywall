import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../database/database.dart';
import '../../marks/mark_editor.dart';
import '../../marks/mark_layer.dart';
import '../../marks/opening_photo.dart';
import '../../providers/app_providers.dart';
import '../../utils/undo_snackbar.dart';
import '../../widgets/zoomable_photo.dart';
import '../not_found_screen.dart';

/// A problem to read and climb: the photo with its marks, to pan and zoom
/// but not to edit, the name and grade in the app bar, and the description
/// in a sheet that folds away.
class ProblemViewScreen extends ConsumerWidget {
  final String wallId;
  final String problemId;
  const ProblemViewScreen({
    super.key,
    required this.wallId,
    required this.problemId,
  });

  Future<void> _delete(BuildContext context, WidgetRef ref, Problem p) async {
    // Captured up front: the undo is tapped on the list, after this screen
    // has gone.
    final db        = ref.read(dbProvider);
    final messenger = ScaffoldMessenger.of(context);
    // Leave first, so this screen never shows the problem as missing.
    context.go('/walls/$wallId');
    final deleted = await db.deleteProblem(p.id);
    showUndoSnackBar(messenger,
        message: 'Deleted "${p.name}"',
        onUndo:  () => db.restoreProblem(deleted));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problem = ref.watch(problemProvider(problemId));
    final marks   = ref.watch(problemMarksProvider(problemId));
    final p       = problem.value;
    final layout  = p == null ? null : ref.watch(layoutProvider(p.layoutId));
    final l       = layout?.value;
    final photos  = l == null ? null : ref.watch(photosProvider(l.id));

    if (problem.isLoading || marks.isLoading ||
        (layout?.isLoading ?? false) || (photos?.isLoading ?? false)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (p == null || l == null || l.wallId != wallId) {
      return const NotFoundScreen();
    }
    final ms    = marks.value!;
    final photo = openingPhoto(photos!.value!, ms);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(p.grade ?? 'Ungraded',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          PopupMenuButton<void>(
            tooltip: 'Problem menu',
            itemBuilder: (_) => [
              PopupMenuItem(
                onTap: () => context.go('/walls/$wallId/problems/${p.id}/edit'),
                child: const Text('Edit'),
              ),
              PopupMenuItem(
                onTap: () => _delete(context, ref, p),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: photo == null
              ? const Center(child: Text('This layout has no photos'))
              : _ReadOnlyPhoto(photo: photo, marks: ms),
        ),
        if (p.description.isNotEmpty) _DescriptionSheet(problem: p),
      ]),
    );
  }
}

class _ReadOnlyPhoto extends StatefulWidget {
  final WallPhoto  photo;
  final List<Mark> marks;
  const _ReadOnlyPhoto({required this.photo, required this.marks});

  @override
  State<_ReadOnlyPhoto> createState() => _ReadOnlyPhotoState();
}

class _ReadOnlyPhotoState extends State<_ReadOnlyPhoto> {
  final _tc = TransformationController();

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ZoomablePhoto(
        photo:      widget.photo,
        controller: _tc,
        // No callbacks: it draws, and takes no taps or drags of its own.
        overlay: MarkLayer(
          photo: Size(widget.photo.width.toDouble(),
                      widget.photo.height.toDouble()),
          controller: _tc,
          marks: [
            for (final m in widget.marks)
              if (m.photoId == widget.photo.id) EditMark.fromMark(m),
          ],
        ),
      );
}

/// The description and set date, folded away with a tap so the photo gets
/// the room.
class _DescriptionSheet extends StatefulWidget {
  final Problem problem;
  const _DescriptionSheet({required this.problem});

  @override
  State<_DescriptionSheet> createState() => _DescriptionSheetState();
}

class _DescriptionSheetState extends State<_DescriptionSheet> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(children: [
                  Expanded(
                    child: Text('Set ${widget.problem.setOn}',
                        style: theme.textTheme.labelLarge),
                  ),
                  Icon(_open ? Icons.expand_more : Icons.expand_less,
                      semanticLabel: _open ? 'Hide description' : 'Show description'),
                ]),
              ),
            ),
            if (_open)
              ConstrainedBox(
                // A long description scrolls rather than covering the photo.
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.3),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(widget.problem.description),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
