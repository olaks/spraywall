import 'package:flutter/material.dart';
import '../../database/database.dart';
import '../../utils/format_utils.dart';
import '../../utils/grades.dart';

/// The details asked for after the marks: name (required, unique in the
/// layout), grade, description and set date. Saving writes the problem and
/// [marks] together and pops with the new problem's id.
class ProblemDetailsSheet extends StatefulWidget {
  final AppDatabase     db;
  final String          layoutId;
  final GradeScale      gradeScale;
  final List<MarkInput> marks;

  /// Today, for the set date's default. Injected by tests.
  final DateTime? today;

  const ProblemDetailsSheet({
    super.key,
    required this.db,
    required this.layoutId,
    required this.gradeScale,
    required this.marks,
    this.today,
  });

  @override
  State<ProblemDetailsSheet> createState() => _ProblemDetailsSheetState();
}

class _ProblemDetailsSheetState extends State<ProblemDetailsSheet> {
  final _name        = TextEditingController();
  final _description = TextEditingController();
  late  DateTime _setOn = widget.today ?? DateTime.now();
  String? _grade;
  String? _error;
  bool    _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: _setOn,
      firstDate:   DateTime(2000),
      lastDate:    DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _setOn = picked);
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final id = await widget.db.createProblem(
        layoutId:    widget.layoutId,
        name:        _name.text,
        grade:       _grade,
        description: _description.text,
        setOn:       _setOn,
        marks:       widget.marks,
      );
      if (mounted) Navigator.of(context).pop(id);
    } on ProblemNameTaken catch (e) {
      setState(() {
        _busy  = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _name.text.trim().isNotEmpty && !_busy;
    return Padding(
      // Clear of the keyboard.
      padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Problem details',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              key:        const ValueKey('problem-name'),
              controller: _name,
              autofocus:  true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: 'Name', errorText: _error),
              onChanged:  (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              key:          const ValueKey('problem-grade'),
              initialValue: _grade,
              decoration:   const InputDecoration(labelText: 'Grade'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Ungraded')),
                for (final g in gradesFor(widget.gradeScale))
                  DropdownMenuItem(value: g, child: Text(g)),
              ],
              onChanged: (g) => setState(() => _grade = g),
            ),
            const SizedBox(height: 16),
            TextField(
              key:        const ValueKey('problem-description'),
              controller: _description,
              minLines:   2,
              maxLines:   5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText:  'Sit start, no arête, …'),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:  const Icon(Icons.event_outlined),
              title:    const Text('Set on'),
              subtitle: Text(dateStrFrom(_setOn)),
              onTap:    _pickDate,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: canSave ? _save : null,
              child: const Text('Save problem'),
            ),
          ],
        ),
      ),
    );
  }
}
