import 'dart:typed_data';

import '../../core/documents/documentExtractor.dart';
import '../words-counter/wordsCounterService.dart';

class DocumentAnalysis {
  const DocumentAnalysis({
    required this.filename,
    required this.counts,
    required this.images,
    required this.bytes,
    this.note,
    this.preview = '',
  });

  final String filename;
  final WordsCount counts;
  final int images;
  final int bytes;
  final String? note;
  final String preview;
}

DocumentAnalysis analyzeDocument(Uint8List bytes, String filename) {
  final extracted = extractDocument(bytes, filename);
  final counts = countWords(extracted.text);
  final preview = extracted.text.trim();
  return DocumentAnalysis(
    filename: filename,
    counts: counts,
    images: extracted.images,
    bytes: extracted.bytes,
    note: extracted.note,
    preview: preview.length > 280 ? '${preview.substring(0, 280)}…' : preview,
  );
}
