import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/appSecrets.dart';

class GeminiClient {
  static const _model = 'gemini-3.8-flash';

  Future<String> summarize(String text, double ratio) {
    final percent = (ratio.clamp(0.1, 1.0) * 100).round();
    final source = _clip(text);
    return _generate(
      '다음 글을 한국어로 요약해 주세요. 분량은 원문의 약 $percent%로 맞추고, 사실만 남기세요.\n\n$source',
    );
  }

  Future<String> analyze(String text) {
    return _generate(
      '다음 글을 한국어로 짧게 분석해 주세요. 주제, 문체, 핵심을 각각 한 줄로 쓰세요.\n\n${_clip(text)}',
    );
  }

  Future<String> _generate(String prompt) async {
    if (!AppSecrets.hasGemini) {
      throw const FormatException('GEMINI_API_KEY가 설정되지 않았습니다.');
    }
    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent',
      ),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': AppSecrets.geminiApiKey,
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      }),
    );
    if (response.statusCode != 200) {
      throw FormatException(_errorMessage(response.statusCode, response.body));
    }
    return extractGeminiText(jsonDecode(response.body));
  }

  String _clip(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 12000) return trimmed;
    return trimmed.substring(0, 12000);
  }
}

String extractGeminiText(Object? json) {
  if (json is! Map) {
    throw const FormatException('Gemini 응답을 읽지 못했습니다.');
  }
  final candidates = json['candidates'];
  if (candidates is! List || candidates.isEmpty) {
    throw const FormatException('Gemini가 문장을 돌려주지 않았습니다.');
  }
  final first = candidates.first;
  if (first is! Map) {
    throw const FormatException('Gemini 응답을 읽지 못했습니다.');
  }
  final content = first['content'];
  final parts = content is Map ? content['parts'] : null;
  final buffer = StringBuffer();
  if (parts is List) {
    for (final part in parts) {
      if (part is! Map || part['thought'] == true) continue;
      final text = part['text'];
      if (text is String && text.trim().isNotEmpty) {
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(text.trim());
      }
    }
  }
  final result = buffer.toString().trim();
  if (result.isEmpty) {
    throw const FormatException('Gemini 응답이 비어 있습니다.');
  }
  return result;
}

String _errorMessage(int code, String body) {
  try {
    final json = jsonDecode(body);
    if (json is Map && json['error'] is Map) {
      final message = (json['error'] as Map)['message'];
      if (message is String && message.isNotEmpty) {
        final brief = message.split('.').first.trim();
        return 'Gemini 오류 ($code): $brief';
      }
    }
  } catch (_) {}
  return 'Gemini 오류 ($code)';
}
