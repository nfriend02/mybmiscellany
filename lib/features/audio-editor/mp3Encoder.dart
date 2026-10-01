import 'dart:typed_data';

import 'package:shine_dart/shine.dart';

import 'audioEditorService.dart';

Uint8List encodeWavToMp3(Uint8List wavBytes) {
  final pcm = readWavPcm(wavBytes);
  if (pcm == null) {
    throw const FormatException('MP3 저장은 16비트 PCM WAV에서 동작합니다.');
  }
  if (pcm.channels != 1 && pcm.channels != 2) {
    throw const FormatException('MP3 저장은 1채널 또는 2채널 오디오만 지원합니다.');
  }
  const targetRate = 44100;
  final samples = pcm.sampleRate == targetRate
      ? pcm.samples
      : _resample(pcm.samples, pcm.channels, pcm.sampleRate, targetRate);
  final mono = pcm.channels == 1;
  final config = ShineConfig(
    wave: ShineWave(
      channels: mono ? Channels.pcmMono : Channels.pcmStereo,
      samplerate: targetRate,
    ),
    mpeg: ShineMpeg()
      ..bitr = mono ? 128 : 192
      ..mode = mono ? StereoMode.mono : StereoMode.stereo,
  );
  final encoder = shineInitialise(config);
  if (encoder == null) {
    throw const FormatException('이 오디오는 MP3로 변환하지 못했습니다.');
  }
  final samplesPerPass = shineSamplesPerPass(encoder);
  final frameSize = samplesPerPass * pcm.channels;
  final builder = BytesBuilder();
  var offset = 0;
  while (offset < samples.length) {
    final frame = Int16List(frameSize);
    final remaining = samples.length - offset;
    final copy = remaining < frameSize ? remaining : frameSize;
    frame.setRange(0, copy, samples, offset);
    final encoded = shineEncodeBufferInterleaved(encoder, frame);
    builder.add(Uint8List.fromList(encoded.buffer));
    offset += frameSize;
  }
  final flush = shineFlush(encoder);
  builder.add(Uint8List.fromList(flush.buffer));
  shineClose(encoder);
  final mp3 = builder.takeBytes();
  if (mp3.isEmpty) {
    throw const FormatException('MP3 데이터가 비어 있습니다.');
  }
  return mp3;
}

Int16List _resample(Int16List input, int channels, int fromRate, int toRate) {
  final inFrames = input.length ~/ channels;
  if (inFrames == 0) return input;
  final outFrames = (inFrames * toRate / fromRate).round().clamp(1, 1 << 30);
  final output = Int16List(outFrames * channels);
  for (var frame = 0; frame < outFrames; frame++) {
    final source = frame * fromRate / toRate;
    final left = source.floor().clamp(0, inFrames - 1);
    final right = (left + 1).clamp(0, inFrames - 1);
    final mix = source - left;
    for (var channel = 0; channel < channels; channel++) {
      final start = input[left * channels + channel];
      final end = input[right * channels + channel];
      output[frame * channels + channel] = (start + (end - start) * mix)
          .round();
    }
  }
  return output;
}
