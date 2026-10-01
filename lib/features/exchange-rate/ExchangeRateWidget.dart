import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/appSecrets.dart';
import '../../core/history/saveResult.dart';
import '../../core/registry/featureModule.dart';
import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';
import '../../shared/widgets/FeatureFrame.dart';
import '../../shared/widgets/InputBox.dart';
import '../../shared/widgets/Panels.dart';
import 'exchangeRateService.dart';

class ExchangeRateWidget extends StatefulWidget {
  const ExchangeRateWidget({super.key, required this.module});

  final FeatureModule module;

  @override
  State<ExchangeRateWidget> createState() => _ExchangeRateWidgetState();
}

class _ExchangeRateWidgetState extends State<ExchangeRateWidget> {
  static const _currencies = [
    'USD',
    'EUR',
    'JPY',
    'GBP',
    'KRW',
    'CNY',
    'SGD',
    'MYR',
    'AUD',
    'CAD',
  ];

  final _amount = TextEditingController(text: '100');
  final _from = TextEditingController(text: 'USD');
  final _to = TextEditingController(text: 'KRW');
  ExchangeQuote? _quote;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null) {
      setState(() => _error = '금액을 숫자로 입력해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final quote = await fetchExchange(
        from: _from.text,
        to: _to.text,
        amount: amount,
      );
      if (!mounted) return;
      setState(() => _quote = quote);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = '환율 서버에 연결하지 못했습니다.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _applyExample(String from, String to) {
    _amount.text = '100';
    _from.text = from;
    _to.text = to;
    _load();
  }

  Widget _exampleButton(String label, String from, String to) {
    return OutlinedButton(
      onPressed: _busy ? null : () => _applyExample(from, to),
      child: Text(label),
    );
  }

  Widget _currencyField(String label, TextEditingController controller) {
    final code = controller.text.trim().toUpperCase();
    final selected = _currencies.contains(code) ? code : 'USD';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: InputBox(
            label: label,
            hint: selected,
            controller: controller,
            maxLines: 1,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: _currencies.contains(code) ? code : null,
          hint: const Text('통화'),
          items: [
            for (final item in _currencies)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: (value) {
            if (value == null) return;
            controller.text = value;
            setState(() {});
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final quote = _quote;
    return FeatureFrame(
      module: widget.module,
      children: [
        InputBox(
          label: '금액',
          hint: '100',
          controller: _amount,
          maxLines: 1,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
        ),
        const SizedBox(height: 12),
        _currencyField('출발 통화', _from),
        const SizedBox(height: 12),
        _currencyField('도착 통화', _to),
        const SizedBox(height: 8),
        NoteText(
          AppSecrets.hasExchangeRate
              ? 'ExchangeRate-API에서 현재 환율을 가져옵니다.'
              : 'EXCHANGE_RATE_API_KEY가 없어 조회할 수 없습니다.',
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilledButton(
                onPressed: _busy ? null : _load,
                child: Text(_busy ? '조회 중' : '환율 조회'),
              ),
              const SizedBox(width: 8),
              _exampleButton('달러-원 예시', 'USD', 'KRW'),
              const SizedBox(width: 8),
              _exampleButton('엔-원 예시', 'JPY', 'KRW'),
              const SizedBox(width: 8),
              _exampleButton('싱가포르달러-원 예시', 'SGD', 'KRW'),
              const SizedBox(width: 8),
              _exampleButton('말레이지아 링깃-원 예시', 'MYR', 'KRW'),
              if (quote != null) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => saveResult(
                    context,
                    featureType: widget.module.featureType,
                    title: '${quote.from} → ${quote.to}',
                    preview: quote.summary,
                    input: {
                      'amount': quote.amount,
                      'from': quote.from,
                      'to': quote.to,
                    },
                    output: {
                      'rate': quote.rate,
                      'converted': quote.converted,
                      'text': quote.summary,
                    },
                  ),
                  child: const Text('기록에 저장'),
                ),
              ],
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: bodyText(color: AppColors.neonOrange)),
        ],
        if (quote != null) ...[
          const SizedBox(height: 16),
          ResultPanel(
            title: '변환 결과',
            child: SelectableText(quote.summary, style: bodyText(size: 16)),
          ),
        ],
      ],
    );
  }
}
