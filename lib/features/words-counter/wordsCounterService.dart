import 'dart:convert';

class WordsCount {
  const WordsCount({
    required this.characters,
    required this.charactersNoWhitespace,
    required this.words,
    required this.lines,
    required this.spaces,
    required this.utf8Bytes,
    required this.hangul2Bytes,
  });

  final int characters;
  final int charactersNoWhitespace;
  final int words;
  final int lines;
  final int spaces;
  final int utf8Bytes;
  final int hangul2Bytes;
}

WordsCount countWords(String text) {
  final runes = text.runes.toList();
  final characters = runes.length;
  final spaces = runes.where(_isWhitespace).length;
  final trimmed = text.trim();
  return WordsCount(
    characters: characters,
    charactersNoWhitespace: characters - spaces,
    words: trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length,
    lines: text.isEmpty ? 0 : text.split('\n').length,
    spaces: spaces,
    utf8Bytes: utf8.encode(text).length,
    hangul2Bytes: _hangul2Bytes(runes),
  );
}

int _hangul2Bytes(List<int> runes) {
  var total = 0;
  for (final rune in runes) {
    final ascii = rune <= 0x7F;
    total += ascii ? 1 : 2;
  }
  return total;
}

bool _isWhitespace(int rune) => String.fromCharCodes([rune]).trim().isEmpty;
