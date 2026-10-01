import 'package:flutter/material.dart';

class IconSet {
  static const gameCenter = Icons.sports_esports_rounded;
  static const toolbox = Icons.school_rounded;
  static const home = Icons.home_rounded;
  static const menu = Icons.menu_rounded;

  static const Map<String, IconData> _icons = {
    'out-of-office': Icons.event_busy_rounded,
    'bmi-calculator': Icons.monitor_weight_rounded,
    'lucky-canon': Icons.track_changes_rounded,
    'document-summarizer': Icons.summarize_rounded,
    'pdfs-merger': Icons.library_books_rounded,
    'audio-editor': Icons.graphic_eq_rounded,
    'words-counter': Icons.pin_rounded,
    'document-analyzer': Icons.analytics_rounded,
    'lorem-ipsum-generator': Icons.draw_rounded,
    'weather': Icons.wb_sunny_rounded,
    'exchange-rate': Icons.currency_exchange_rounded,
  };

  static IconData of(String featureType) =>
      _icons[featureType] ?? Icons.extension_rounded;
}
