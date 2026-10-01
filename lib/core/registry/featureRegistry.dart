import '../../features/audio-editor/AudioEditorWidget.dart';
import '../../features/bmi-calculator/BmiCalculatorWidget.dart';
import '../../features/document-analyzer/DocumentAnalyzerWidget.dart';
import '../../features/document-summarizer/DocumentSummarizerWidget.dart';
import '../../features/exchange-rate/ExchangeRateWidget.dart';
import '../../features/lorem-ipsum-generator/LoremIpsumGeneratorWidget.dart';
import '../../features/lucky-canon/LuckyCanonWidget.dart';
import '../../features/out-of-office/OutOfOfficeWidget.dart';
import '../../features/pdfs-merger/PdfsMergerWidget.dart';
import '../../features/weather/WeatherWidget.dart';
import '../../features/words-counter/WordsCounterWidget.dart';
import 'featureModule.dart';

/// Add a module here after creating `/lib/features/<feature-name>`.
/// `featureType` must match the folder name. The route is `/<featureType>`.
class FeatureRegistry {
  static final List<FeatureModule> all = [
    FeatureModule(
      featureType: 'lucky-canon',
      title: 'Lucky Canon',
      koreanTitle: '럭키 캐논',
      description: '닉네임 구슬을 쏘아 올리고, 마지막에 떨어진 구슬이 이깁니다.',
      emoji: '🎯',
      section: FeatureSection.gameCenter,
      build: (context, module) => LuckyCanonWidget(module: module),
    ),
    FeatureModule(
      featureType: 'out-of-office',
      title: 'Out of Office',
      koreanTitle: '부재중',
      description: '일정과 복귀 시각으로 안내 문구를 만들고 그라데이션으로 보여 줍니다.',
      emoji: '⏰',
      section: FeatureSection.learningToolbox,
      build: (context, module) => OutOfOfficeWidget(module: module),
    ),
    FeatureModule(
      featureType: 'bmi-calculator',
      title: 'BMI Calculator',
      koreanTitle: '체질량',
      description: '키, 몸무게, 성별로 BMI와 참고 목표 체중을 계산합니다.',
      emoji: '⚖️',
      section: FeatureSection.learningToolbox,
      build: (context, module) => BmiCalculatorWidget(module: module),
    ),
    FeatureModule(
      featureType: 'document-summarizer',
      title: 'Document Summarizer',
      koreanTitle: '문서 요약',
      description: 'PDF, DOC, 텍스트를 Gemini로 요약합니다. 연결이 없으면 TextRank를 씁니다.',
      emoji: '📄',
      section: FeatureSection.learningToolbox,
      build: (context, module) => DocumentSummarizerWidget(module: module),
    ),
    FeatureModule(
      featureType: 'pdfs-merger',
      title: 'PDFs Merger',
      koreanTitle: 'PDF 병합',
      description: '여러 PDF를 순서대로 하나의 파일로 합칩니다.',
      emoji: '📚',
      section: FeatureSection.learningToolbox,
      build: (context, module) => PdfsMergerWidget(module: module),
    ),
    FeatureModule(
      featureType: 'audio-editor',
      title: 'Audio Editor',
      koreanTitle: '오디오 편집',
      description: '오디오를 재생하고 볼륨과 구간을 조절한 뒤 WAV로 저장합니다.',
      emoji: '🎵',
      section: FeatureSection.learningToolbox,
      build: (context, module) => AudioEditorWidget(module: module),
    ),
    FeatureModule(
      featureType: 'words-counter',
      title: 'Words Counter',
      koreanTitle: '글자 수',
      description: '글자, 단어, 공백과 한글 2바이트 환산 길이를 바로 보여 줍니다.',
      emoji: '🔢',
      section: FeatureSection.learningToolbox,
      build: (context, module) => WordsCounterWidget(module: module),
    ),
    FeatureModule(
      featureType: 'document-analyzer',
      title: 'Document Analyzer',
      koreanTitle: '문서 분석',
      description: '문서의 글자 수, 단어 수, 공백, 이미지 수를 분석합니다.',
      emoji: '📊',
      section: FeatureSection.learningToolbox,
      build: (context, module) => DocumentAnalyzerWidget(module: module),
    ),
    FeatureModule(
      featureType: 'lorem-ipsum-generator',
      title: 'Lorem Ipsum',
      koreanTitle: '로렘 입숨',
      description: '기본 150자에서 슬라이더로 10자부터 5000자까지 조절합니다.',
      emoji: '✍️',
      section: FeatureSection.learningToolbox,
      build: (context, module) => LoremIpsumGeneratorWidget(module: module),
    ),
    FeatureModule(
      featureType: 'weather',
      title: 'Weather',
      koreanTitle: '날씨',
      description: 'OpenWeather로 도시의 현재 기온, 습도, 바람을 가져옵니다.',
      emoji: '🌤️',
      section: FeatureSection.learningToolbox,
      build: (context, module) => WeatherWidget(module: module),
    ),
    FeatureModule(
      featureType: 'exchange-rate',
      title: 'Exchange Rate',
      koreanTitle: '환율',
      description: 'ExchangeRate-API로 두 통화의 현재 환율과 환산 금액을 보여 줍니다.',
      emoji: '💱',
      section: FeatureSection.learningToolbox,
      build: (context, module) => ExchangeRateWidget(module: module),
    ),
  ];

  static List<FeatureModule> inSection(FeatureSection section) {
    return all.where((feature) => feature.section == section).toList();
  }
}
