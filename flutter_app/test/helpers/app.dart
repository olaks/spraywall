import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spraywall/app.dart';
import 'package:spraywall/backup/backup_import.dart';
import 'package:spraywall/database/database.dart';
import 'package:spraywall/photos/photo_import.dart';
import 'package:spraywall/photos/photo_source.dart';
import 'package:spraywall/providers/app_providers.dart';
import 'package:spraywall/providers/backup_provider.dart';
import 'package:spraywall/providers/theme_provider.dart';
import 'package:spraywall/share/share_problem.dart';
import 'package:spraywall/utils/pick_binary_file.dart';
import 'package:spraywall/utils/share_file.dart';

/// Hands over fixture bytes instead of opening a picker, and records what
/// was asked of it.
class FakePhotoSource implements PhotoSource {
  @override
  bool supportsCamera;

  /// What the next [pick] returns; null is the user backing out.
  Uint8List? next;

  /// What [retrieveLost] returns, once.
  (Uint8List, String)? lost;

  final picks = <PhotoFrom>[];

  FakePhotoSource({this.supportsCamera = false, this.next});

  @override
  Future<Uint8List?> pick(PhotoFrom from, String layoutId) async {
    picks.add(from);
    return next;
  }

  @override
  Future<(Uint8List, String)?> retrieveLost() async {
    final l = lost;
    lost = null;
    return l;
  }
}

/// Stands in for the share sheet, save dialog or download: keeps every file
/// it was handed, and says they went somewhere unless [backOut] is set.
class FakeShare {
  final files = <({Uint8List bytes, String name, String mimeType})>[];
  var   calls = 0;
  bool backOut = false;

  Future<bool> call(List<SharedFile> handed, String mimeType) async {
    calls++;
    files.addAll([
      for (final f in handed) (bytes: f.bytes, name: f.name, mimeType: mimeType),
    ]);
    return !backOut;
  }
}

/// A phone held upright: the narrow layout. Wide-window tests pass their
/// own [pumpApp] size.
const phone = Size(400, 800);

/// Pumps the whole app, starting at '/', over [db] and empty preferences, in
/// a window of [size] logical pixels (a phone unless given). [clock] stands
/// in for `DateTime.now` where the backup reminder reads it. With
/// [keepPrefs] it reopens the app over what the last run stored, as a user
/// coming back days later would. [pickedFile] is what the file picker hands
/// back (null: the user backed out); [thumbMaker] replaces the inline
/// thumbnail maker, to hold an import part-way.
/// Photo import, reading a backup, making thumbnails and encoding share
/// images run inline: an isolate never finishes under fake time.
Future<void> pumpApp(
  WidgetTester tester,
  AppDatabase  db, {
  PhotoSource? photos,
  Size         size = phone,
  FakeShare?   share,
  DateTime Function()? clock,
  bool         keepPrefs = false,
  Uint8List?   pickedFile,
  Future<Uint8List> Function(Uint8List)? thumbMaker,
}) async {
  tester.view.physicalSize     = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  if (!keepPrefs) SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      dbProvider.overrideWithValue(db),
      prefsProvider.overrideWithValue(prefs),
      themeIndexProvider.overrideWith(() => ThemeNotifier(0, prefs)),
      photoSourceProvider.overrideWithValue(photos ?? FakePhotoSource()),
      photoImporterProvider.overrideWithValue((bytes) async => importPhoto(bytes)),
      shareFilesProvider.overrideWithValue((share ?? FakeShare()).call),
      pickBinaryFileProvider.overrideWithValue(
          ({required extension}) async => pickedFile),
      backupParserProvider.overrideWithValue((bytes) async => parseBackup(bytes)),
      shareEncoderProvider.overrideWithValue((image) async => encodeShareJpeg(image)),
      thumbMakerProvider.overrideWithValue(
          thumbMaker ?? (data) async => makeThumb(data)),
      if (clock != null) clockProvider.overrideWithValue(clock),
    ],
    child: const SpraywallApp(),
  ));
  await tester.pumpAndSettle();
}

/// A widget test over the app: [testWidgets] with [teardownTree] run after
/// the body, pass or fail. It has to run inside the body, because the binding
/// checks for pending timers before any `addTearDown`; and a failing test that
/// skips it leaves drift's timers pending and hangs the runner for minutes.
void testApp(String description, Future<void> Function(WidgetTester) body) =>
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        await teardownTree(tester);
      }
    });

/// Widget tests run in fake time: drift closes its streams on a timer, so
/// advance the clock a millisecond after removing the tree, or the test ends
/// with a pending timer.
Future<void> teardownTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
}

/// Lets drift's change notifications reach the app's streams. Under fake
/// time some don't arrive (a reset swaps the screen onto the new layout's
/// streams), so alternate short real-time gaps with frames. Not
/// `pumpAndSettle`: while a stream loads, a spinning progress indicator
/// never settles. The in-memory database answers in well under a
/// millisecond.
Future<void> settleDb(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Navigates the running app to [path], as a typed URL or deep link would.
Future<void> goTo(WidgetTester tester, String path) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(path);
  await tester.pumpAndSettle();
}
