import 'package:flutter/widgets.dart';

enum FeatureSection { gameCenter, learningToolbox }

class FeatureModule {
  const FeatureModule({
    required this.featureType,
    required this.title,
    required this.koreanTitle,
    required this.description,
    required this.emoji,
    required this.section,
    required this.build,
  });

  final String featureType;
  final String title;
  final String koreanTitle;
  final String description;
  final String emoji;
  final FeatureSection section;
  final Widget Function(BuildContext context, FeatureModule module) build;

  String get route => '/$featureType';

  bool get isGame => section == FeatureSection.gameCenter;
}
