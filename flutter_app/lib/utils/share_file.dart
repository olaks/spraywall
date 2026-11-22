import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'share_file_io.dart'
    if (dart.library.js_interop) 'share_file_web.dart' as platform;

/// One finished file to hand over.
typedef SharedFile = ({Uint8List bytes, String name});

/// Hands finished files of one [mimeType] to the user: the share sheet on
/// Android, a save dialog on the desktop (a folder for several), downloads
/// on the web. True once they went somewhere, false if the user backed out.
typedef ShareFiles = Future<bool> Function(
    List<SharedFile> files, String mimeType);

/// Overridden in widget tests, where no platform channel answers.
final shareFilesProvider = Provider<ShareFiles>((ref) => platform.shareFiles);
