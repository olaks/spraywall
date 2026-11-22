import 'package:flutter/material.dart';
import '../../database/database.dart';
import '../../utils/format_utils.dart';
import '../../utils/grades.dart';

/// A problem's details: name (required, unique in the layout), grade,
/// description and set date. [submit] does whatever the caller needs with
/// them (create the problem, or just check the name) and may throw
/// [ProblemNameTaken], which keeps the sheet open with the reason. Pops with
/// the details once [submit] succeeds.
class ProblemDetailsSheet extends StatefulWidget {
  final GradeScale                              gradeScale;
  final ProblemDetails?                         initial;
  final String                                  actionLabel;
  final Future<void> Function(ProblemDetails)   submit;

  /// Today, for a new problem's set date. Injected by tests.
  final DateTime? today;

  const ProblemDetailsSheet({
    super.key,
    required this.gradeScale,
    required this.actionLabel,
    required this.submit,
    this.initial,
    this.today,
  });

  @override
  State<ProblemDetailsSheet> createState() => _ProblemDetailsSheetState();
}

class _ProblemDetailsSheetState extends State<ProblemDetailsSheet> {
  late final _name        = TextEditingController(text: widget.initial?.name);
  late final _description =
      TextEditingController(text: widget.initial?.description);
  late DateTime _setOn = widget.initial?.setOn ?? widget.today ?? DateTime.now();
  late String?  _grade = widget.initial?.grade;
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

  Future<void> _submit() async {
    setState(() => _busy = true);
    final ProblemDetails details = (
      name:        _name.text.trim(),
      grade:       _grade,
      description: _description.text.trim(),
      setOn:       _setOn,
    );
    try {
      await widget.submit(details);
      if (mounted) Navigator.of(context).pop(details);
    } on ProblemNameTaken catch (e) {
      setState(() {
        _busy  = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _name.text.trim().isNotEmpty && !_busy;
    final grades    = gradesFor(widget.gradeScale);
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
              autofocus:  widget.initial == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: 'Name', errorText: _error),
              onChanged:  (_) => setState(() => _error = null),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              key:          const ValueKey('problem-grade'),
              // A grade off the scale (not possible today) shows as ungraded.
              initialValue: grades.contains(_grade) ? _grade : null,
              decoration:   const InputDecoration(labelText: 'Grade'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Ungraded')),
                for (final g in grades)
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
              onPressed: canSubmit ? _submit : null,
              child: Text(widget.actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
