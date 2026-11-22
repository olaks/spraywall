import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;
import 'share_file.dart';

/// A browser can only download: a link to each file's bytes, clicked. The
/// links are freed a little later, once the downloads have surely started.
Future<bool> shareFiles(List<SharedFile> files, String mimeType) async {
  for (final f in files) {
    final blob = web.Blob([f.bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
    final url  = web.URL.createObjectURL(blob);
    web.HTMLAnchorElement()
      ..href     = url
      ..download = f.name
      ..click();
    Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
  }
  return true;
}
