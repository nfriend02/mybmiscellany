import 'dart:typed_data';

class WavEditResult {
  const WavEditResult({
    required this.processed,
    required this.message,
    this.bytes,
    this.startSeconds = 0,
    this.endSeconds = 0,
  });

  final bool processed;
  final String message;
  final Uint8List? bytes;
  final double startSeconds;
  final double endSeconds;
}

String audioMime(String filename) {
  final extension = filename.contains('.')
      ? filename.split('.').last.toLowerCase()
      : '';
  return switch (extension) {
    'mp3' => 'audio/mpeg',
    'wav' => 'audio/wav',
    'm4a' => 'audio/mp4',
    'aac' => 'audio/aac',
    'ogg' => 'audio/ogg',
    'webm' => 'audio/webm',
    'flac' => 'audio/flac',
    _ => 'application/octet-stream',
  };
}

WavEditResult editWav(
  Uint8List bytes, {
  required double volume,
  required double startRatio,
  required double endRatio,
}) {
  final parsed = _parsePcm16(bytes);
  if (parsed == null) {
    return const WavEditResult(
      processed: false,
      message:
          '바이트 단위 변환은 16비트 PCM WAV에서 동작합니다. 다른 형식은 미리보기에서 볼륨과 트림을 확인할 수 있습니다.',
    );
  }
  final frameSize = parsed.channels * 2;
  final frames = parsed.dataLength ~/ frameSize;
  if (frames == 0) {
    throw const FormatException('오디오 데이터가 비어 있습니다.');
  }
  final start = (frames * startRatio).floor().clamp(0, frames - 1);
  final end = (frames * endRatio).ceil().clamp(start + 1, frames);
  final view = ByteData.sublistView(
    bytes,
    parsed.dataOffset,
    parsed.dataOffset + parsed.dataLength,
  );
  final output = BytesBuilder();
  for (var frame = start; frame < end; frame++) {
    for (var channel = 0; channel < parsed.channels; channel++) {
      final sample = view.getInt16(
        (frame * parsed.channels + channel) * 2,
        Endian.little,
      );
      final scaled = (sample * volume).round().clamp(-32768, 32767);
      final pair = ByteData(2)..setInt16(0, scaled, Endian.little);
      output.add(pair.buffer.asUint8List());
    }
  }
  final pcm = output.toBytes();
  return WavEditResult(
    processed: true,
    bytes: buildPcm16Wav(
      sampleRate: parsed.sampleRate,
      channels: parsed.channels,
      pcm: pcm,
    ),
    message:
        '볼륨 ${volume.toStringAsFixed(2)}배, ${(start / parsed.sampleRate).toStringAsFixed(2)}초부터 ${(end / parsed.sampleRate).toStringAsFixed(2)}초까지 잘라 WAV로 만들었습니다.',
    startSeconds: start / parsed.sampleRate,
    endSeconds: end / parsed.sampleRate,
  );
}

Uint8List buildPcm16Wav({
  required int sampleRate,
  required int channels,
  required Uint8List pcm,
}) {
  final dataLength = pcm.length;
  final header = BytesBuilder();
  void addString(String value) => header.add(value.codeUnits);
  void add32(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.little);
    header.add(data.buffer.asUint8List());
  }

  void add16(int value) {
    final data = ByteData(2)..setUint16(0, value, Endian.little);
    header.add(data.buffer.asUint8List());
  }

  addString('RIFF');
  add32(36 + dataLength);
  addString('WAVE');
  addString('fmt ');
  add32(16);
  add16(1);
  add16(channels);
  add32(sampleRate);
  add32(sampleRate * channels * 2);
  add16(channels * 2);
  add16(16);
  addString('data');
  add32(dataLength);
  header.add(pcm);
  return header.toBytes();
}

class _Wav {
  const _Wav({
    required this.channels,
    required this.sampleRate,
    required this.dataOffset,
    required this.dataLength,
  });

  final int channels;
  final int sampleRate;
  final int dataOffset;
  final int dataLength;
}

_Wav? _parsePcm16(Uint8List bytes) {
  if (bytes.length < 44) return null;
  final data = ByteData.sublistView(bytes);
  if (data.getUint32(0, Endian.little) != 0x46464952) return null;
  if (data.getUint32(8, Endian.little) != 0x45564157) return null;
  var offset = 12;
  int? channels;
  int? sampleRate;
  int? bits;
  int? dataOffset;
  int? dataLength;
  while (offset + 8 <= bytes.length) {
    final id = data.getUint32(offset, Endian.little);
    final size = data.getUint32(offset + 4, Endian.little);
    final start = offset + 8;
    if (id == 0x20746d66 && start + 16 <= bytes.length) {
      if (data.getUint16(start, Endian.little) != 1) return null;
      channels = data.getUint16(start + 2, Endian.little);
      sampleRate = data.getUint32(start + 4, Endian.little);
      bits = data.getUint16(start + 14, Endian.little);
    } else if (id == 0x61746164) {
      dataOffset = start;
      dataLength = size;
    }
    final next = start + size + (size.isOdd ? 1 : 0);
    if (next <= offset) return null;
    offset = next;
  }
  if (channels == null ||
      sampleRate == null ||
      bits != 16 ||
      dataOffset == null ||
      dataLength == null) {
    return null;
  }
  if (dataOffset + dataLength > bytes.length) return null;
  return _Wav(
    channels: channels,
    sampleRate: sampleRate,
    dataOffset: dataOffset,
    dataLength: dataLength,
  );
}
