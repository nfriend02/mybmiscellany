import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/firestoreGateway.dart';
import '../models/appUser.dart';

class SessionController extends ChangeNotifier {
  SessionController({FirestoreGateway? gateway})
    : _gateway = gateway ?? const FirestoreGateway();

  final FirestoreGateway _gateway;
  AppUser user = AppUser.guest();

  Future<void> bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedId = prefs.getString('userId');
      final storedCreated = prefs.getString('createdAt');
      final created = storedCreated == null
          ? user.createdAt
          : DateTime.tryParse(storedCreated) ?? user.createdAt;
      final id = storedId ?? user.userId;
      if (storedId == null) {
        await prefs.setString('userId', id);
        await prefs.setString('createdAt', created.toIso8601String());
      }
      user = AppUser(
        userId: id,
        displayName: prefs.getString('displayName') ?? '게스트',
        email: prefs.getString('email') ?? '',
        avatarUrl: prefs.getString('avatarUrl') ?? '',
        createdAt: created,
      );
    } catch (_) {}
    notifyListeners();
    await _gateway.touchUser(user);
  }

  Future<void> applyProfile({
    required String displayName,
    required String email,
    required String avatarUrl,
  }) async {
    final name = displayName.trim().isEmpty ? '게스트' : displayName.trim();
    user = AppUser(
      userId: user.userId,
      displayName: name,
      email: email.trim(),
      avatarUrl: avatarUrl.trim(),
      createdAt: user.createdAt,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('displayName', user.displayName);
      await prefs.setString('email', user.email);
      await prefs.setString('avatarUrl', user.avatarUrl);
    } catch (_) {}
    notifyListeners();
    await _gateway.touchUser(user);
  }
}
