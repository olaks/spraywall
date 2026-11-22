import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'share_file_io.dart'
    if (dart.library.js_interop) 'share_file_web.dart' as platform;

/// Hands a finished file to the user: the share sheet on Android, a save
/// dialog on the desktop, a download on the web. True once it went
/// somewhere, false if the user backed out.
typedef ShareFile = Future<bool> Function(
    Uint8List bytes, String fileName, String mimeType);

/// Overridden in widget tests, where no platform channel answers.
final shareFileProvider = Provider<ShareFile>((ref) => platform.shareFile);
