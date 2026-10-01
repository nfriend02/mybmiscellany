import 'package:flutter/foundation.dart';

class OfficeNoticeBoard extends ChangeNotifier {
  String? title;
  String? text;

  void publish({required String title, required String text}) {
    this.title = title;
    this.text = text;
    notifyListeners();
  }
}
