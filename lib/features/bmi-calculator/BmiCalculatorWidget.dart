import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/history/saveResult.dart';
import '../../core/registry/featureModule.dart';
import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';
import '../../shared/widgets/FeatureFrame.dart';
import '../../shared/widgets/InputBox.dart';
import '../../shared/widgets/Panels.dart';
import 'bmiCalculatorService.dart';

class BmiCalculatorWidget extends StatefulWidget {
  const BmiCalculatorWidget({super.key, required this.module});

  final FeatureModule module;

  @override
  State<BmiCalculatorWidget> createState() => _BmiCalculatorWidgetState();
}

class _BmiCalculatorWidgetState extends State<BmiCalculatorWidget> {
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _age = TextEditingController();
  BmiGender _gender = BmiGender.male;
  BmiResult? _result;
  String? _error;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _age.dispose();
    super.dispose();
  }

  void _calculate() {
    final height = double.tryParse(_height.text.trim());
    final weight = double.tryParse(_weight.text.trim());
    final age = int.tryParse(_age.text.trim());
    if (height == null || weight == null || age == null) {
      setState(() => _error = '키, 몸무게, 나이를 숫자로 입력해 주세요.');
      return;
    }
    try {
      setState(() {
        _result = calculateBmi(
          heightCm: height,
          weightKg: weight,
          gender: _gender,
          age: age,
        );
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return FeatureFrame(
      module: widget.module,
      children: [
        InputBox(
          label: '키 (cm)',
          hint: '170',
          controller: _height,
          maxLines: 1,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
        ),
        const SizedBox(height: 12),
        InputBox(
          label: '몸무게 (kg)',
          hint: '65',
          controller: _weight,
          maxLines: 1,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
        ),
        const SizedBox(height: 12),
        InputBox(
          label: '나이',
          hint: '30',
          controller: _age,
          maxLines: 1,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),
        SegmentedButton<BmiGender>(
          segments: const [
            ButtonSegment(value: BmiGender.male, label: Text('남')),
            ButtonSegment(value: BmiGender.female, label: Text('여')),
            ButtonSegment(value: BmiGender.other, label: Text('기타')),
          ],
          selected: {_gender},
          onSelectionChanged: (value) => setState(() => _gender = value.first),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton(onPressed: _calculate, child: const Text('BMI 계산')),
            OutlinedButton(
              onPressed: () {
                _height.text = '170';
                _weight.text = '65';
                _age.text = '30';
                setState(() => _gender = BmiGender.male);
                _calculate();
              },
              child: const Text('예시 170/65'),
            ),
            if (result != null)
              OutlinedButton(
                onPressed: () => saveResult(
                  context,
                  featureType: widget.module.featureType,
                  title: 'BMI ${result.bmi.toStringAsFixed(1)}',
                  preview: result.guidance,
                  input: {
                    'heightCm': double.parse(_height.text.trim()),
                    'weightKg': double.parse(_weight.text.trim()),
                    'gender': genderLabel(_gender),
                    'age': int.parse(_age.text.trim()),
                  },
                  output: {
                    'bmi': double.parse(result.bmi.toStringAsFixed(1)),
                    'category': result.category,
                    'ageBand': result.ageBand,
                    'targetKg': double.parse(
                      result.targetKg.toStringAsFixed(1),
                    ),
                    'text': result.guidance,
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
        if (result != null) ...[
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 640 ? 3 : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: width,
                    child: StatTile(
                      label: 'BMI',
                      value: result.bmi.toStringAsFixed(1),
                      accent: AppColors.blue,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: StatTile(
                      label: result.ageBand,
                      value: result.category,
                      accent: AppColors.neonPurple,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: StatTile(
                      label: '목표 체중',
                      value: '${result.targetKg.toStringAsFixed(1)}kg',
                      accent: AppColors.neonOrange,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          ResultPanel(
            title: '안내',
            child: SelectableText(result.guidance, style: bodyText()),
          ),
        ],
      ],
    );
  }
}
