import 'package:flutter/material.dart';
import '../../database/database.dart';

enum EditWallResult { saved, exported, deleted }

/// Renames a wall and sets its grade scale, or asks for it to be exported or
/// deleted. Saving happens here, so a clashing name can be refused in place;
/// exporting and deleting are left to the caller, which shows how they went
/// (and, to delete, has to leave the wall's screen first).
class EditWallDialog extends StatefulWidget {
  final AppDatabase db;
  final Wall        wall;

  /// Whether any of the wall's problems has a grade, which locks the scale.
  final bool hasGrades;

  const EditWallDialog({
    super.key,
    required this.db,
    required this.wall,
    required this.hasGrades,
  });

  @override
  State<EditWallDialog> createState() => _EditWallDialogState();
}

class _EditWallDialogState extends State<EditWallDialog> {
  late final _name  = TextEditingController(text: widget.wall.name);
  late GradeScale _scale = widget.wall.gradeScale;
  String? _error;
  bool    _busy  = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await widget.db.editWall(widget.wall.id,
          name: _name.text, gradeScale: _scale);
      if (mounted) Navigator.of(context).pop(EditWallResult.saved);
    } on WallNameTaken catch (e) {
      setState(() {
        _busy  = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _name.text.trim().isNotEmpty && !_busy;
    final theme   = Theme.of(context);
    return AlertDialog(
      title: const Text('Edit wall'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: 'Name', errorText: _error),
            onChanged:  (_) => setState(() => _error = null),
            onSubmitted: (_) => canSave ? _save() : null,
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
            onSelectionChanged: widget.hasGrades
                ? null
                : (s) => setState(() => _scale = s.single),
          ),
          if (widget.hasGrades) ...[
            const SizedBox(height: 8),
            Text(
              'Locked: some problems on this wall have grades. '
              'Remove them to switch scale.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _busy
                ? null
                : () => Navigator.of(context).pop(EditWallResult.exported),
            icon:  const Icon(Icons.download),
            label: const Text('Export this wall'),
          ),
          TextButton.icon(
            onPressed: _busy
                ? null
                : () => Navigator.of(context).pop(EditWallResult.deleted),
            style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error),
            icon:  const Icon(Icons.delete_outline),
            label: const Text('Delete wall'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSave ? _save : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
