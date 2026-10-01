import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybmiscellany/core/api/geminiClient.dart';
import 'package:mybmiscellany/core/documents/documentExtractor.dart';
import 'package:mybmiscellany/core/registry/featureRegistry.dart';
import 'package:mybmiscellany/features/exchange-rate/exchangeRateService.dart';
import 'package:mybmiscellany/features/weather/weatherService.dart';
import 'package:mybmiscellany/features/audio-editor/audioEditorService.dart';
import 'package:mybmiscellany/features/audio-editor/mp3Encoder.dart';
import 'package:mybmiscellany/features/bmi-calculator/bmiCalculatorService.dart';
import 'package:mybmiscellany/features/document-summarizer/documentSummarizerService.dart';
import 'package:mybmiscellany/features/lorem-ipsum-generator/loremIpsumGeneratorService.dart';
import 'package:mybmiscellany/features/lucky-canon/luckyCanonService.dart';
import 'package:mybmiscellany/features/out-of-office/outOfOfficeService.dart';
import 'package:mybmiscellany/features/pdfs-merger/pdfsMergerService.dart';
import 'package:mybmiscellany/features/words-counter/wordsCounterService.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('feature routes use the folder featureType', () {
    final pattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
    final types = FeatureRegistry.all
        .map((feature) => feature.featureType)
        .toList();
    expect(types.toSet().length, types.length);
    expect(
      types,
      containsAll([
        'lucky-canon',
        'out-of-office',
        'bmi-calculator',
        'document-summarizer',
        'pdfs-merger',
        'audio-editor',
        'words-counter',
        'document-analyzer',
        'lorem-ipsum-generator',
      ]),
    );
    for (final type in types) {
      expect(pattern.hasMatch(type), isTrue);
      expect(
        FeatureRegistry.all.where((feature) => feature.route == '/$type'),
        hasLength(1),
      );
    }
  });

  test('out of office message includes the return time', () {
    final start = DateTime(2026, 10, 2, 9, 0);
    final message = buildOutOfOffice(
      name: '김다온',
      role: '기획',
      start: start,
      returnAt: start.add(const Duration(days: 2)),
      reason: '워크숍',
      contact: 'team@example.com',
    );
    expect(message.text, contains('김다온'));
    expect(message.text, contains('2026.10.04'));
    expect(
      () => buildOutOfOffice(
        name: '김다온',
        role: '',
        start: start,
        returnAt: start,
        reason: '',
        contact: '',
      ),
      throwsFormatException,
    );
  });

  test('bmi uses height weight and gender for a target weight', () {
    final result = calculateBmi(
      heightCm: 170,
      weightKg: 70,
      gender: BmiGender.male,
      age: 30,
    );
    expect(result.bmi, closeTo(24.22, 0.02));
    expect(result.category, '정상');
    expect(result.targetKg, closeTo(63.58, 0.05));
    expect(result.ageBand, '성인');
  });

  test('older adults use a wider bmi band', () {
    final result = calculateBmi(
      heightCm: 170,
      weightKg: 75,
      gender: BmiGender.male,
      age: 70,
    );
    expect(result.bmi, closeTo(25.95, 0.05));
    expect(result.ageBand, '고령');
    expect(result.category, '정상');
  });

  test('hangul characters count as two bytes', () {
    final count = countWords('A안녕');
    expect(count.characters, 3);
    expect(count.words, 1);
    expect(count.hangul2Bytes, 5);
    expect(count.utf8Bytes, 7);
    expect(countWords('').characters, 0);
  });

  test('lorem length follows the slider bounds', () {
    expect(generateLorem(150).length, 150);
    expect(generateLorem(10).length, 10);
    expect(generateLorem(5000).length, 5000);
    expect(generateLorem(40, seed: '다온'), contains('다온'));
    expect(() => generateLorem(9), throwsFormatException);
  });

  test('text rank keeps the requested share of sentences', () {
    const source = '사과는 빨갛다. 바나나는 노랗다. 포도는 보라색이다. 사과는 달다. 바나나는 부드럽다.';
    final summary = summarizeText(source, 0.4);
    expect(summary.sentenceCount, greaterThan(1));
    expect(summary.selectedCount, lessThan(summary.sentenceCount));
    expect(summary.summary.length, lessThan(source.length));
  });

  test('docx extraction counts words and images', () {
    const xml = '''
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p><w:r><w:t>안녕하세요 문서</w:t></w:r></w:p>
    <w:p><w:r><w:t>두번째 문장입니다.</w:t></w:r></w:p>
  </w:body>
</w:document>
''';
    final xmlBytes = utf8.encode(xml);
    final archive = Archive()
      ..addFile(ArchiveFile('word/document.xml', xmlBytes.length, xmlBytes))
      ..addFile(ArchiveFile('word/media/image1.png', 4, [1, 2, 3, 4]));
    final extracted = extractDocument(
      ZipEncoder().encodeBytes(archive),
      'note.docx',
    );
    expect(extracted.text, contains('안녕하세요 문서'));
    expect(extracted.text, contains('두번째 문장입니다.'));
    expect(extracted.images, 1);
  });

  test('pdf image markers are counted from the file bytes', () {
    final bytes = Uint8List.fromList(
      ascii.encode('<< /Subtype /Image >> << /Subtype/Image >>'),
    );
    expect(countPdfImageMarkers(bytes), 2);
  });

  test('pdf merge keeps every page', () async {
    Future<Uint8List> page(String label) async {
      final document = PdfDocument();
      document.pages.add().graphics.drawString(
        label,
        PdfStandardFont(PdfFontFamily.helvetica, 18),
      );
      final bytes = Uint8List.fromList(await document.save());
      document.dispose();
      return bytes;
    }

    final merged = await mergePdfs([await page('One'), await page('Two')]);
    final check = PdfDocument(inputBytes: merged);
    expect(check.pages.count, 2);
    check.dispose();
  });

  test('wav export applies trim and volume', () {
    final source = buildPcm16Wav(
      sampleRate: 8000,
      channels: 1,
      pcm: Uint8List(8000),
    );
    final edited = editWav(source, volume: 0.5, startRatio: 0, endRatio: 0.5);
    expect(edited.processed, isTrue);
    expect(edited.bytes, isNotNull);
    expect(edited.bytes!.length, lessThan(source.length));
    expect(edited.endSeconds, closeTo(0.25, 0.02));
  });

  test('wav pcm encodes to an mp3 frame', () {
    final wav = buildPcm16Wav(
      sampleRate: 44100,
      channels: 1,
      pcm: Uint8List(1152 * 4),
    );
    final mp3 = encodeWavToMp3(wav);
    expect(mp3.length, greaterThan(32));
    expect(mp3[0], 0xFF);
  });

  test('the last marble to land wins', () {
    final world = createCanonWorld(['가', '나', '다'], duration: 1);
    world.start();
    for (var frame = 0; frame < 60 * 20; frame++) {
      world.step(1 / 60);
      if (world.completed) break;
    }
    expect(world.completed, isTrue);
    expect(world.winner, isNotNull);
    expect(world.ranking.first.name, world.winner!.name);
  });

  test('lucky canon stylesheet defines marble colors', () {
    final css = File('lib/features/lucky-canon/luckyCanon.css')
        .readAsStringSync();
    expect(css, contains('--lc-marble'));
    expect(css, contains('--lc-cannon'));
  });

  test('weather parser reads city and temperature', () {
    final report = parseWeather({
      'name': 'Seoul',
      'weather': [
        {'description': '맑음'},
      ],
      'main': {'temp': 18.2, 'humidity': 40},
      'wind': {'speed': 3.5},
    });
    expect(report.city, 'Seoul');
    expect(report.tempC, 18.2);
    expect(report.summary, contains('18.2'));
  });

  test('exchange parser reads a successful pair rate', () {
    final quote = parseExchange({
      'result': 'success',
      'conversion_rate': 1350.5,
      'base_code': 'USD',
      'target_code': 'KRW',
    });
    expect(quote.from, 'USD');
    expect(quote.to, 'KRW');
    expect(quote.converted, 1350.5);
    expect(() => parseExchange({'result': 'error'}), throwsFormatException);
  });

  test('gemini text skips thought parts', () {
    final text = extractGeminiText({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': '생각', 'thought': true},
              {'text': '요약 결과'},
            ],
          },
        },
      ],
    });
    expect(text, '요약 결과');
  });
}
