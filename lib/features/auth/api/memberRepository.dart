import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/firebase/firebaseBootstrap.dart';
import '../model/appIdentity.dart';
import '../model/credentialRules.dart';
import '../model/defaultAdmin.dart';
import '../model/passwordHash.dart';

class MemberSession {
  const MemberSession({
    required this.loginId,
    required this.nickname,
    required this.kind,
    required this.admin,
  });

  final String loginId;
  final String nickname;
  final String kind;
  final bool admin;
}

class MemberSummary {
  const MemberSummary({
    required this.loginId,
    required this.nickname,
    required this.admin,
  });

  final String loginId;
  final String nickname;
  final bool admin;
}

class MemberRepository {
  const MemberRepository();

  static const _vaultKey = 'memberVault';

  Future<void> saveIdentity({
    required String appId,
    String loginId = '',
  }) async {
    if (!FirebaseBootstrap.ready || appId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final known = prefs.getBool('identitySaved') ?? false;
      await FirebaseFirestore.instance.collection('identities').doc(appId).set({
        'appId': appId,
        'loginId': loginId,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!known) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await prefs.setBool('identitySaved', true);
    } catch (_) {}
  }

  Future<void> unlinkIdentity(String appId) async {
    if (!FirebaseBootstrap.ready || appId.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('identities').doc(appId).set({
        'loginId': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<MemberSession?> find(String loginId) async {
    final record = await _record(loginId);
    if (record == null) return null;
    return _sessionFrom(loginId, record);
  }

  Future<bool> exists(String loginId) async {
    if (loginId.isEmpty) return false;
    final remote = await _remote(loginId);
    if (remote != null) return true;
    final local = await _local();
    return local.containsKey(loginId);
  }

  Future<bool> passwordAccepted(String loginId, String password) async {
    final record = await _record(loginId);
    if (record == null) return false;
    final hash = record['passwordHash'] ?? '';
    final salt = record['passwordSalt'] ?? '';
    if (hash.isEmpty || salt.isEmpty) return false;
    return passwordMatches(password, salt, hash);
  }

  Future<MemberSession?> authenticate(String loginId, String password) async {
    if (!await passwordAccepted(loginId, password)) return null;
    final record = await _record(loginId);
    if (record == null) return null;
    return _sessionFrom(loginId, record);
  }

  Future<void> ensureDefaultAdmin() async {
    final loginId = normalizeEmail(defaultAdminEmail);
    final current = await _record(loginId);
    if (current == null) {
      final salt = createSalt();
      await _write(
        loginId: loginId,
        nickname: '관리자',
        kind: 'email',
        passwordHash: hashPassword(defaultAdminPassword, salt),
        passwordSalt: salt,
        appId: createAppId(),
        email: loginId,
        admin: true,
      );
      return;
    }
    if (current['admin'] == 'true') return;
    await _write(
      loginId: loginId,
      nickname: current['nickname']?.isNotEmpty == true
          ? current['nickname']!
          : '관리자',
      kind: current['kind']?.isNotEmpty == true ? current['kind']! : 'email',
      passwordHash: current['passwordHash'] ?? '',
      passwordSalt: current['passwordSalt'] ?? '',
      appId: current['appId'] ?? '',
      email: loginId,
      firebaseUid: current['firebaseUid'] ?? '',
      admin: true,
    );
  }

  Future<List<MemberSummary>> listMembers() async {
    final merged = <String, MemberSummary>{};
    for (final entry in (await _local()).entries) {
      merged[entry.key] = MemberSummary(
        loginId: entry.key,
        nickname: entry.value['nickname'] ?? '',
        admin: entry.value['admin'] == 'true',
      );
    }
    if (FirebaseBootstrap.ready) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('members')
            .get();
        for (final doc in snap.docs) {
          final data = doc.data();
          merged[doc.id] = MemberSummary(
            loginId: doc.id,
            nickname: '${data['nickname'] ?? ''}',
            admin: data['admin'] == true || '${data['admin']}' == 'true',
          );
        }
      } catch (_) {}
    }
    final members = merged.values.toList()
      ..sort((a, b) => a.loginId.compareTo(b.loginId));
    return members;
  }

  Future<void> appointAdmin(String loginId) async {
    final current = await _record(loginId);
    if (current == null) {
      throw const FormatException('가입된 회원이 아닙니다.');
    }
    await _write(
      loginId: loginId,
      nickname: current['nickname'] ?? '',
      kind: current['kind'] ?? '',
      passwordHash: current['passwordHash'] ?? '',
      passwordSalt: current['passwordSalt'] ?? '',
      appId: current['appId'] ?? '',
      email: current['email'] ?? '',
      firebaseUid: current['firebaseUid'] ?? '',
      admin: true,
    );
  }

  Future<void> register({
    required String loginId,
    required String nickname,
    required String kind,
    required String password,
    required String appId,
    String email = '',
  }) async {
    final salt = createSalt();
    final hash = hashPassword(password, salt);
    await _write(
      loginId: loginId,
      nickname: nickname,
      kind: kind,
      passwordHash: hash,
      passwordSalt: salt,
      appId: appId,
      email: email,
    );
  }

  Future<void> registerGoogle({
    required String email,
    required String nickname,
    required String appId,
    String firebaseUid = '',
  }) async {
    final current = await _record(email);
    await _write(
      loginId: email,
      nickname: nickname,
      kind: 'google',
      passwordHash: current?['passwordHash'] ?? '',
      passwordSalt: current?['passwordSalt'] ?? '',
      appId: appId,
      email: email,
      firebaseUid: firebaseUid,
      admin: current?['admin'] == 'true',
    );
  }

  Future<void> updateNickname({
    required String loginId,
    required String nickname,
  }) async {
    final current = await _record(loginId);
    if (current == null) return;
    await _write(
      loginId: loginId,
      nickname: nickname,
      kind: current['kind'] ?? '',
      passwordHash: current['passwordHash'] ?? '',
      passwordSalt: current['passwordSalt'] ?? '',
      appId: current['appId'] ?? '',
      email: current['email'] ?? '',
      firebaseUid: current['firebaseUid'] ?? '',
      admin: current['admin'] == 'true',
    );
  }

  Future<void> updatePassword({
    required String loginId,
    required String password,
  }) async {
    final current = await _record(loginId);
    if (current == null) return;
    final salt = createSalt();
    await _write(
      loginId: loginId,
      nickname: current['nickname'] ?? '',
      kind: current['kind'] ?? '',
      passwordHash: hashPassword(password, salt),
      passwordSalt: salt,
      appId: current['appId'] ?? '',
      email: current['email'] ?? '',
      firebaseUid: current['firebaseUid'] ?? '',
      admin: current['admin'] == 'true',
    );
  }

  Future<void> withdraw(String loginId) async {
    final local = await _local();
    local.remove(loginId);
    await _saveLocal(local);
    if (!FirebaseBootstrap.ready || loginId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('members')
          .doc(loginId)
          .delete();
    } catch (_) {}
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(loginId)
          .delete();
    } catch (_) {}
  }

  Future<void> _write({
    required String loginId,
    required String nickname,
    required String kind,
    required String passwordHash,
    required String passwordSalt,
    required String appId,
    required String email,
    String firebaseUid = '',
    bool admin = false,
  }) async {
    final local = await _local();
    local[loginId] = {
      'loginId': loginId,
      'nickname': nickname,
      'kind': kind,
      'passwordHash': passwordHash,
      'passwordSalt': passwordSalt,
      'appId': appId,
      'email': email,
      'firebaseUid': firebaseUid,
      'admin': admin ? 'true' : 'false',
    };
    await _saveLocal(local);
    if (!FirebaseBootstrap.ready) return;
    try {
      await FirebaseFirestore.instance.collection('members').doc(loginId).set({
        'loginId': loginId,
        'nickname': nickname,
        'kind': kind,
        'passwordHash': passwordHash,
        'passwordSalt': passwordSalt,
        'appId': appId,
        'email': email,
        'firebaseUid': firebaseUid,
        'admin': admin,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('users').doc(loginId).set({
        'userId': loginId,
        'displayName': nickname,
        'email': email,
        'provider': kind,
        'appId': appId,
        'admin': admin,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await saveIdentity(appId: appId, loginId: loginId);
    } catch (_) {}
  }

  Future<Map<String, String>?> _record(String loginId) async {
    final remote = await _remote(loginId);
    if (remote != null) return remote;
    return (await _local())[loginId];
  }

  Future<Map<String, String>?> _remote(String loginId) async {
    if (!FirebaseBootstrap.ready || loginId.isEmpty) return null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('members')
          .doc(loginId)
          .get();
      if (!snap.exists) return null;
      final data = snap.data() ?? {};
      return {
        'loginId': loginId,
        'nickname': '${data['nickname'] ?? ''}',
        'kind': '${data['kind'] ?? ''}',
        'passwordHash': '${data['passwordHash'] ?? ''}',
        'passwordSalt': '${data['passwordSalt'] ?? ''}',
        'appId': '${data['appId'] ?? ''}',
        'email': '${data['email'] ?? ''}',
        'firebaseUid': '${data['firebaseUid'] ?? ''}',
        'admin': data['admin'] == true || '${data['admin']}' == 'true'
            ? 'true'
            : 'false',
      };
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, Map<String, String>>> _local() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_vaultKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final vault = <String, Map<String, String>>{};
      decoded.forEach((dynamic key, dynamic value) {
        if (value is! Map) return;
        vault[key.toString()] = value.map(
          (dynamic itemKey, dynamic item) =>
              MapEntry(itemKey.toString(), item.toString()),
        );
      });
      return vault;
    } catch (_) {
      return {};
    }
  }

  MemberSession _sessionFrom(String loginId, Map<String, String> record) {
    return MemberSession(
      loginId: loginId,
      nickname: record['nickname'] ?? '',
      kind: record['kind'] ?? '',
      admin: record['admin'] == 'true',
    );
  }

  Future<void> _saveLocal(Map<String, Map<String, String>> vault) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_vaultKey, jsonEncode(vault));
    } catch (_) {}
  }
}
