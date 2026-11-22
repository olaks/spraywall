import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../database/database.dart';
import '../../marks/mark_editor.dart';
import '../../photos/add_photo.dart';
import '../../problems/browse.dart';
import '../../providers/app_providers.dart';
import '../../utils/grades.dart';
import '../../utils/undo_snackbar.dart';
import '../../widgets/marked_thumb.dart';
import '../not_found_screen.dart';
import 'edit_wall_dialog.dart';

/// A wall's current layout: its problems, filtered and sorted, each row with
/// its grade, set date and the first photo it is marked on.
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
    final photos    = ref.watch(photosProvider(l.id)).value;
    final hasPhotos = photos?.isNotEmpty ?? false;
    final problems  = ref.watch(problemsProvider(l.id)).value;
    final marks     = ref.watch(layoutMarksProvider(l.id)).value ?? const [];
    final query     = ref.watch(problemQueryProvider(w.id));
    void setQuery(ProblemQuery q) =>
        ref.read(problemQueryProvider(w.id).notifier).set(q);

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
                onTap: () => context.go('/walls/${w.id}/photos'),
                child: const Text('Photos'),
              ),
              PopupMenuItem(
                onTap: () => _editWall(context, ref, w),
                child: const Text('Edit wall'),
              ),
            ],
          ),
        ],
      ),
      // Problems are set on photos, so the first thing a layout needs is one.
      floatingActionButton: photos == null ? null : hasPhotos
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/walls/${w.id}/problems/new'),
              icon:      const Icon(Icons.add),
              label:     const Text('New problem'),
            )
          : FloatingActionButton.extended(
              onPressed: () => addWallPhoto(context, ref, l.id),
              icon:      const Icon(Icons.add_a_photo_outlined),
              label:     const Text('Add a wall photo'),
            ),
      body: switch ((photos, problems)) {
        (null, _) || (_, null) => const SizedBox.shrink(),
        (final ps?, final list?) when ps.isEmpty || list.isEmpty => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                ps.isEmpty ? 'No wall photos yet' : 'No problems yet',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        (final ps?, final list?) => _ProblemList(
            wall:     w,
            photos:   ps,
            problems: list,
            marks:    marks,
            query:    query,
            onQuery:  setQuery,
          ),
      },
    );
  }
}

class _ProblemList extends StatelessWidget {
  final Wall               wall;
  final List<WallPhoto>    photos;
  final List<Problem>      problems;
  final List<Mark>         marks;
  final ProblemQuery       query;
  final ValueChanged<ProblemQuery> onQuery;

  const _ProblemList({
    required this.wall,
    required this.photos,
    required this.problems,
    required this.marks,
    required this.query,
    required this.onQuery,
  });

  @override
  Widget build(BuildContext context) {
    final shown   = browse(problems, gradesFor(wall.gradeScale), query);
    final byProblem = <String, List<Mark>>{};
    for (final m in marks) {
      (byProblem[m.problemId] ??= []).add(m);
    }

    return Column(children: [
      _FilterBar(
        scale:   gradesFor(wall.gradeScale),
        query:   query,
        onQuery: onQuery,
      ),
      Expanded(
        child: shown.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('No problems match'),
                  TextButton(
                    onPressed: () => onQuery(query.cleared()),
                    child: const Text('Clear filters'),
                  ),
                ]),
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [
                  for (final p in shown)
                    _ProblemRow(
                      wallId:  wall.id,
                      problem: p,
                      photos:  photos,
                      marks:   byProblem[p.id] ?? const [],
                    ),
                ],
              ),
      ),
    ]);
  }
}

class _ProblemRow extends StatelessWidget {
  final String          wallId;
  final Problem         problem;
  final List<WallPhoto> photos;
  final List<Mark>      marks;

  const _ProblemRow({
    required this.wallId,
    required this.problem,
    required this.photos,
    required this.marks,
  });

  @override
  Widget build(BuildContext context) {
    final photo = firstMarkedPhoto(photos, marks);
    return ListTile(
      key:      ValueKey('problem-${problem.id}'),
      onTap:    () => context.go('/walls/$wallId/problems/${problem.id}'),
      leading:  SizedBox(
        width: 64, height: 48,
        child: photo == null
            ? null
            : MarkedThumb(photo: photo, marks: [
                for (final m in marks)
                  if (m.photoId == photo.id) EditMark.fromMark(m),
              ]),
      ),
      title:    Text(problem.name),
      subtitle: Text('Set ${problem.setOn}'),
      trailing: Text(problem.grade ?? '–',
          semanticsLabel: problem.grade ?? 'Ungraded',
          style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

/// Name search, the grade range and the sort, above the list.
class _FilterBar extends StatefulWidget {
  final List<String>               scale;
  final ProblemQuery               query;
  final ValueChanged<ProblemQuery> onQuery;

  const _FilterBar({
    required this.scale,
    required this.query,
    required this.onQuery,
  });

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  // Starts from the kept query, so coming back to the wall shows the search.
  late final _name = TextEditingController(text: widget.query.name);

  @override
  void didUpdateWidget(_FilterBar old) {
    super.didUpdateWidget(old);
    // "Clear filters" empties the field too.
    if (widget.query.name != _name.text) _name.text = widget.query.name;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _gradeLabel => switch ((widget.query.minGrade, widget.query.maxGrade)) {
        (null, null)                     => 'Any grade',
        (final lo?, final hi?) when lo == hi => lo,
        (final lo?, final hi?)           => '$lo – $hi',
        (final lo?, null)                => '$lo and up',
        (null, final hi?)                => 'Up to $hi',
      };

  Future<void> _pickGrades() async {
    final range = await showDialog<_Range>(
      context: context,
      builder: (_) => _GradeRangeDialog(
          scale: widget.scale,
          min:   widget.query.minGrade,
          max:   widget.query.maxGrade),
    );
    if (range == null) return;
    widget.onQuery(widget.query.withGrades(range.min, range.max));
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.query;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(children: [
        TextField(
          key:        const ValueKey('problem-search'),
          controller: _name,
          decoration: InputDecoration(
            isDense:    true,
            hintText:   'Search by name',
            prefixIcon: const Icon(Icons.search),
            border:     const OutlineInputBorder(),
            suffixIcon: q.name.isEmpty
                ? null
                : IconButton(
                    tooltip:   'Clear search',
                    icon:      const Icon(Icons.clear),
                    onPressed: () => widget.onQuery(q.withName('')),
                  ),
          ),
          onChanged: (v) => widget.onQuery(q.withName(v)),
        ),
        const SizedBox(height: 8),
        Row(children: [
          FilterChip(
            avatar:     const Icon(Icons.tune, size: 18),
            label:      Text(_gradeLabel),
            selected:   q.hasGradeRange,
            showCheckmark: false,
            onSelected: (_) => _pickGrades(),
          ),
          const Spacer(),
          SegmentedButton<ProblemSort>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ProblemSort.grade,  label: Text('Grade')),
              ButtonSegment(value: ProblemSort.newest, label: Text('Newest')),
            ],
            selected: {q.sort},
            onSelectionChanged: (s) => widget.onQuery(q.withSort(s.single)),
          ),
        ]),
      ]),
    );
  }
}

typedef _Range = ({String? min, String? max});

/// The easiest and hardest grade to show; the whole scale means any grade,
/// ungraded problems included.
class _GradeRangeDialog extends StatefulWidget {
  final List<String> scale;
  final String?      min;
  final String?      max;
  const _GradeRangeDialog({required this.scale, this.min, this.max});

  @override
  State<_GradeRangeDialog> createState() => _GradeRangeDialogState();
}

class _GradeRangeDialogState extends State<_GradeRangeDialog> {
  late final _top = (widget.scale.length - 1).toDouble();
  late var _values = RangeValues(
    widget.min == null ? 0    : widget.scale.indexOf(widget.min!).toDouble(),
    widget.max == null ? _top : widget.scale.indexOf(widget.max!).toDouble(),
  );

  String _at(double v) => widget.scale[v.round()];

  @override
  Widget build(BuildContext context) {
    final any = _values.start == 0 && _values.end == _top;
    return AlertDialog(
      title: const Text('Grades'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(any
            ? 'Any grade'
            : '${_at(_values.start)} – ${_at(_values.end)}',
            style: Theme.of(context).textTheme.titleMedium),
        RangeSlider(
          key:       const ValueKey('grade-range'),
          values:    _values,
          min:       0,
          max:       _top,
          divisions: widget.scale.length - 1,
          labels:    RangeLabels(_at(_values.start), _at(_values.end)),
          onChanged: (v) => setState(() => _values = v),
        ),
        if (!any)
          Text('Ungraded problems are hidden',
              style: Theme.of(context).textTheme.bodySmall),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop<_Range>(context, (min: null, max: null)),
          child: const Text('Any grade'),
        ),
        FilledButton(
          // The whole scale is no filter, so ungraded problems stay.
          onPressed: () => Navigator.pop<_Range>(context, any
              ? (min: null, max: null)
              : (min: _values.start == 0    ? null : _at(_values.start),
                 max: _values.end   == _top ? null : _at(_values.end))),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
