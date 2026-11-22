import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/backup_provider.dart';
import 'photo_import.dart';

enum PhotoFrom { camera, file }

/// Where wall photos come from. Behind a provider so widget tests can hand
/// over fixture bytes instead of opening a picker.
abstract class PhotoSource {
  /// Whether this platform can take a photo (not Linux, for one).
  bool get supportsCamera;

  /// The picked photo's bytes, or null if the user backed out. [layoutId] is
  /// remembered in case Android kills the app while the camera is open.
  Future<Uint8List?> pick(PhotoFrom from, String layoutId);

  /// A photo taken before Android killed the app, and the layout it was for.
  Future<(Uint8List, String)?> retrieveLost();
}

const _kPendingLayoutKey = 'pending_photo_layout';

/// [PhotoSource] over `image_picker`. Its own resize and quality options stay
/// unused: [importPhoto] does that, and strips the EXIF the picker keeps.
class ImagePickerSource implements PhotoSource {
  final ImagePicker       _picker = ImagePicker();
  final SharedPreferences _prefs;
  ImagePickerSource(this._prefs);

  @override
  bool get supportsCamera => _picker.supportsImageSource(ImageSource.camera);

  @override
  Future<Uint8List?> pick(PhotoFrom from, String layoutId) async {
    await _prefs.setString(_kPendingLayoutKey, layoutId);
    try {
      final file = await _picker.pickImage(
          source: from == PhotoFrom.camera ? ImageSource.camera : ImageSource.gallery);
      return file?.readAsBytes();
    } finally {
      await _prefs.remove(_kPendingLayoutKey);
    }
  }

  @override
  Future<(Uint8List, String)?> retrieveLost() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final layoutId = _prefs.getString(_kPendingLayoutKey);
    final lost     = await _picker.retrieveLostData();
    await _prefs.remove(_kPendingLayoutKey);
    final file = lost.file;
    if (lost.isEmpty || file == null || layoutId == null) return null;
    return (await file.readAsBytes(), layoutId);
  }
}

final photoSourceProvider = Provider<PhotoSource>(
    (ref) => ImagePickerSource(ref.watch(prefsProvider)));

/// Runs [importPhoto] off the UI thread. Overridden in widget tests, where an
/// isolate never finishes under fake time.
final photoImporterProvider =
    Provider<Future<ImportedPhoto> Function(Uint8List)>(
        (ref) => (bytes) => compute(importPhoto, bytes));
