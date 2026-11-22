import 'package:flutter/material.dart';
import '../../database/database.dart';

/// Asks for a new wall's name and grade scale, then creates it with its first
/// current layout. Pops with the new wall's id, or null if cancelled.
class NewWallDialog extends StatefulWidget {
  final AppDatabase db;
  const NewWallDialog({super.key, required this.db});

  @override
  State<NewWallDialog> createState() => _NewWallDialogState();
}

class _NewWallDialogState extends State<NewWallDialog> {
  final _name  = TextEditingController();
  GradeScale _scale = GradeScale.font;
  String?    _error;
  bool       _busy  = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final id = await widget.db.createWall(
          name: _name.text, gradeScale: _scale);
      if (mounted) Navigator.of(context).pop(id);
    } on WallNameTaken catch (e) {
      setState(() {
        _busy  = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = _name.text.trim().isNotEmpty && !_busy;
    return AlertDialog(
      title: const Text('New wall'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            autofocus:  true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: 'Name', errorText: _error),
            onChanged:  (_) => setState(() => _error = null),
            onSubmitted: (_) => canCreate ? _create() : null,
          ),
          const SizedBox(height: 16),
          const Text('Grade scale'),
          const SizedBox(height: 8),
          SegmentedButton<GradeScale>(
            segments: const [
              ButtonSegment(value: GradeScale.font, label: Text('Font')),
              ButtonSegment(value: GradeScale.v,    label: Text('V')),
            ],
            selected: {_scale},
            onSelectionChanged: (s) => setState(() => _scale = s.single),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canCreate ? _create : null,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
