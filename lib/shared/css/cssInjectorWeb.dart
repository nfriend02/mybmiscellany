import 'package:web/web.dart';

void injectCss(String css) {
  final head = document.head;
  if (head == null) return;
  final style = HTMLStyleElement();
  style.textContent = css;
  head.append(style);
}
