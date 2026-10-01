import 'dart:js_interop';

import 'package:web/web.dart' as web;

void bindSiteLeave(void Function() onLeave) {
  web.window.addEventListener('pagehide', ((web.Event _) => onLeave()).toJS);
}
