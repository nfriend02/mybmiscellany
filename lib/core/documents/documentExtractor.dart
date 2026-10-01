import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ExtractedDocument {
  const ExtractedDocument({
    required this.text,
    required this.images,
    required this.bytes,
    this.note,
  });

  final String text;
  final int images;
  final int bytes;
  final String? note;
}

ExtractedDocument extractDocument(Uint8List bytes, String filename) {
  if (bytes.isEmpty) {
    throw const FormatException('빈 파일입니다.');
  }
  final extension = filename.contains('.')
      ? filename.split('.').last.toLowerCase()
      : '';
  switch (extension) {
    case 'txt':
    case 'md':
    case 'csv':
    case 'json':
      return ExtractedDocument(
        text: utf8.decode(bytes, allowMalformed: true),
        images: 0,
        bytes: bytes.length,
      );
    case 'docx':
      return _extractDocx(bytes);
    case 'pdf':
      return _extractPdf(bytes);
    case 'doc':
      return ExtractedDocument(
        text: _extractLegacyDoc(bytes),
        images: 0,
        bytes: bytes.length,
        note: '구형 DOC는 보이는 문자열만 대략 추출합니다. DOCX 또는 PDF를 권장합니다.',
      );
    default:
      throw FormatException('지원하지 않는 형식입니다: .$extension');
  }
}

ExtractedDocument _extractPdf(Uint8List bytes) {
  String text = '';
  String? note;
  try {
    final document = PdfDocument(inputBytes: bytes);
    try {
      text = PdfTextExtractor(document).extractText();
    } finally {
      document.dispose();
    }
  } catch (_) {
    note = 'PDF 텍스트를 읽지 못했습니다. 암호가 걸려 있거나 스캔본일 수 있습니다.';
  }
  if (text.trim().isEmpty && note == null) {
    note = '추출된 텍스트가 없습니다. 이미지로만 구성된 PDF일 수 있습니다.';
  }
  return ExtractedDocument(
    text: text,
    images: countPdfImageMarkers(bytes),
    bytes: bytes.length,
    note: note,
  );
}

int countPdfImageMarkers(Uint8List bytes) {
  final latin = latin1.decode(bytes, allowInvalid: true);
  return RegExp(r'/Subtype\s*/Image').allMatches(latin).length;
}

ExtractedDocument _extractDocx(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  ArchiveFile? documentXml;
  var images = 0;
  for (final file in archive) {
    final name = file.name.replaceAll('\\', '/');
    if (name == 'word/document.xml') documentXml = file;
    if (name.startsWith('word/media/') && file.isFile && !name.endsWith('/')) {
      images++;
    }
  }
  if (documentXml == null) {
    throw const FormatException('DOCX에서 document.xml을 찾지 못했습니다.');
  }
  final xml = utf8.decode(documentXml.content, allowMalformed: true);
  return ExtractedDocument(
    text: _docxParagraphs(xml),
    images: images,
    bytes: bytes.length,
  );
}

String _docxParagraphs(String xml) {
  final buffer = StringBuffer();
  final textPattern = RegExp(r'<w:t[^>]*>(.*?)</w:t>');
  for (final paragraph in xml.split(RegExp(r'</w:p>'))) {
    final parts = textPattern
        .allMatches(paragraph)
        .map((match) => _unescapeXml(match.group(1)!))
        .toList();
    if (parts.isEmpty) continue;
    buffer.writeln(parts.join());
  }
  return buffer.toString().trim();
}

String _unescapeXml(String value) {
  return value
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");
}

String _extractLegacyDoc(Uint8List bytes) {
  final buffer = StringBuffer();
  final current = StringBuffer();
  for (final byte in bytes) {
    final printable = byte >= 32 && byte < 127;
    if (printable) {
      current.writeCharCode(byte);
    } else if (current.length >= 4) {
      buffer.writeln(current);
      current.clear();
    } else {
      current.clear();
    }
  }
  if (current.length >= 4) buffer.writeln(current);
  return buffer.toString().trim();
}
