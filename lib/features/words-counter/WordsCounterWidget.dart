import 'package:flutter/material.dart';

import '../../core/history/saveResult.dart';
import '../../core/registry/featureModule.dart';
import '../../core/theme/appColors.dart';
import '../../shared/widgets/FeatureFrame.dart';
import '../../shared/widgets/InputBox.dart';
import '../../shared/widgets/Panels.dart';
import 'wordsCounterService.dart';

class WordsCounterWidget extends StatefulWidget {
  const WordsCounterWidget({super.key, required this.module});

  final FeatureModule module;

  @override
  State<WordsCounterWidget> createState() => _WordsCounterWidgetState();
}

class _WordsCounterWidgetState extends State<WordsCounterWidget> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counts = countWords(_text.text);
    return FeatureFrame(
      module: widget.module,
      children: [
        InputBox(
          label: '텍스트',
          hint: '글자를 입력하거나 음성으로 받아적으세요.',
          controller: _text,
          enableVoice: true,
          maxLines: 8,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            _text.text = '안녕, Play & Learn. 한글은 2바이트로 셉니다.';
            setState(() {});
          },
          child: const Text('예시 문장'),
        ),
        const SizedBox(height: 8),
        const NoteText('한글과 그 외 비ASCII 문자는 2바이트, ASCII는 1바이트로 계산합니다.'),
        const SizedBox(height: 14),
        _Stats(counts: counts),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: _text.text.isEmpty
              ? null
              : () => saveResult(
                  context,
                  featureType: widget.module.featureType,
                  title: '글자 ${counts.characters}',
                  preview:
                      '글자 ${counts.characters} · 단어 ${counts.words} · 한글 2바이트 ${counts.hangul2Bytes}',
                  input: {'text': _text.text},
                  output: {
                    'characters': counts.characters,
                    'words': counts.words,
                    'spaces': counts.spaces,
                    'utf8Bytes': counts.utf8Bytes,
                    'hangul2Bytes': counts.hangul2Bytes,
                  },
                ),
          child: const Text('기록에 저장'),
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.counts});

  final WordsCount counts;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ('글자', '${counts.characters}', AppColors.blue),
      ('공백 제외', '${counts.charactersNoWhitespace}', AppColors.blueBright),
      ('단어', '${counts.words}', AppColors.neonPurple),
      ('줄', '${counts.lines}', AppColors.navy),
      ('공백', '${counts.spaces}', AppColors.muted),
      ('UTF-8', '${counts.utf8Bytes}', AppColors.aqua),
      ('한글 2바이트', '${counts.hangul2Bytes}', AppColors.neonOrange),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 720
            ? 4
            : constraints.maxWidth > 460
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
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
                  accent: tile.$3,
                ),
              ),
          ],
        );
      },
    );
  }
}
