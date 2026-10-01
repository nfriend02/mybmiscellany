import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/api/geminiClient.dart';
import '../../core/config/appSecrets.dart';
import '../../core/history/saveResult.dart';
import '../../core/registry/featureModule.dart';
import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';
import '../../shared/widgets/FeatureFrame.dart';
import '../../shared/widgets/InputBox.dart';
import '../../shared/widgets/Panels.dart';
import 'documentAnalyzerService.dart';

class DocumentAnalyzerWidget extends StatefulWidget {
  const DocumentAnalyzerWidget({super.key, required this.module});

  final FeatureModule module;

  @override
  State<DocumentAnalyzerWidget> createState() => _DocumentAnalyzerWidgetState();
}

class _DocumentAnalyzerWidgetState extends State<DocumentAnalyzerWidget> {
  final _label = TextEditingController();
  DocumentAnalysis? _analysis;
  String? _insight;
  String? _error;
  bool _busy = false;

  static const _sample =
      '서울의 아침 공기는 차가웠다. 김다온은 9시 회의 전에 보고서를 다시 읽었다. '
      '지난달 방문자는 12퍼센트 늘었고, 모바일 이탈이 커서 첫 화면을 단순하게 바꾸자는 제안이 붙었다.';

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _analyze(List<PickedUpload> files) async {
    if (files.isEmpty) return;
    final file = files.last;
    late DocumentAnalysis analysis;
    try {
      analysis = analyzeDocument(file.bytes, file.name);
    } on FormatException catch (error) {
      setState(() => _error = error.message);
      return;
    }
    _label.text = file.name;
    setState(() {
      _analysis = analysis;
      _insight = null;
      _error = null;
      _busy = true;
    });
    if (!AppSecrets.hasGemini || analysis.body.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _insight = AppSecrets.hasGemini
              ? '본문이 비어 통계만 표시합니다.'
              : '로컬 통계만 계산했습니다. Gemini 키가 있으면 주제와 문체를 덧붙입니다.';
          _busy = false;
        });
      }
      return;
    }
    try {
      final insight = await GeminiClient().analyze(analysis.body);
      if (!mounted) return;
      setState(() => _insight = insight);
    } on FormatException catch (error) {
      if (mounted) setState(() => _insight = error.message);
    } catch (_) {
      if (mounted) setState(() => _insight = 'Gemini에 연결하지 못해 통계만 표시합니다.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _loadSample() {
    _analyze([
      PickedUpload(
        name: 'sample.txt',
        bytes: Uint8List.fromList(utf8.encode(_sample)),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final analysis = _analysis;
    return FeatureFrame(
      module: widget.module,
      children: [
        InputBox(
          label: '문서 파일',
          hint: 'PDF, DOC, DOCX, TXT',
          controller: _label,
          maxLines: 1,
          enableFile: true,
          allowedExtensions: const ['pdf', 'doc', 'docx', 'txt', 'md'],
          onFiles: _analyze,
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _busy ? null : _loadSample,
          child: Text(_busy ? '분석 중' : '예시 문서로 분석'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: bodyText(color: AppColors.neonOrange)),
        ],
        if (analysis != null) ...[
          const SizedBox(height: 16),
          if (analysis.note != null) ...[
            NoteText(analysis.note!),
            const SizedBox(height: 10),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final tiles = [
                ('글자', '${analysis.counts.characters}'),
                ('단어', '${analysis.counts.words}'),
                ('공백', '${analysis.counts.spaces}'),
                ('이미지', '${analysis.images}'),
                ('줄', '${analysis.counts.lines}'),
                ('파일', '${(analysis.bytes / 1024).toStringAsFixed(1)}KB'),
              ];
              final columns = constraints.maxWidth > 720 ? 3 : 2;
              final width =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final tile in tiles)
                    SizedBox(
                      width: width,
                      child: StatTile(
                        label: tile.$1,
                        value: tile.$2,
                        accent: AppColors.blue,
                      ),
                    ),
                ],
              );
            },
          ),
          if (_insight != null) ...[
            const SizedBox(height: 12),
            ResultPanel(
              title: '분석 메모',
              child: SelectableText(_insight!, style: bodyText()),
            ),
          ],
          if (analysis.preview.isNotEmpty) ...[
            const SizedBox(height: 12),
            ResultPanel(
              title: '앞부분',
              child: SelectableText(analysis.preview, style: bodyText()),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => saveResult(
              context,
              featureType: widget.module.featureType,
              title: analysis.filename,
              preview:
                  '글자 ${analysis.counts.characters}, 단어 ${analysis.counts.words}, 공백 ${analysis.counts.spaces}, 이미지 ${analysis.images}',
              input: {'filename': analysis.filename, 'bytes': analysis.bytes},
              output: {
                'characters': analysis.counts.characters,
                'words': analysis.counts.words,
                'spaces': analysis.counts.spaces,
                'images': analysis.images,
                'lines': analysis.counts.lines,
              },
            ),
            child: const Text('기록에 저장'),
          ),
        ],
      ],
    );
  }
}
