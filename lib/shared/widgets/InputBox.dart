import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/history/saveResult.dart';
import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';
import '../files/pickUploads.dart';

class PickedUpload {
  const PickedUpload({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class InputBox extends StatefulWidget {
  const InputBox({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.maxLines = 4,
    this.keyboardType,
    this.inputFormatters,
    this.enableVoice = false,
    this.enableFile = false,
    this.allowMultiple = false,
    this.allowedExtensions,
    this.fileType = FileType.any,
    this.onChanged,
    this.onFiles,
    this.files,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enableVoice;
  final bool enableFile;
  final bool allowMultiple;
  final List<String>? allowedExtensions;
  final FileType fileType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<List<PickedUpload>>? onFiles;
  final List<PickedUpload>? files;

  @override
  State<InputBox> createState() => _InputBoxState();
}

class _InputBoxState extends State<InputBox> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  final SpeechToText _speech = SpeechToText();
  bool _listening = false;
  List<PickedUpload> _localFiles = [];

  List<PickedUpload> get _files => widget.files ?? _localFiles;

  void _setFiles(List<PickedUpload> next) {
    if (widget.files == null) {
      setState(() => _localFiles = next);
    }
    widget.onFiles?.call(next);
  }

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_handleText);
  }

  void _handleText() {
    widget.onChanged?.call(_controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleText);
    if (_listening) {
      _speech.stop();
    }
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final ready = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
    );
    if (!mounted) return;
    if (!ready) {
      showAppMessage(context, '이 브라우저에서는 음성 입력을 사용할 수 없습니다.');
      return;
    }
    final base = _controller.text.trim();
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        final spoken = result.recognizedWords.trim();
        _controller.text = [
          base,
          spoken,
        ].where((part) => part.isNotEmpty).join(' ');
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
      },
      listenOptions: SpeechListenOptions(
        localeId: 'ko_KR',
        listenMode: ListenMode.dictation,
        partialResults: true,
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final uploads = await pickUploads(
        allowMultiple: widget.allowMultiple,
        extensions: widget.allowedExtensions,
        audio: widget.fileType == FileType.audio,
      );
      if (!mounted || uploads.isEmpty) return;
      final picked = [
        for (final file in uploads)
          PickedUpload(name: file.name, bytes: file.bytes),
      ];
      _setFiles(widget.allowMultiple ? [..._files, ...picked] : picked);
    } on FormatException catch (error) {
      if (mounted) showAppMessage(context, error.message);
    } catch (_) {
      if (mounted) showAppMessage(context, '파일을 열지 못했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: labelText(color: AppColors.ink)),
          const SizedBox(height: 8),
        ],
        if (widget.enableVoice || widget.enableFile)
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.enableVoice)
                  IconButton(
                    tooltip: _listening ? '음성 입력 중지' : '음성 입력',
                    onPressed: _toggleVoice,
                    icon: Icon(
                      _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: _listening ? AppColors.neonOrange : AppColors.blue,
                    ),
                  ),
                if (widget.enableFile)
                  IconButton(
                    tooltip: '파일 업로드',
                    onPressed: _pickFiles,
                    icon: const Icon(
                      Icons.upload_file_rounded,
                      color: AppColors.blue,
                    ),
                  ),
              ],
            ),
          ),
        TextField(
          controller: _controller,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          decoration: InputDecoration(hintText: widget.hint),
        ),
        if (_files.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final file in _files)
                Chip(
                  label: Text(
                    file.name,
                    style: labelText(size: 12, color: AppColors.ink),
                  ),
                  onDeleted: () =>
                      _setFiles(_files.where((item) => item != file).toList()),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
