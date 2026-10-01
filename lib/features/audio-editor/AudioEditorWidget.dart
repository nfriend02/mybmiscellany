import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/history/saveResult.dart';
import '../../core/registry/featureModule.dart';
import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';
import '../../shared/audio/audioSourceFactory.dart';
import '../../shared/widgets/FeatureFrame.dart';
import '../../shared/widgets/InputBox.dart';
import '../../shared/widgets/Panels.dart';
import 'audioEditorService.dart';

class AudioEditorWidget extends StatefulWidget {
  const AudioEditorWidget({super.key, required this.module});

  final FeatureModule module;

  @override
  State<AudioEditorWidget> createState() => _AudioEditorWidgetState();
}

class _AudioEditorWidgetState extends State<AudioEditorWidget> {
  final AudioPlayer _player = AudioPlayer();
  final _label = TextEditingController();
  StreamSubscription<PlayerState>? _subscription;
  PickedUpload? _file;
  double _volume = 1;
  RangeValues _trim = const RangeValues(0, 1);
  Duration? _duration;
  bool _playing = false;
  String? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription = _player.playerStateStream.listen((state) {
      if (mounted) setState(() => _playing = state.playing);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _player.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _load(List<PickedUpload> files) async {
    if (files.isEmpty) return;
    final file = files.last;
    setState(() {
      _file = file;
      _label.text = file.name;
      _duration = null;
      _trim = const RangeValues(0, 1);
      _error = null;
      _status = null;
    });
    try {
      final source = await buildAudioSource(
        file.bytes,
        file.name,
        audioMime(file.name),
      );
      final duration = await _player.setAudioSource(source);
      await _player.setVolume(_volume);
      if (!mounted) return;
      setState(() => _duration = duration);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '이 오디오를 재생하지 못했습니다.');
    }
  }

  Future<void> _applyPreview() async {
    final duration = _duration;
    if (duration == null) return;
    final start = Duration(
      milliseconds: (duration.inMilliseconds * _trim.start).round(),
    );
    final end = Duration(
      milliseconds: (duration.inMilliseconds * _trim.end).round(),
    );
    try {
      await _player.setClip(
        start: start,
        end: end == Duration.zero ? null : end,
      );
      await _player.setVolume(_volume);
      if (!mounted) return;
      setState(() => _status = '미리보기에 볼륨과 트림을 적용했습니다.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '트림 미리보기를 적용하지 못했습니다.');
    }
  }

  Future<void> _export() async {
    final file = _file;
    if (file == null) return;
    try {
      final edited = editWav(
        file.bytes,
        volume: _volume,
        startRatio: _trim.start,
        endRatio: _trim.end,
      );
      var saved = false;
      if (edited.processed && edited.bytes != null) {
        final uri = await FilePicker.saveFile(
          fileName: 'edited.wav',
          bytes: edited.bytes!,
          mimeType: 'audio/wav',
        );
        saved = uri != null;
      }
      if (!mounted) return;
      setState(() => _status = edited.message);
      await saveResult(
        context,
        featureType: widget.module.featureType,
        title: file.name,
        preview: edited.message,
        input: {
          'filename': file.name,
          'volume': _volume,
          'trimStart': _trim.start,
          'trimEnd': _trim.end,
        },
        output: {
          'text': edited.message,
          'processedWav': edited.processed,
          'saved': saved,
          'startSeconds': edited.startSeconds,
          'endSeconds': edited.endSeconds,
        },
      );
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = _duration;
    final label = duration == null
        ? '길이를 확인한 뒤 트림할 수 있습니다.'
        : '${_clock(_portion(duration, _trim.start))} - ${_clock(_portion(duration, _trim.end))} / ${_clock(duration)}';
    return FeatureFrame(
      module: widget.module,
      children: [
        InputBox(
          label: '오디오',
          hint: 'wav, mp3, m4a, ogg',
          controller: _label,
          maxLines: 1,
          enableFile: true,
          fileType: FileType.audio,
          onFiles: _load,
        ),
        const SizedBox(height: 8),
        const NoteText(
          '재생 미리보기는 올린 형식 그대로 볼륨과 구간을 적용합니다. 파일로 저장되는 가공은 16비트 PCM WAV입니다.',
        ),
        const SizedBox(height: 12),
        Text(
          '볼륨 ${(_volume * 100).round()}%',
          style: labelText(color: AppColors.ink),
        ),
        Slider(
          min: 0,
          max: 2,
          value: _volume,
          onChanged: (value) {
            setState(() => _volume = value);
            _player.setVolume(value);
          },
        ),
        Text(label, style: bodyText(size: 13, color: AppColors.muted)),
        RangeSlider(
          values: _trim,
          onChanged: duration == null
              ? null
              : (value) => setState(() => _trim = value),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton(
              onPressed: _file == null
                  ? null
                  : () {
                      if (_playing) {
                        _player.pause();
                      } else {
                        _player.play();
                      }
                    },
              child: Text(_playing ? '일시정지' : '재생'),
            ),
            OutlinedButton(
              onPressed: duration == null ? null : _applyPreview,
              child: const Text('미리보기 적용'),
            ),
            OutlinedButton(
              onPressed: _file == null ? null : _export,
              child: const Text('WAV로 저장'),
            ),
          ],
        ),
        if (_status != null) ...[
          const SizedBox(height: 12),
          ResultPanel(child: Text(_status!, style: bodyText())),
        ],
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: bodyText(color: AppColors.neonOrange)),
        ],
      ],
    );
  }

  Duration _portion(Duration duration, double ratio) {
    return Duration(milliseconds: (duration.inMilliseconds * ratio).round());
  }

  String _clock(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
