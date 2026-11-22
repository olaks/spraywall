import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spraywall/app.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/providers/app_providers.dart';
import 'package:spraywall/providers/backup_provider.dart';
import 'package:spraywall/providers/theme_provider.dart';

/// Pumps the whole app, starting at '/', over [db] and empty preferences.
Future<void> pumpApp(WidgetTester tester, AppDatabase db) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      dbProvider.overrideWithValue(db),
      prefsProvider.overrideWithValue(prefs),
      themeIndexProvider.overrideWith(() => ThemeNotifier(0, prefs)),
    ],
    child: const SpraywallApp(),
  ));
  await tester.pumpAndSettle();
}

/// Widget tests run in fake time: drift closes its streams on a timer, so
/// advance the clock a millisecond after removing the tree, or the test ends
/// with a pending timer.
Future<void> teardownTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
}
