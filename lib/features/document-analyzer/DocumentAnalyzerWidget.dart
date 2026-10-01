import 'package:flutter/material.dart';

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
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _analyze(List<PickedUpload> files) {
    if (files.isEmpty) return;
    final file = files.last;
    try {
      final analysis = analyzeDocument(file.bytes, file.name);
      _label.text = file.name;
      setState(() {
        _analysis = analysis;
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
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
