import '../../core/api/geminiClient.dart';
import '../../core/config/appSecrets.dart';

class SummaryResult {
  const SummaryResult({
    required this.summary,
    required this.sentenceCount,
    required this.selectedCount,
    this.engine = 'TextRank',
    this.notice,
  });

  final String summary;
  final int sentenceCount;
  final int selectedCount;
  final String engine;
  final String? notice;
}

Future<SummaryResult> summarizeDocument(String text, double ratio) async {
  if (!AppSecrets.hasGemini) {
    return summarizeText(text, ratio);
  }
  try {
    final summary = await GeminiClient().summarize(text, ratio);
    final sentences = _sentences(text.trim());
    final selected = summary
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .length;
    return SummaryResult(
      summary: summary,
      sentenceCount: sentences.isEmpty ? 1 : sentences.length,
      selectedCount: selected == 0 ? 1 : selected,
      engine: 'Gemini',
    );
  } on FormatException catch (error) {
    final local = summarizeText(text, ratio);
    return SummaryResult(
      summary: local.summary,
      sentenceCount: local.sentenceCount,
      selectedCount: local.selectedCount,
      notice: '${error.message} TextRank로 대신 요약했습니다.',
    );
  } catch (_) {
    final local = summarizeText(text, ratio);
    return SummaryResult(
      summary: local.summary,
      sentenceCount: local.sentenceCount,
      selectedCount: local.selectedCount,
      notice: 'Gemini에 연결하지 못해 TextRank로 대신 요약했습니다.',
    );
  }
}

SummaryResult summarizeText(String text, double ratio) {
  final source = text.trim();
  if (source.isEmpty) {
    throw const FormatException('요약할 텍스트를 입력하거나 파일을 올려 주세요.');
  }
  final clamped = ratio.clamp(0.1, 1.0);
  final sentences = _sentences(source);
  if (sentences.length <= 1) {
    return SummaryResult(
      summary: source,
      sentenceCount: sentences.length,
      selectedCount: sentences.length,
    );
  }
  final keep = (sentences.length * clamped).ceil().clamp(1, sentences.length);
  final scores = _rank(sentences);
  final selected = scores.asMap().entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final indexes = selected.take(keep).map((entry) => entry.key).toList()
    ..sort();
  return SummaryResult(
    summary: indexes.map((index) => sentences[index]).join('\n'),
    sentenceCount: sentences.length,
    selectedCount: keep,
  );
}

List<String> _sentences(String text) {
  return text
      .replaceAll('\r', '\n')
      .split(RegExp(r'(?<=[\.!?。！？])\s+|\n+'))
      .map((sentence) => sentence.trim())
      .where((sentence) => sentence.isNotEmpty)
      .toList();
}

List<double> _rank(List<String> sentences) {
  final tokens = sentences.map(_tokens).toList();
  final count = sentences.length;
  final similarity = List.generate(count, (_) => List.filled(count, 0.0));
  final weight = List.filled(count, 0.0);
  for (var i = 0; i < count; i++) {
    for (var j = i + 1; j < count; j++) {
      final score = _jaccard(tokens[i], tokens[j]);
      similarity[i][j] = score;
      similarity[j][i] = score;
      weight[i] += score;
      weight[j] += score;
    }
  }
  if (weight.every((value) => value == 0)) {
    return List.filled(count, 1);
  }
  var scores = List.filled(count, 1 / count);
  const damping = 0.85;
  for (var iteration = 0; iteration < 24; iteration++) {
    final next = List.filled(count, (1 - damping) / count);
    for (var i = 0; i < count; i++) {
      for (var j = 0; j < count; j++) {
        if (weight[j] == 0 || similarity[j][i] == 0) continue;
        next[i] += damping * scores[j] * similarity[j][i] / weight[j];
      }
    }
    scores = next;
  }
  return scores;
}

Set<String> _tokens(String sentence) {
  return sentence
      .toLowerCase()
      .split(RegExp(r'[^0-9a-zA-Z가-힣]+'))
      .where((token) => token.length > 1)
      .toSet();
}

double _jaccard(Set<String> left, Set<String> right) {
  if (left.isEmpty || right.isEmpty) return 0;
  final intersection = left.intersection(right).length;
  final union = left.union(right).length;
  return union == 0 ? 0 : intersection / union;
}
