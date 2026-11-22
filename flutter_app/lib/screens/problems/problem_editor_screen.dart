import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../database/database.dart';
import '../../marks/mark_editor.dart';
import '../../marks/mark_geometry.dart';
import '../../marks/mark_layer.dart';
import '../../marks/opening_photo.dart';
import '../../providers/app_providers.dart';
import '../../utils/format_utils.dart';
import '../../utils/undo_snackbar.dart';
import '../../widgets/photo_strip.dart';
import '../../widgets/wide.dart';
import '../../widgets/zoomable_photo.dart';
import '../not_found_screen.dart';
import 'problem_details_sheet.dart';

/// Sets a new problem (no [problemId]) or edits one: marks first, details
/// in a sheet. Never adds photos; the wall screen does that.
class ProblemEditorScreen extends ConsumerWidget {
  final String  wallId;
  final String? problemId;

  /// The photo the problem view was showing, to open on.
  final String? photoId;

  const ProblemEditorScreen({
    super.key,
    required this.wallId,
    this.problemId,
    this.photoId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = problemId;
    final wall = ref.watch(wallProvider(wallId));
    final problem = id == null ? null : ref.watch(problemProvider(id));
    final marks   = id == null ? null : ref.watch(problemMarksProvider(id));
    // A new problem goes on the current layout; an existing one stays on its own.
    final layout = id == null
        ? ref.watch(currentLayoutProvider(wallId))
        : problem!.value == null
            ? null
            : ref.watch(layoutProvider(problem.value!.layoutId));
    final l      = layout?.value;
    final photos = l == null ? null : ref.watch(photosProvider(l.id));

    final loading = [wall, problem, marks, layout, photos]
        .any((v) => v != null && v.isLoading);
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final w = wall.value;
    // An archived layout's problems, and retired ones, are view-only.
    if (w == null || l == null || l.wallId != w.id || l.endedOn != null ||
        (id != null && problem?.value == null) ||
        problem?.value?.retiredOn != null) {
      return const NotFoundScreen();
    }
    if (photos!.value!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('New problem')),
        body: const Center(child: Text('Add a wall photo first')),
      );
    }
    final existing = marks?.value ?? const <Mark>[];
    return _Editor(
      wall:    w,
      layout:  l,
      photos:  photos.value!,
      opening: openingPhoto(photos.value!, existing, shown: photoId)!.id,
      problem: problem?.value,
      marks:   existing,
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  final Wall            wall;
  final Layout          layout;
  final List<WallPhoto> photos;
  final String          opening;
  final Problem?        problem;
  final List<Mark>      marks;
  const _Editor({
    required this.wall,
    required this.layout,
    required this.photos,
    required this.opening,
    required this.problem,
    required this.marks,
  });

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late final _marks = MarkEditorController(
      [for (final m in widget.marks) EditMark.fromMark(m)]);

  /// An existing problem's details, as edited so far.
  late ProblemDetails? _details = switch (widget.problem) {
    null      => null,
    final p   => (name: p.name, grade: p.grade, description: p.description,
                  setOn: dateFromStr(p.setOn)),
  };
  bool _detailsChanged = false;
  bool _holding = false;

  /// The photo on screen, and each photo's pan and zoom while the editor is
  /// open.
  late String _photoId = widget.opening;
  final Map<String, PhotoViewController> _views = {};

  WallPhoto get _photo =>
      widget.photos.where((p) => p.id == _photoId).firstOrNull ??
      widget.photos.first;

  PhotoViewController _view(String photoId) =>
      _views.putIfAbsent(photoId, PhotoViewController.new);

  /// Never leaves a mark selected that is off screen.
  void _show(String photoId) {
    if (photoId == _photoId) return;
    _marks.select(null);
    setState(() {
      _photoId = photoId;
      _holding = false;
    });
  }

  /// Set once saved: a trash undone after the editor has closed goes into
  /// this problem, through the database captured with it.
  String? _savedId;

  bool get _isNew  => widget.problem == null;
  bool get _unsaved => (_marks.dirty || _detailsChanged) && _savedId == null;

  Size get _photoSize =>
      Size(_photo.width.toDouble(), _photo.height.toDouble());

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
    for (final v in _views.values) {
      v.dispose();
    }
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
          db.addMark(id, trashed.mark.input);
        }
        // Discarded: there is nothing left to put it back into.
      },
    );
  }

  List<MarkInput> get _inputs => [for (final m in _marks.marks) m.input];

  Future<ProblemDetails?> _detailsSheet({
    required String                            actionLabel,
    required Future<void> Function(ProblemDetails) submit,
  }) =>
      showModalBottomSheet<ProblemDetails>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => ProblemDetailsSheet(
          gradeScale:  widget.wall.gradeScale,
          initial:     _details,
          actionLabel: actionLabel,
          submit:      submit,
        ),
      );

  /// A new problem: the details sheet, which creates it with the marks.
  /// An existing one: details and marks written together.
  Future<void> _save() async {
    final db = ref.read(dbProvider);
    if (_isNew) {
      String? created;
      await _detailsSheet(
        actionLabel: 'Save problem',
        submit: (d) async => created = await db.createProblem(
          layoutId: widget.layout.id, name: d.name, grade: d.grade,
          description: d.description, setOn: d.setOn, marks: _inputs,
        ),
      );
      if (created == null) return;
      _savedId = created;
    } else {
      await db.updateProblem(widget.problem!.id,
          details: _details!, marks: _inputs);
      _savedId = widget.problem!.id;
    }
    if (!mounted) return;
    setState(() {});
    context.go('/walls/${widget.wall.id}/problems/$_savedId');
  }

  /// An existing problem's details, checked but kept until Save.
  Future<void> _editDetails() async {
    final db = ref.read(dbProvider);
    final id = widget.problem!.id;
    final d = await _detailsSheet(
      actionLabel: 'Done',
      submit: (d) async {
        if (await db.problemNameTaken(widget.layout.id, d.name, exceptId: id)) {
          throw ProblemNameTaken(d.name);
        }
      },
    );
    if (d == null || !mounted) return;
    setState(() {
      _details        = d;
      _detailsChanged = true;
    });
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
    if (discard != true || !mounted) return;
    context.go(_isNew
        ? '/walls/${widget.wall.id}'
        : '/walls/${widget.wall.id}/problems/${widget.problem!.id}');
  }

  @override
  Widget build(BuildContext context) {
    final photo    = _photo;
    final view     = _view(photo.id);
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
      canPop: !_unsaved,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isNew ? 'New problem' : _details!.name),
          actions: [
            if (!_isNew)
              TextButton(
                onPressed: _editDetails,
                child: const Text('Edit details'),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _marks.marks.isEmpty ? null : _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
        // A phone stacks photo, strip and palette; a wide window puts the
        // strip on the left and the palette on the right. Each photo's zoom
        // lives in its controller, so it survives the switch.
        body: LayoutBuilder(builder: (context, c) {
          final wide      = isWide(c);
          final photoArea = Stack(children: [
            ZoomablePhoto(
              // A fresh viewer per photo, on that photo's own controller.
              key:        ValueKey(photo.id),
              photo:      photo,
              controller: view,
              panEnabled: !_holding,
              overlay: MarkLayer(
                photo:      _photoSize,
                controller: view,
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
          ]);
          final strip = PhotoStrip(
            photos:    widget.photos,
            currentId: photo.id,
            marks:     _marks.marks,
            onSelect:  _show,
            axis:      wide ? Axis.vertical : Axis.horizontal,
          );
          final palette = _Palette(
            role:     selected?.role ?? _marks.brush,
            onRole:   _marks.chooseRole,
            onTrash:  selected == null ? null : _trash,
            onDone:   selected == null ? null : () => _marks.select(null),
            sideBar:  wide,
          );
          return wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [strip, Expanded(child: photoArea), palette])
              : Column(children: [Expanded(child: photoArea), strip, palette]);
        }),
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
/// done: a bar under the photo, or a side bar on its right.
class _Palette extends StatelessWidget {
  final Role               role;
  final ValueChanged<Role> onRole;
  final VoidCallback?      onTrash;
  final VoidCallback?      onDone;
  final bool               sideBar;

  const _Palette({
    required this.role,
    required this.onRole,
    required this.onTrash,
    required this.onDone,
    required this.sideBar,
  });

  /// The side bar's width: room for the widest chip, "Finish".
  static const width = 160.0;

  static String _label(Role r) => switch (r) {
        Role.start  => 'Start',
        Role.hand   => 'Hand',
        Role.foot   => 'Foot',
        Role.finish => 'Finish',
      };

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final r in Role.values)
        ChoiceChip(
          key: ValueKey('role-${r.name}'),
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
    ];
    final actions = [
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
    ];

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: sideBar
          // A landscape phone is short: the side bar scrolls if it must.
          ? SafeArea(
              left: false,
              child: SizedBox(
                width: width,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final c in chips)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: c,
                        ),
                      Row(children: actions),
                    ],
                  ),
                ),
              ),
            )
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [...chips, ...actions],
                ),
              ),
            ),
    );
  }
}
