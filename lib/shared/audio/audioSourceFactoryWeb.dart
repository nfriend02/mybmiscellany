import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

Future<AudioSource> buildAudioSource(
  Uint8List bytes,
  String filename,
  String mimeType,
) async {
  return AudioSource.uri(Uri.dataFromBytes(bytes, mimeType: mimeType));
}
