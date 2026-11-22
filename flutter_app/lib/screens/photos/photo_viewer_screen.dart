import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../database/database.dart';
import '../../marks/mark_editor.dart';
import '../../marks/mark_layer.dart';
import '../../marks/overlap.dart';
import '../../providers/app_providers.dart';
import '../../widgets/zoomable_photo.dart';
import '../not_found_screen.dart';

/// One wall photo, full-screen, to pan and zoom around. "Show problems"
/// draws the marks of every problem in use on it, faintly; tapping one lists
/// the problems whose marks overlap it, to see what else uses a hold before
/// moving it.
class PhotoViewerScreen extends ConsumerStatefulWidget {
  final String wallId;
  final String photoId;
  const PhotoViewerScreen({
    super.key,
    required this.wallId,
    required this.photoId,
  });

  @override
  ConsumerState<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends ConsumerState<PhotoViewerScreen> {
  final _view = PhotoViewController();
  bool _showProblems = false;

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  void _openSheet(Mark tapped, List<Mark> marks, Map<String, Problem> byId,
      Size photo) {
    final others = [
      for (final id in overlappingProblems(tapped, marks, photo)) byId[id]!,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) {
        Widget row(Problem p) => ListTile(
              key:      ValueKey('overlap-${p.id}'),
              title:    Text(p.name),
              trailing: Text(p.grade ?? '–',
                  semanticsLabel: p.grade ?? 'Ungraded',
                  style: Theme.of(sheet).textTheme.titleMedium),
              onTap: () {
                Navigator.pop(sheet);
                context.go('/walls/${widget.wallId}/problems/${p.id}');
              },
            );
        final label = Theme.of(sheet).textTheme.labelLarge;
        return SafeArea(
          child: ListView(shrinkWrap: true, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text('This mark', style: label),
            ),
            row(byId[tapped.problemId]!),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(others.isEmpty
                  ? 'No other problem has a mark here'
                  : 'Overlapping marks', style: label),
            ),
            for (final p in others) row(p),
            const SizedBox(height: 8),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = ref.watch(photoProvider(widget.photoId));
    if (photo.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final p = photo.value;
    if (p == null) return const NotFoundScreen();
    final size = Size(p.width.toDouble(), p.height.toDouble());

    // Problems in use: the layout's, retired ones left out.
    final inUse = _showProblems
        ? {
            for (final pr in ref.watch(problemsProvider(p.layoutId)).value ??
                const <Problem>[])
              if (pr.retiredOn == null) pr.id: pr,
          }
        : const <String, Problem>{};
    final marks = [
      if (_showProblems)
        for (final m in ref.watch(layoutMarksProvider(p.layoutId)).value ??
            const <Mark>[])
          if (m.photoId == p.id && inUse.containsKey(m.problemId)) m,
    ];
    final byId = {for (final m in marks) m.id: m};

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(p.label ?? 'Wall photo'),
        actions: [
          IconButton(
            tooltip:    _showProblems ? 'Hide problems' : 'Show problems',
            isSelected: _showProblems,
            icon:         const Icon(Icons.layers_outlined),
            selectedIcon: const Icon(Icons.layers),
            onPressed:  () => setState(() => _showProblems = !_showProblems),
          ),
        ],
      ),
      body: ZoomablePhoto(
        photo:      p,
        controller: _view,
        overlay: _showProblems
            // Faint: many problems share a photo, and the holds should
            // still show through.
            ? Opacity(
                opacity: 0.6,
                child: MarkLayer(
                  photo:      size,
                  controller: _view,
                  marks:      [for (final m in marks) EditMark.fromMark(m)],
                  onTapMark:  (id) =>
                      _openSheet(byId[id]!, marks, inUse, size),
                ),
              )
            : null,
      ),
    );
  }
}
