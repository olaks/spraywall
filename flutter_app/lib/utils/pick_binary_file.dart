import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks for a single `.$extension` file and returns its bytes, or null if
/// the picker was dismissed. Bytes on every platform, the web included,
/// where there are no paths; a backup is read whole anyway.
Future<Uint8List?> pickBinaryFile({required String extension}) async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: [extension],
    withData: true,
    withReadStream: false,
  );
  return result?.files.single.bytes;
}

/// [pickBinaryFile], overridden in widget tests, where no picker opens.
final pickBinaryFileProvider =
    Provider<Future<Uint8List?> Function({required String extension})>(
        (ref) => pickBinaryFile);
