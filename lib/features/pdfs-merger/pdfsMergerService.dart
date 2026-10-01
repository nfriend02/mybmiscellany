import 'dart:typed_data';
import 'dart:ui';

import 'package:syncfusion_flutter_pdf/pdf.dart';

Future<Uint8List> mergePdfs(List<Uint8List> files) async {
  if (files.length < 2) {
    throw const FormatException('PDF를 두 개 이상 선택해 주세요.');
  }
  final merged = PdfDocument();
  merged.pageSettings.margins.all = 0;
  try {
    for (final bytes in files) {
      final source = PdfDocument(inputBytes: bytes);
      try {
        for (var i = 0; i < source.pages.count; i++) {
          final sourcePage = source.pages[i];
          final pageSize = sourcePage.size;
          merged.pageSettings.size = pageSize;
          merged.pageSettings.margins.all = 0;
          final page = merged.pages.add();
          page.graphics.drawPdfTemplate(
            sourcePage.createTemplate(),
            Offset.zero,
            pageSize,
          );
        }
      } finally {
        source.dispose();
      }
    }
    return Uint8List.fromList(await merged.save());
  } finally {
    merged.dispose();
  }
}

Future<Uint8List> buildSamplePdf(String title, String line) async {
  final document = PdfDocument();
  try {
    final page = document.pages.add();
    page.graphics.drawString(
      title,
      PdfStandardFont(PdfFontFamily.helvetica, 18),
      bounds: const Rect.fromLTWH(40, 40, 480, 40),
    );
    page.graphics.drawString(
      line,
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: const Rect.fromLTWH(40, 90, 480, 80),
    );
    return Uint8List.fromList(await document.save());
  } finally {
    document.dispose();
  }
}
