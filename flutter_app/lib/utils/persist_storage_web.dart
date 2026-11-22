import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Asks the browser not to evict this site's storage (OPFS holds the whole
/// database, photos included) under storage pressure. Browsers may grant it
/// silently, prompt, or refuse; the app works the same either way.
Future<void> requestPersistentStorage() async {
  try {
    final storage = web.window.navigator.storage;
    if (!(await storage.persisted().toDart).toDart) {
      await storage.persist().toDart;
    }
  } catch (_) {
    // Not offered (an older browser, a private window): nothing to do.
  }
}
