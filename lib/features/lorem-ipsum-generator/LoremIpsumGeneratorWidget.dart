import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/history/saveResult.dart';
import '../../core/registry/featureModule.dart';
import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';
import '../../shared/widgets/FeatureFrame.dart';
import '../../shared/widgets/InputBox.dart';
import '../../shared/widgets/Panels.dart';
import 'loremIpsumGeneratorService.dart';

class LoremIpsumGeneratorWidget extends StatefulWidget {
  const LoremIpsumGeneratorWidget({super.key, required this.module});

  final FeatureModule module;

  @override
  State<LoremIpsumGeneratorWidget> createState() =>
      _LoremIpsumGeneratorWidgetState();
}

class _LoremIpsumGeneratorWidgetState extends State<LoremIpsumGeneratorWidget> {
  final _seed = TextEditingController();
  double _length = 150;
  String _text = generateLorem(150);

  @override
  void dispose() {
    _seed.dispose();
    super.dispose();
  }

  void _rebuild(double length) {
    setState(() {
      _length = length;
      _text = generateLorem(length.round(), seed: _seed.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FeatureFrame(
      module: widget.module,
      children: [
        InputBox(
          label: '섞을 단어',
          hint: '비워 두면 기본 Lorem Ipsum',
          controller: _seed,
          maxLines: 2,
          enableVoice: true,
          onChanged: (_) => _rebuild(_length),
        ),
        const SizedBox(height: 12),
        Text('${_length.round()}자', style: orbitron(16, color: AppColors.navy)),
        Slider(
          min: 10,
          max: 5000,
          divisions: 499,
          value: _length,
          label: '${_length.round()}',
          onChanged: _rebuild,
        ),
        const SizedBox(height: 8),
        ResultPanel(
          title: '생성된 문장',
          child: SelectableText(_text, style: bodyText()),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: [
            OutlinedButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _text));
                if (!context.mounted) return;
                showAppMessage(context, '문장을 복사했습니다.');
              },
              child: const Text('복사'),
            ),
            FilledButton(
              onPressed: () => saveResult(
                context,
                featureType: widget.module.featureType,
                title: 'Lorem ${_length.round()}자',
                preview: _text,
                input: {'length': _length.round(), 'seed': _seed.text.trim()},
                output: {'text': _text, 'length': _text.length},
              ),
              child: const Text('기록에 저장'),
            ),
          ],
        ),
      ],
    );
  }
}
