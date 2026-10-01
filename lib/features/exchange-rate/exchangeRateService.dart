import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/appSecrets.dart';

class ExchangeQuote {
  const ExchangeQuote({
    required this.from,
    required this.to,
    required this.rate,
    required this.amount,
  });

  final String from;
  final String to;
  final double rate;
  final double amount;

  double get converted => amount * rate;

  String get summary =>
      '${_money(amount)} $from = ${_money(converted)} $to (1 $from = ${_money(rate)} $to)';
}

Future<ExchangeQuote> fetchExchange({
  required String from,
  required String to,
  required double amount,
}) async {
  final base = _code(from);
  final target = _code(to);
  if (amount <= 0) {
    throw const FormatException('금액은 0보다 커야 합니다.');
  }
  if (!AppSecrets.hasExchangeRate) {
    throw const FormatException('EXCHANGE_RATE_API_KEY가 설정되지 않았습니다.');
  }
  final uri = Uri.parse(
    'https://v6.exchangerate-api.com/v6/${AppSecrets.exchangeRateApiKey}/pair/$base/$target',
  );
  final response = await http.get(uri);
  if (response.statusCode != 200) {
    throw FormatException('환율 조회에 실패했습니다 (${response.statusCode}).');
  }
  final quote = parseExchange(jsonDecode(response.body));
  return ExchangeQuote(
    from: quote.from,
    to: quote.to,
    rate: quote.rate,
    amount: amount,
  );
}

ExchangeQuote parseExchange(Object? json) {
  if (json is! Map || json['result'] != 'success') {
    throw const FormatException('환율 응답을 읽지 못했습니다. 통화 코드를 확인해 주세요.');
  }
  final rate = json['conversion_rate'];
  final from = json['base_code'];
  final to = json['target_code'];
  if (rate is! num || from is! String || to is! String) {
    throw const FormatException('환율 응답을 읽지 못했습니다.');
  }
  return ExchangeQuote(from: from, to: to, rate: rate.toDouble(), amount: 1);
}

String _code(String value) {
  final code = value.trim().toUpperCase();
  if (!RegExp(r'^[A-Z]{3}$').hasMatch(code)) {
    throw const FormatException('통화 코드는 USD, KRW처럼 영문 3글자입니다.');
  }
  return code;
}

String _money(double value) {
  if (value >= 100) return value.toStringAsFixed(2);
  if (value >= 1) return value.toStringAsFixed(4);
  return value.toStringAsFixed(6);
}
