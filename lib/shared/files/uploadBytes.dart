import 'dart:typed_data';

class UploadBytes {
  const UploadBytes({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}
