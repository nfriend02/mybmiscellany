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
  bool _busy = false;

  static const _sample =
      '서울의 아침 공기는 차가웠다. 김다온은 9시 회의 전에 보고서를 다시 읽었다. '
      '보고서에는 지난달 방문자가 12퍼센트 늘었다고 적혀 있었다. '
      '다만 모바일에서 이탈이 커서 첫 화면을 단순하게 바꾸자는 제안이 붙었다. '
      '팀은 목요일까지 시안 두 개를 비교하기로 했다.';

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

  Future<void> _summarize() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final summary = await summarizeDocument(_text.text, _ratio);
      if (!mounted) return;
      setState(() => _summary = summary);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
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
        const NoteText('Gemini가 연결되어 있으면 그 모델로 요약하고, 실패하면 TextRank로 대신합니다.'),
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
            FilledButton(
              onPressed: _busy ? null : _summarize,
              child: Text(_busy ? '요약 중' : '요약하기'),
            ),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () {
                      _text.text = _sample;
                      _summarize();
                    },
              child: const Text('예시로 요약'),
            ),
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
          if (summary.notice != null) ...[
            NoteText(summary.notice!),
            const SizedBox(height: 8),
          ],
          ResultPanel(
            title:
                '${summary.engine} 요약 ${summary.selectedCount} / ${summary.sentenceCount}',
            child: SelectableText(summary.summary, style: bodyText()),
          ),
        ],
      ],
    );
  }
}
