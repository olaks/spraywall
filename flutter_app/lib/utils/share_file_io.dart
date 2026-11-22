import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Phones share through the sheet; the desktop asks where to save, and the
/// save dialog writes the file itself.
Future<bool> shareFile(Uint8List bytes, String fileName, String mimeType) async {
  if (Platform.isAndroid || Platform.isIOS) {
    final dir  = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    final result = await SharePlus.instance.share(ShareParams(
      files:   [XFile(file.path, mimeType: mimeType)],
      subject: fileName,
    ));
    // "Unavailable" is a platform that can't tell: count it as shared.
    return result.status != ShareResultStatus.dismissed;
  }
  final path = await FilePicker.saveFile(
    dialogTitle: 'Save $fileName',
    fileName:    fileName,
    type:        FileType.custom,
    allowedExtensions: [fileName.split('.').last],
    bytes:       bytes,
  );
  return path != null;
}
