import 'package:flutter/material.dart';

import '../../core/config/appSecrets.dart';
import '../../core/history/saveResult.dart';
import '../../core/registry/featureModule.dart';
import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';
import '../../shared/widgets/FeatureFrame.dart';
import '../../shared/widgets/InputBox.dart';
import '../../shared/widgets/Panels.dart';
import 'weatherService.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key, required this.module});

  final FeatureModule module;

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  static const _presets = [
    'Seoul',
    'Busan',
    'Yokohama',
    'Tokyo',
    'Singapore',
    'Kuala Lumpur',
  ];

  final _city = TextEditingController(text: 'Seoul');
  final _extra = <String>[];
  WeatherReport? _report;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final report = await fetchWeather(_city.text);
      if (!mounted) return;
      setState(() => _report = report);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '날씨 서버에 연결하지 못했습니다.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addCity() async {
    final controller = TextEditingController();
    final city = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('도시 추가'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Osaka'),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    final name = city?.trim() ?? '';
    if (!mounted || name.isEmpty || _extra.length >= 4) return;
    if (_presets.contains(name) || _extra.contains(name)) {
      setState(() => _error = '이미 있는 도시입니다.');
      return;
    }
    setState(() {
      _extra.add(name);
      _city.text = name;
      _error = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return FeatureFrame(
      module: widget.module,
      children: [
        InputBox(
          label: '도시',
          hint: 'Seoul',
          controller: _city,
          maxLines: 1,
          enableVoice: true,
        ),
        const SizedBox(height: 8),
        NoteText(
          AppSecrets.hasOpenWeather
              ? 'OpenWeather에서 현재 날씨를 가져옵니다.'
              : 'OPENWEATHER_API_KEY가 없어 조회할 수 없습니다.',
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final city in _presets) ...[
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () {
                          _city.text = city;
                          _load();
                        },
                  child: Text(city),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilledButton(
                onPressed: _busy || _extra.length >= 4 ? null : _addCity,
                child: const Text('도시 추가'),
              ),
              for (final city in _extra) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () {
                          _city.text = city;
                          _load();
                        },
                  child: Text(city),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: [
            FilledButton(
              onPressed: _busy ? null : _load,
              child: Text(_busy ? '조회 중' : '현재 날씨'),
            ),
            if (report != null)
              OutlinedButton(
                onPressed: () => saveResult(
                  context,
                  featureType: widget.module.featureType,
                  title: report.city,
                  preview: report.summary,
                  input: {'city': _city.text.trim()},
                  output: {
                    'city': report.city,
                    'description': report.description,
                    'tempC': report.tempC,
                    'humidity': report.humidity,
                    'text': report.summary,
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
        if (report != null) ...[
          const SizedBox(height: 16),
          ResultPanel(
            title: report.city,
            child: SelectableText(report.summary, style: bodyText(size: 16)),
          ),
        ],
      ],
    );
  }
}
