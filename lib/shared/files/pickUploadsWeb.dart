import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'uploadBytes.dart';

Future<List<UploadBytes>> pickUploads({
  bool allowMultiple = false,
  List<String>? extensions,
  bool audio = false,
}) async {
  final body = web.document.body;
  if (body == null) {
    throw const FormatException('이 브라우저에서는 파일을 열 수 없습니다.');
  }
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..multiple = allowMultiple
    ..accept = _accept(extensions: extensions, audio: audio);
  input.style
    ..setProperty('position', 'fixed')
    ..setProperty('left', '0')
    ..setProperty('top', '0')
    ..setProperty('opacity', '0')
    ..setProperty('width', '1px')
    ..setProperty('height', '1px');
  body.append(input);

  final completer = Completer<List<web.File>>();
  void finish(List<web.File> files) {
    input.remove();
    if (!completer.isCompleted) completer.complete(files);
  }

  input.addEventListener(
    'change',
    ((web.Event _) {
      final selected = input.files;
      final files = <web.File>[];
      if (selected != null) {
        for (var index = 0; index < selected.length; index++) {
          final file = selected.item(index);
          if (file != null) files.add(file);
        }
      }
      finish(files);
    }).toJS,
  );
  input.addEventListener('cancel', ((web.Event _) => finish([])).toJS);
  input.click();

  final selected = await completer.future;
  final uploads = <UploadBytes>[];
  for (final file in selected) {
    final bytes = await _readFile(file);
    if (bytes.isEmpty) {
      throw FormatException('${file.name} 을 읽지 못했습니다.');
    }
    uploads.add(UploadBytes(name: file.name, bytes: bytes));
  }
  return uploads;
}

String _accept({List<String>? extensions, required bool audio}) {
  if (audio) {
    return 'audio/*,.wav,.mp3,.m4a,.aac,.ogg,.flac,.webm';
  }
  if (extensions == null || extensions.isEmpty) return '';
  const mime = {
    'pdf': 'application/pdf',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'txt': 'text/plain',
    'md': 'text/markdown,text/plain',
  };
  final parts = <String>[];
  for (final extension in extensions) {
    final clean = extension.toLowerCase().replaceAll('.', '');
    final type = mime[clean];
    if (type != null) parts.add(type);
    parts.add('.$clean');
  }
  return parts.join(',');
}

Future<Uint8List> _readFile(web.File file) {
  final reader = web.FileReader();
  final completer = Completer<Uint8List>();
  reader.addEventListener(
    'loadend',
    ((web.Event _) {
      final result = reader.result;
      if (!completer.isCompleted) {
        if (result != null && result.isA<JSArrayBuffer>()) {
          completer.complete((result as JSArrayBuffer).toDart.asUint8List());
        } else {
          completer.complete(Uint8List(0));
        }
      }
    }).toJS,
  );
  reader.addEventListener(
    'error',
    ((web.Event _) {
      if (!completer.isCompleted) completer.complete(Uint8List(0));
    }).toJS,
  );
  reader.readAsArrayBuffer(file);
  return completer.future;
}
