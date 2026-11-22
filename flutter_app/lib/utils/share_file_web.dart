import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// A browser can only download: a link to the bytes, clicked. The link is
/// freed a little later, once the download has surely started.
Future<bool> shareFile(Uint8List bytes, String fileName, String mimeType) async {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url  = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href     = url
    ..download = fileName
    ..click();
  Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
  return true;
}
