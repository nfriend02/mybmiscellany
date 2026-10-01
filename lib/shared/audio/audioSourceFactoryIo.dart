import 'dart:io';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

Future<AudioSource> buildAudioSource(
  Uint8List bytes,
  String filename,
  String mimeType,
) async {
  final dir = await getTemporaryDirectory();
  final safe = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final file = File('${dir.path}${Platform.pathSeparator}$safe');
  await file.writeAsBytes(bytes, flush: true);
  return AudioSource.file(file.path);
}
