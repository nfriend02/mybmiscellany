import 'package:flutter/services.dart';

import 'cssInjector.dart';

Future<Map<String, Color>> loadCssColors(String asset) async {
  final css = await rootBundle.loadString(asset);
  injectCss(css);
  final colors = <String, Color>{};
  final pattern = RegExp(r'--([A-Za-z0-9-]+)\s*:\s*(#[0-9A-Fa-f]{6})');
  for (final match in pattern.allMatches(css)) {
    colors[match.group(1)!] = _hex(match.group(2)!);
  }
  return colors;
}

Color _hex(String value) {
  final hex = value.replaceFirst('#', '');
  return Color(int.parse('FF$hex', radix: 16));
}
