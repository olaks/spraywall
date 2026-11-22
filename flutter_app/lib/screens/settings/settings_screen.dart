import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../backup/backup_export.dart';
import '../../backup/backup_import.dart';
import '../../database/database.dart';
import '../../photos/photo_import.dart';
import '../../providers/app_providers.dart';
import '../../providers/backup_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/pick_binary_file.dart';
import '../../utils/share_file.dart';
import '../../widgets/wide.dart';

/// Things that apply to the whole app. Everything lives on this device, so
/// backups lead: the status, the full export, and import.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _exportAll() async {
    final messenger = ScaffoldMessenger.of(context);
    final now       = ref.read(clockProvider)();
    setState(() => _busy = true);
    try {
      final bytes = await exportBackup(ref.read(dbProvider), now: now);
      final sent  = await ref.read(shareFileProvider)(
          bytes, backupFileName(now), 'application/zip');
      // Backing out of the save dialog or the share sheet is no backup.
      if (!sent) return;
      await ref.read(backupProvider.notifier).recordBackup(now);
      messenger.showSnackBar(const SnackBar(content: Text('Backup exported')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Picks a backup, checks all of it, makes the new photos' thumbnails
  /// with progress, merges it in one transaction, and says what happened.
  /// A backup that fails a check writes nothing. There is no undo.
  Future<void> _import() async {
    final bytes = await ref.read(pickBinaryFileProvider)(extension: 'zip');
    if (bytes == null || !mounted) return;
    final db        = ref.read(dbProvider);
    final parse     = ref.read(backupParserProvider);
    final thumb     = ref.read(thumbMakerProvider);
    final navigator = Navigator.of(context, rootNavigator: true);
    final progress  = ValueNotifier<_Progress>((step: 'Reading the backup', done: null));
    setState(() => _busy = true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProgressDialog(progress),
    );

    Object? failure;
    ImportSummary? summary;
    try {
      final rows   = await parse(bytes);
      final fresh  = await db.newPhotoIds([for (final p in rows.photos) p.id]);
      final thumbs = <String, Uint8List>{};
      for (final id in fresh) {
        progress.value = (
          step: 'Making thumbnails (${thumbs.length + 1} of ${fresh.length})',
          done: thumbs.length / fresh.length,
        );
        thumbs[id] = await thumb(rows.photoData[id]!);
      }
      progress.value = (step: 'Importing', done: null);
      summary = await db.importBackup(rows, thumbs);
    } on UnreadablePhoto {
      failure = "This backup is damaged: one of its photos can't be read.";
    } catch (e) {
      failure = e;
    } finally {
      navigator.pop();
      progress.dispose();
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key:   const ValueKey('import-result'),
        title: Text(summary == null ? 'Import failed' : 'Backup imported'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (summary == null)
              Text('$failure\n\nNothing was changed.')
            else
              for (final line in importSummaryLines(summary))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(line),
                ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeIdx = ref.watch(themeIndexProvider);
    final status   = ref.watch(backupProvider);
    final hasData  = ref.watch(wallsProvider).value?.isNotEmpty ?? false;
    final now      = ref.watch(clockProvider)();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ReadableWidth(builder: (context, sides) => ListView(
        padding: sides + const EdgeInsets.only(bottom: 32),
        children: [
          const _SectionLabel('BACKUP'),
          _BackupStatusCard(status: status, now: now, hasData: hasData),
          ListTile(
            leading:  const Icon(Icons.download),
            title:    const Text('Export everything'),
            subtitle: const Text('All walls with their photos, as a .zip you keep'),
            enabled:  hasData && !_busy,
            onTap:    _exportAll,
          ),
          ListTile(
            leading:  const Icon(Icons.upload),
            title:    const Text('Import backup'),
            subtitle: const Text('Merge a backup into what is here'),
            enabled:  !_busy,
            onTap:    _import,
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(minHeight: 2),
            ),

          const Divider(height: 32),
          const _SectionLabel('APPEARANCE'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: AccentPicker(
              selected: themeIdx,
              onSelect: (i) =>
                  ref.read(themeIndexProvider.notifier).setTheme(i),
            ),
          ),
        ],
      )),
    );
  }
}

typedef _Progress = ({String step, double? done});

/// What the import is doing; it can't be dismissed, and closes itself.
class _ProgressDialog extends StatelessWidget {
  final ValueListenable<_Progress> progress;
  const _ProgressDialog(this.progress);

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Importing backup'),
          content: ValueListenableBuilder<_Progress>(
            valueListenable: progress,
            builder: (context, p, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.step),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: p.done),
              ],
            ),
          ),
        ),
      );
}

/// How long ago the last full export was: calm while it is recent, a
/// warning once a month has gone by (or never, with walls to lose).
class _BackupStatusCard extends StatelessWidget {
  final BackupStatus status;
  final DateTime     now;
  final bool         hasData;
  const _BackupStatusCard({
    required this.status,
    required this.now,
    required this.hasData,
  });

  @override
  Widget build(BuildContext context) {
    final days  = status.daysSinceBackup(now);
    final stale = hasData && (days == null || days >= kBackupStaleDays);
    final color = stale
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        key:     const ValueKey('backup-status'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          Icon(stale ? Icons.warning_amber_rounded : Icons.check_circle,
              size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(backupStatusText(status, now, hasData: hasData),
                style: const TextStyle(fontSize: 13)),
          ),
        ]),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary)),
      );
}

/// The four accent colours, as a row of swatches.
class AccentPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const AccentPicker({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(themeAccents.length, (i) {
          final accent = themeAccents[i];
          final isSelected = selected == i;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.15),
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.black, size: 22)
                      : null,
                ),
                const SizedBox(height: 6),
                Text(accent.name,
                    style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5))),
              ],
            ),
          );
        }),
      );
}
