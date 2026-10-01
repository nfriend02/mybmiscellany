import 'package:google_sign_in/google_sign_in.dart';

import '../config/appSecrets.dart';

class GoogleAuth {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized || !AppSecrets.hasOAuth) return;
    await GoogleSignIn.instance.initialize(clientId: AppSecrets.oauthClientId);
    _initialized = true;
  }

  static Future<GoogleSignInAccount> signIn() async {
    if (!AppSecrets.hasOAuth) {
      throw const FormatException('OAuth_Client_ID가 설정되지 않았습니다.');
    }
    await ensureInitialized();
    return GoogleSignIn.instance.authenticate();
  }

  static Future<void> signOut() async {
    if (!_initialized) return;
    await GoogleSignIn.instance.signOut();
  }
}
