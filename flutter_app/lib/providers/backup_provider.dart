import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/format_utils.dart';

/// The app keeps everything in a local database with no sync, so an export is
/// the only thing standing between a lost phone and a lost set of walls and
/// problems. This tracks when the last full one happened: exporting one wall
/// leaves the rest unprotected, so it doesn't count.

const _kLastBackupKey = 'last_backup_date';
const _kSnoozeKey     = 'backup_reminder_snoozed';

/// Nag once a month, and stay quiet for a week after being dismissed.
const kBackupStaleDays  = 30;
const kBackupSnoozeDays = 7;

class BackupStatus {
  /// `yyyy-MM-dd` of the last export, or null if there has never been one.
  final String? lastBackup;
  final String? snoozedOn;

  const BackupStatus({this.lastBackup, this.snoozedOn});

  int? daysSinceBackup(DateTime now) => _daysSince(lastBackup, now);

  /// Whether to nudge: overdue (or never done) and not recently dismissed.
  bool needsReminder(DateTime now) {
    final snoozed = _daysSince(snoozedOn, now);
    if (snoozed != null && snoozed < kBackupSnoozeDays) return false;
    final since = daysSinceBackup(now);
    return since == null || since >= kBackupStaleDays;
  }

  static int? _daysSince(String? dateStr, DateTime now) {
    if (dateStr == null) return null;
    final then = dateFromStr(dateStr);
    return DateTime(now.year, now.month, now.day).difference(then).inDays;
  }
}

class BackupNotifier extends Notifier<BackupStatus> {
  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  BackupStatus build() => BackupStatus(
        lastBackup: _prefs.getString(_kLastBackupKey),
        snoozedOn:  _prefs.getString(_kSnoozeKey),
      );

  Future<void> recordBackup([DateTime? now]) async {
    final today = dateStrFrom(now ?? DateTime.now());
    await _prefs.setString(_kLastBackupKey, today);
    // A fresh backup clears any outstanding dismissal.
    await _prefs.remove(_kSnoozeKey);
    state = BackupStatus(lastBackup: today);
  }

  Future<void> snoozeReminder([DateTime? now]) async {
    final today = dateStrFrom(now ?? DateTime.now());
    await _prefs.setString(_kSnoozeKey, today);
    state = BackupStatus(lastBackup: state.lastBackup, snoozedOn: today);
  }
}

/// Overridden in main() with the instance opened at startup.
final prefsProvider = Provider<SharedPreferences>(
    (ref) => throw UnimplementedError('prefsProvider must be overridden'));

final backupProvider =
    NotifierProvider<BackupNotifier, BackupStatus>(BackupNotifier.new);

/// Now, as the backup reminder sees it. Overridden in tests to move time on.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// How exposed the data is, in plain words, for the Settings card.
String backupStatusText(BackupStatus status, DateTime now, {required bool hasData}) {
  final days = status.daysSinceBackup(now);
  if (days == null) {
    return hasData
        ? 'Never backed up. This device holds the only copy of your walls '
            'and problems.'
        : 'No walls yet: nothing to back up.';
  }
  if (days == 0) return 'Backed up today.';
  if (days == 1) return 'Backed up yesterday.';
  if (days < kBackupStaleDays) return 'Backed up $days days ago.';
  return 'Last backup was $days days ago. Anything set since then exists '
      'only on this device.';
}
