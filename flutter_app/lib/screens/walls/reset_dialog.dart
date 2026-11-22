import 'package:flutter/material.dart';
import '../../database/database.dart';
import '../../utils/format_utils.dart';

/// What the Reset dialog was given: an optional name and the start date.
typedef ResetChoice = ({String? name, DateTime startedOn});

/// "Start a new layout?": says what the reset archives, and takes the new
/// layout's optional name and start date (today by default, never before
/// the current layout started).
class ResetDialog extends StatefulWidget {
  final Layout current;

  /// The current layout's problems, which the reset archives.
  final int problems;

  /// Injectable for tests.
  final DateTime? today;

  const ResetDialog({
    super.key,
    required this.current,
    required this.problems,
    this.today,
  });

  @override
  State<ResetDialog> createState() => _ResetDialogState();
}

class _ResetDialogState extends State<ResetDialog> {
  final _name = TextEditingController();
  late final DateTime _earliest = dateFromStr(widget.current.startedOn);
  late DateTime _startedOn = () {
    final now   = widget.today ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return today.isBefore(_earliest) ? _earliest : today;
  }();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: _startedOn,
      firstDate:   _earliest,
      lastDate:    _startedOn.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startedOn = picked);
  }

  String get _archives => switch (widget.problems) {
        0 => 'The current layout will be archived.',
        1 => 'The current one will be archived with its 1 problem.',
        final n => 'The current one will be archived with its $n problems.',
      };

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Start a new layout?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_archives),
            const SizedBox(height: 16),
            TextField(
              key:        const ValueKey('layout-name'),
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name (optional)',
                hintText:  'Winter set',
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text('Starts ${dateStrFrom(_startedOn)}')),
              TextButton(onPressed: _pickDate, child: const Text('Change')),
            ]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop<ResetChoice>(
                context, (name: _name.text, startedOn: _startedOn)),
            child: const Text('Reset'),
          ),
        ],
      );
}
