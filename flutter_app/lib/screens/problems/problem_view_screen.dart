import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../database/database.dart';
import '../../marks/mark_editor.dart';
import '../../marks/mark_layer.dart';
import '../../marks/opening_photo.dart';
import '../../providers/app_providers.dart';
import '../../share/share_problem.dart';
import '../../utils/share_file.dart';
import '../../utils/undo_snackbar.dart';
import '../../widgets/photo_strip.dart';
import '../photos/photos_screen.dart' show photoTitle;
import '../../widgets/wide.dart';
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
    final wall    = ref.watch(wallProvider(wallId));
    final problem = ref.watch(problemProvider(problemId));
    final marks   = ref.watch(problemMarksProvider(problemId));
    final p       = problem.value;
    final layout  = p == null ? null : ref.watch(layoutProvider(p.layoutId));
    final l       = layout?.value;
    final photos  = l == null ? null : ref.watch(photosProvider(l.id));

    if (wall.isLoading || problem.isLoading || marks.isLoading ||
        (layout?.isLoading ?? false) || (photos?.isLoading ?? false)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final w = wall.value;
    if (w == null || p == null || l == null || l.wallId != wallId) {
      return const NotFoundScreen();
    }
    return _ProblemView(
        wall: w, problem: p, marks: marks.value!, photos: photos!.value!,
        archived: l.endedOn != null);
  }
}

class _ProblemView extends ConsumerStatefulWidget {
  final Wall            wall;
  final Problem         problem;
  final List<Mark>      marks;
  final List<WallPhoto> photos;

  /// On an archived layout: view only, so the menu holds only Share.
  final bool            archived;

  const _ProblemView({
    required this.wall,
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
    final wallId = widget.wall.id;
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

  /// One JPEG per photo carrying this problem's marks, at the photo's own
  /// size with a caption bar, handed to the share sheet, a save dialog or
  /// downloads. Images only: nothing on the other side can import them.
  Future<void> _share() async {
    final p         = widget.problem;
    final db        = ref.read(dbProvider);
    final encode    = ref.read(shareEncoderProvider);
    final share     = ref.read(shareFilesProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    final photos    = photosToShare(widget.photos, widget.marks);
    final caption   = shareCaption(
        name: p.name, grade: p.grade, wall: widget.wall.name);
    final progress  = ValueNotifier('Preparing the images');
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BusyDialog(progress),
    );

    final files = <SharedFile>[];
    Object? failure;
    try {
      for (final (i, photo) in photos.indexed) {
        progress.value = photos.length == 1
            ? 'Preparing the image'
            : 'Preparing image ${i + 1} of ${photos.length}';
        final image = await renderShareImage(
          photo:   (await db.photoImage(photo.id))!.data,
          marks:   [for (final m in widget.marks) if (m.photoId == photo.id) m],
          caption: caption,
        );
        files.add((
          bytes: await encode(image),
          name:  shareImageName(
              p.name, photoTitle(photo, widget.photos.indexOf(photo)),
              several: photos.length > 1),
        ));
      }
    } catch (e) {
      failure = e;
    } finally {
      navigator.pop();
      progress.dispose();
    }
    if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text("Couldn't share: $failure")));
      return;
    }
    await share(files, 'image/jpeg');
  }

  @override
  Widget build(BuildContext context) {
    final p     = widget.problem;
    final ms    = widget.marks;
    // A picked photo deleted meanwhile falls back to the opening one.
    final photo = openingPhoto(widget.photos, ms, shown: _picked);
    final edit  = '/walls/${widget.wall.id}/problems/${p.id}/edit'
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
          // Share goes everywhere. A retired problem keeps its record as it
          // was (no Edit); an archived one is view only.
          PopupMenuButton<void>(
            tooltip: 'Problem menu',
            itemBuilder: (_) => [
              if (!widget.archived && p.retiredOn == null)
                PopupMenuItem(
                  onTap: () => context.go(edit),
                  child: const Text('Edit'),
                ),
              if (widget.marks.isNotEmpty)
                PopupMenuItem(
                  onTap: _share,
                  child: const Text('Share'),
                ),
              if (!widget.archived) ...[
                if (p.retiredOn == null)
                  PopupMenuItem(
                    onTap: _retire,
                    child: const Text('Retire'),
                  )
                else
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
            ],
          ),
        ],
      ),
      // A phone stacks photo, strip and description sheet; a wide window
      // puts the strip on the left and the details in a panel on the right.
      body: LayoutBuilder(builder: (context, c) {
        final wide      = isWide(c);
        final photoArea = photo == null
            ? const Center(child: Text('This layout has no photos'))
            : ZoomablePhoto(
                key:        ValueKey(photo.id),
                photo:      photo,
                controller: _views.putIfAbsent(photo.id, PhotoViewController.new),
                // No callbacks: it draws, and takes no taps or drags of its
                // own.
                overlay: MarkLayer(
                  photo: Size(photo.width.toDouble(), photo.height.toDouble()),
                  controller: _views[photo.id]!,
                  marks: [
                    for (final m in ms)
                      if (m.photoId == photo.id) EditMark.fromMark(m),
                  ],
                ),
              );
        final strip = photo == null
            ? const SizedBox.shrink()
            : PhotoStrip(
                photos:      widget.photos,
                currentId:   photo.id,
                marks:       [for (final m in ms) EditMark.fromMark(m)],
                dimUnmarked: true,
                onSelect:    (id) => setState(() => _picked = id),
                axis:        wide ? Axis.vertical : Axis.horizontal,
              );
        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  strip,
                  Expanded(child: photoArea),
                  _DetailsPanel(problem: p),
                ])
            : Column(children: [
                Expanded(child: photoArea),
                strip,
                if (p.description.isNotEmpty) _DescriptionSheet(problem: p),
              ]);
      }),
    );
  }
}

/// What a slow job is doing; it can't be dismissed, and closes itself.
class _BusyDialog extends StatelessWidget {
  final ValueListenable<String> step;
  const _BusyDialog(this.step);

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(children: [
            const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(width: 20),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: step,
                builder: (context, s, _) => Text(s),
              ),
            ),
          ]),
        ),
      );
}

/// A wide window's right-hand panel: the dates and the description, always
/// open, since the photo has room beside it. Name and grade stay in the app
/// bar, as on a phone.
class _DetailsPanel extends StatelessWidget {
  final Problem problem;
  const _DetailsPanel({required this.problem});

  static const width = 300.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p     = problem;
    return Material(
      key:   const ValueKey('details-panel'),
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        left: false,
        child: SizedBox(
          width: width,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Set ${p.setOn}', style: theme.textTheme.labelLarge),
              if (p.retiredOn != null)
                Text('Retired ${p.retiredOn}', style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              p.description.isEmpty
                  ? Text('No description',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant))
                  : Text(p.description),
            ],
          ),
        ),
      ),
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
