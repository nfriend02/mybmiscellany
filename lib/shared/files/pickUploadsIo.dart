import 'package:file_picker/file_picker.dart';

import 'uploadBytes.dart';

Future<List<UploadBytes>> pickUploads({
  bool allowMultiple = false,
  List<String>? extensions,
  bool audio = false,
}) async {
  final type = audio
      ? FileType.audio
      : (extensions == null || extensions.isEmpty
            ? FileType.any
            : FileType.custom);
  final List<PlatformFile> picked;
  if (allowMultiple) {
    picked = await FilePicker.pickFiles(
      type: type,
      allowedExtensions: type == FileType.custom ? extensions : null,
    );
  } else {
    final file = await FilePicker.pickFile(
      type: type,
      allowedExtensions: type == FileType.custom ? extensions : null,
    );
    picked = file == null ? [] : [file];
  }
  final uploads = <UploadBytes>[];
  for (final file in picked) {
    uploads.add(UploadBytes(name: file.name, bytes: await file.readAsBytes()));
  }
  return uploads;
}
