import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'photo_import.dart';
import 'photo_source.dart';

/// Adds a wall photo to [layoutId]: asks camera or file where the camera is
/// available, imports the pick, and stores it. Returns the new photo's id,
/// or null if the user backed out or the file wasn't a photo.
Future<String?> addWallPhoto(
    BuildContext context, WidgetRef ref, String layoutId) async {
  final source    = ref.read(photoSourceProvider);
  final importer  = ref.read(photoImporterProvider);
  final db        = ref.read(dbProvider);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);

  var from = PhotoFrom.file;
  if (source.supportsCamera) {
    final chosen = await showModalBottomSheet<PhotoFrom>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title:   const Text('Take a photo'),
            onTap:   () => Navigator.pop(context, PhotoFrom.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title:   const Text('Choose a photo'),
            onTap:   () => Navigator.pop(context, PhotoFrom.file),
          ),
        ]),
      ),
    );
    if (chosen == null) return null;
    from = chosen;
  }

  final bytes = await source.pick(from, layoutId);
  if (bytes == null || !context.mounted) return null;

  // Decoding and re-encoding a phone photo takes a second or two.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 24),
          Text('Adding photo…'),
        ]),
      ),
    ),
  );
  try {
    return await db.addPhoto(layoutId, await importer(bytes));
  } on UnreadablePhoto catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('$e')));
    return null;
  } finally {
    navigator.pop();
  }
}

/// Adds a photo Android took while it killed the app, to the layout it was
/// meant for, if that layout is still there. Returns whether it added one.
Future<bool> recoverLostPhoto(WidgetRef ref) async {
  final lost = await ref.read(photoSourceProvider).retrieveLost();
  if (lost == null) return false;
  final (bytes, layoutId) = lost;
  final db = ref.read(dbProvider);
  if (await db.layout(layoutId) == null) return false;
  try {
    await db.addPhoto(layoutId, await ref.read(photoImporterProvider)(bytes));
    return true;
  } on UnreadablePhoto {
    return false;
  }
}
