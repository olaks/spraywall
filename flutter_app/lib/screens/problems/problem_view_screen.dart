import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../database/database.dart';
import '../../marks/mark_editor.dart';
import '../../marks/mark_layer.dart';
import '../../marks/opening_photo.dart';
import '../../providers/app_providers.dart';
import '../../utils/undo_snackbar.dart';
import '../../widgets/photo_strip.dart';
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
    return _ProblemView(
        wallId: wallId, problem: p, marks: marks.value!, photos: photos!.value!,
        archived: l.endedOn != null);
  }
}

class _ProblemView extends ConsumerStatefulWidget {
  final String          wallId;
  final Problem         problem;
  final List<Mark>      marks;
  final List<WallPhoto> photos;

  /// On an archived layout: view only, no menu at all.
  final bool            archived;

  const _ProblemView({
    required this.wallId,
    required this.problem,
    required this.marks,
    required this.photos,
    required this.archived,
  });

  @override
  ConsumerState<_ProblemView> createState() => _ProblemViewState();
}

class _ProblemViewState extends ConsumerState<_ProblemView> {
  /// The photo picked on the strip; until then, the opening photo.
  String? _picked;
  final Map<String, PhotoViewController> _views = {};

  @override
  void dispose() {
    for (final v in _views.values) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _delete() async {
    final p      = widget.problem;
    final wallId = widget.wallId;
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

  Future<void> _retire() async {
    final p         = widget.problem;
    final db        = ref.read(dbProvider);
    final messenger = ScaffoldMessenger.of(context);
    await db.retireProblem(p.id);
    showUndoSnackBar(messenger,
        message: 'Retired "${p.name}"',
        onUndo:  () => db.unretireProblem(p.id));
  }

  @override
  Widget build(BuildContext context) {
    final p     = widget.problem;
    final ms    = widget.marks;
    // A picked photo deleted meanwhile falls back to the opening one.
    final photo = openingPhoto(widget.photos, ms, shown: _picked);
    final edit  = '/walls/${widget.wallId}/problems/${p.id}/edit'
        '${photo == null ? '' : '?photo=${photo.id}'}';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text([
              p.grade ?? 'Ungraded',
              if (p.retiredOn != null) 'Retired ${p.retiredOn}',
            ].join(' · '), style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [
          // A retired problem keeps its record as it was: no Edit.
          if (!widget.archived) PopupMenuButton<void>(
            tooltip: 'Problem menu',
            itemBuilder: (_) => [
              if (p.retiredOn == null) ...[
                PopupMenuItem(
                  onTap: () => context.go(edit),
                  child: const Text('Edit'),
                ),
                PopupMenuItem(
                  onTap: _retire,
                  child: const Text('Retire'),
                ),
              ] else
                PopupMenuItem(
                  onTap: () =>
                      ref.read(dbProvider).unretireProblem(p.id),
                  child: const Text('Un-retire'),
                ),
              PopupMenuItem(
                onTap: _delete,
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
              : ZoomablePhoto(
                  key:        ValueKey(photo.id),
                  photo:      photo,
                  controller: _views.putIfAbsent(photo.id, PhotoViewController.new),
                  // No callbacks: it draws, and takes no taps or drags of
                  // its own.
                  overlay: MarkLayer(
                    photo: Size(photo.width.toDouble(), photo.height.toDouble()),
                    controller: _views[photo.id]!,
                    marks: [
                      for (final m in ms)
                        if (m.photoId == photo.id) EditMark.fromMark(m),
                    ],
                  ),
                ),
        ),
        if (photo != null)
          PhotoStrip(
            photos:      widget.photos,
            currentId:   photo.id,
            marks:       [for (final m in ms) EditMark.fromMark(m)],
            dimUnmarked: true,
            onSelect:    (id) => setState(() => _picked = id),
          ),
        if (p.description.isNotEmpty) _DescriptionSheet(problem: p),
      ]),
    );
  }
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
