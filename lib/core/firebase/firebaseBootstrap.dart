import 'package:firebase_core/firebase_core.dart';

import 'firebaseOptions.dart';

class FirebaseBootstrap {
  static bool ready = false;
  static String status = 'Firebase 연결 전';

  static Future<void> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.current);
      }
      ready = true;
      status = 'Firebase 연결됨';
    } catch (_) {
      ready = false;
      status = '로컬 모드';
    }
  }
}
