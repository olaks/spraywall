import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../database/database.dart';
import '../../marks/mark_editor.dart';
import '../../marks/mark_geometry.dart';
import '../../marks/mark_layer.dart';
import '../../providers/app_providers.dart';
import '../../utils/undo_snackbar.dart';
import '../../widgets/zoomable_photo.dart';
import '../not_found_screen.dart';
import 'problem_details_sheet.dart';

/// Sets a new problem: marks first, on the layout's first photo, then the
/// details on Save. Never adds photos; the wall screen does that.
class ProblemEditorScreen extends ConsumerWidget {
  final String wallId;
  const ProblemEditorScreen({super.key, required this.wallId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wall   = ref.watch(wallProvider(wallId));
    final layout = ref.watch(currentLayoutProvider(wallId));
    final w = wall.value;
    final l = layout.value;
    final photos = l == null ? null : ref.watch(photosProvider(l.id)).value;
    if (wall.isLoading || layout.isLoading || (l != null && photos == null)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (w == null || l == null) return const NotFoundScreen();
    if (photos!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('New problem')),
        body: const Center(child: Text('Add a wall photo first')),
      );
    }
    return _Editor(wall: w, layout: l, photo: photos.first);
  }
}

class _Editor extends ConsumerStatefulWidget {
  final Wall      wall;
  final Layout    layout;
  final WallPhoto photo;
  const _Editor({required this.wall, required this.layout, required this.photo});

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  final _marks = MarkEditorController();
  final _tc    = TransformationController();
  bool _holding = false;

  /// Set once saved: a trash undone after the editor has closed goes into
  /// this problem, through the database captured with it.
  String? _savedId;

  Size get _photoSize =>
      Size(widget.photo.width.toDouble(), widget.photo.height.toDouble());

  @override
  void initState() {
    super.initState();
    _marks.addListener(_rebuild);
  }

  @override
  void dispose() {
    _marks
      ..removeListener(_rebuild)
      ..dispose();
    _tc.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _trash() {
    final sel = _marks.selected;
    if (sel == null) return;
    final db      = ref.read(dbProvider);
    final trashed = _marks.trash(sel.id);
    showUndoSnackBar(
      ScaffoldMessenger.of(context),
      message: 'Deleted ${sel.role.name} mark',
      onUndo: () {
        if (mounted) {
          _marks.untrash(trashed);
        } else if (_savedId case final id?) {
          db.addMark(id, _input(trashed.mark));
        }
        // Discarded: there is nothing left to put it back into.
      },
    );
  }

  Future<void> _save() async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ProblemDetailsSheet(
        db:         ref.read(dbProvider),
        layoutId:   widget.layout.id,
        gradeScale: widget.wall.gradeScale,
        marks:      [for (final m in _marks.marks) _input(m)],
      ),
    );
    if (id == null || !mounted) return;
    setState(() => _savedId = id);
    context.go('/walls/${widget.wall.id}');
  }

  Future<void> _confirmLeave() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('The marks on this problem will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) context.go('/walls/${widget.wall.id}');
  }

  static MarkInput _input(EditMark m) => (
        id: m.id, photoId: m.photoId, role: m.role,
        cx: m.cx, cy: m.cy, r: m.r,
      );

  @override
  Widget build(BuildContext context) {
    final photo    = widget.photo;
    final selected = _marks.selected;
    final hint     = _marks.marks.isEmpty
        ? null
        : switch ((_marks.hasStart, _marks.hasFinish)) {
            (false, false) => 'No start or finish mark yet',
            (false, true)  => 'No start mark yet',
            (true,  false) => 'No finish mark yet',
            (true,  true)  => null,
          };

    return PopScope(
      canPop: !_marks.dirty || _savedId != null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('New problem'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _marks.marks.isEmpty ? null : _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: Stack(children: [
              ZoomablePhoto(
                photo:      photo,
                controller: _tc,
                panEnabled: !_holding,
                overlay: MarkLayer(
                  photo:      _photoSize,
                  controller: _tc,
                  marks:      _marks.marksOn(photo.id),
                  selectedId: selected?.id,
                  onTapEmpty: (p) {
                    final (cx, cy) = normalise(p, _photoSize);
                    _marks.place(photo.id, cx, cy);
                  },
                  onTapMark: _marks.select,
                  onMove: (id, d) => _marks.move(
                      id, d.dx / _photoSize.width, d.dy / _photoSize.height),
                  // r is a fraction of width, like the handle's drag.
                  onResize: (id, dx) => _marks.resize(id, dx / _photoSize.width),
                  onHold: (h) => setState(() => _holding = h),
                ),
              ),
              if (hint != null)
                Positioned(
                  top: 8, left: 0, right: 0,
                  child: Center(child: _Hint(hint)),
                ),
            ]),
          ),
          _Palette(
            role:     selected?.role ?? _marks.brush,
            onRole:   _marks.chooseRole,
            onTrash:  selected == null ? null : _trash,
            onDone:   selected == null ? null : () => _marks.select(null),
          ),
        ]),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      );
}

/// The four role chips (the brush, or the selected mark's role), trash and
/// done.
class _Palette extends StatelessWidget {
  final Role               role;
  final ValueChanged<Role> onRole;
  final VoidCallback?      onTrash;
  final VoidCallback?      onDone;

  const _Palette({
    required this.role,
    required this.onRole,
    required this.onTrash,
    required this.onDone,
  });

  static String _label(Role r) => switch (r) {
        Role.start  => 'Start',
        Role.hand   => 'Hand',
        Role.foot   => 'Foot',
        Role.finish => 'Finish',
      };

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final r in Role.values)
                  ChoiceChip(
                    avatar: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        shape:  BoxShape.circle,
                        border: Border.all(color: roleColors[r]!, width: 3),
                      ),
                    ),
                    label:      Text(_label(r)),
                    selected:   role == r,
                    onSelected: (_) => onRole(r),
                  ),
                IconButton(
                  tooltip:   'Delete mark',
                  icon:      const Icon(Icons.delete_outline),
                  onPressed: onTrash,
                ),
                IconButton(
                  tooltip:   'Done',
                  icon:      const Icon(Icons.check),
                  onPressed: onDone,
                ),
              ],
            ),
          ),
        ),
      );
}
