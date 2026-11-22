// Conditional export: only browsers can evict the app's storage.
export 'persist_storage_io.dart'
    if (dart.library.js_interop) 'persist_storage_web.dart';
