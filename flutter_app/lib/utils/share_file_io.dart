import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'share_file.dart';

/// Phones share through the sheet. The desktop asks where to save one file,
/// and the save dialog writes it; several go into a folder it asks for.
Future<bool> shareFiles(List<SharedFile> files, String mimeType) async {
  if (Platform.isAndroid || Platform.isIOS) {
    final dir = await getTemporaryDirectory();
    final out = <XFile>[];
    for (final f in files) {
      final file = File('${dir.path}/${f.name}');
      await file.writeAsBytes(f.bytes, flush: true);
      out.add(XFile(file.path, mimeType: mimeType));
    }
    final result = await SharePlus.instance.share(ShareParams(
      files:   out,
      subject: files.length == 1 ? files.single.name : null,
    ));
    // "Unavailable" is a platform that can't tell: count it as shared.
    return result.status != ShareResultStatus.dismissed;
  }

  if (files.length == 1) {
    final f = files.single;
    final path = await FilePicker.saveFile(
      dialogTitle: 'Save ${f.name}',
      fileName:    f.name,
      type:        FileType.custom,
      allowedExtensions: [f.name.split('.').last],
      bytes:       f.bytes,
    );
    return path != null;
  }
  final dir = await FilePicker.getDirectoryPath(
      dialogTitle: 'Choose a folder for ${files.length} files');
  if (dir == null) return false;
  for (final f in files) {
    await File('$dir/${f.name}').writeAsBytes(f.bytes, flush: true);
  }
  return true;
}
