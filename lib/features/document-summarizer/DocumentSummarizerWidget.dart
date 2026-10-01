import 'package:flutter/material.dart';

import '../../core/documents/documentExtractor.dart';
import '../../core/history/saveResult.dart';
import '../../core/registry/featureModule.dart';
import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';
import '../../shared/widgets/FeatureFrame.dart';
import '../../shared/widgets/InputBox.dart';
import '../../shared/widgets/Panels.dart';
import 'documentSummarizerService.dart';

class DocumentSummarizerWidget extends StatefulWidget {
  const DocumentSummarizerWidget({super.key, required this.module});

  final FeatureModule module;

  @override
  State<DocumentSummarizerWidget> createState() =>
      _DocumentSummarizerWidgetState();
}

class _DocumentSummarizerWidgetState extends State<DocumentSummarizerWidget> {
  final _text = TextEditingController();
  double _ratio = 0.35;
  SummaryResult? _summary;
  String? _error;
  String? _note;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _loadFile(List<PickedUpload> files) {
    if (files.isEmpty) return;
    final file = files.last;
    try {
      final extracted = extractDocument(file.bytes, file.name);
      _text.text = extracted.text;
      setState(() {
        _note = extracted.note;
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  void _summarize() {
    try {
      setState(() {
        _summary = summarizeText(_text.text, _ratio);
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    return FeatureFrame(
      module: widget.module,
      children: [
        InputBox(
          label: '문서',
          hint: '텍스트를 붙여 넣거나 PDF, DOCX, TXT를 올리세요.',
          controller: _text,
          enableVoice: true,
          enableFile: true,
          allowedExtensions: const ['pdf', 'doc', 'docx', 'txt', 'md'],
          maxLines: 8,
          onFiles: _loadFile,
        ),
        const SizedBox(height: 8),
        const NoteText('요약은 TextRank로 문장 중요도를 매긴 뒤, 원래 순서를 유지해 고릅니다.'),
        if (_note != null) ...[const SizedBox(height: 8), NoteText(_note!)],
        const SizedBox(height: 8),
        Text(
          '요약 분량 ${(_ratio * 100).round()}%',
          style: orbitron(15, color: AppColors.navy),
        ),
        Slider(
          min: 0.1,
          max: 1,
          divisions: 18,
          value: _ratio,
          label: '${(_ratio * 100).round()}%',
          onChanged: (value) => setState(() => _ratio = value),
        ),
        Wrap(
          spacing: 10,
          children: [
            FilledButton(onPressed: _summarize, child: const Text('요약하기')),
            if (summary != null)
              OutlinedButton(
                onPressed: () => saveResult(
                  context,
                  featureType: widget.module.featureType,
                  title: '요약 ${summary.selectedCount}/${summary.sentenceCount}',
                  preview: summary.summary,
                  input: {'ratio': _ratio, 'characters': _text.text.length},
                  output: {
                    'text': summary.summary,
                    'sentenceCount': summary.sentenceCount,
                    'selectedCount': summary.selectedCount,
                  },
                ),
                child: const Text('기록에 저장'),
              ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: bodyText(color: AppColors.neonOrange)),
        ],
        if (summary != null) ...[
          const SizedBox(height: 16),
          ResultPanel(
            title: '요약 ${summary.selectedCount} / ${summary.sentenceCount}문장',
            child: SelectableText(summary.summary, style: bodyText()),
          ),
        ],
      ],
    );
  }
}
