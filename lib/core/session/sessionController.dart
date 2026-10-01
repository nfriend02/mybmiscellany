import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/api/memberRepository.dart';
import '../../features/auth/model/appIdentity.dart';
import '../../features/auth/model/credentialRules.dart';
import '../../features/auth/model/defaultAdmin.dart';
import '../auth/googleAuth.dart';
import '../firebase/firebaseBootstrap.dart';
import '../models/appUser.dart';

class SessionController extends ChangeNotifier {
  SessionController({MemberRepository? members})
    : _members = members ?? const MemberRepository();

  final MemberRepository _members;
  AppUser user = AppUser.guest();

  Future<void> bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedId = prefs.getString('appId') ?? '';
      final createdRaw = prefs.getString('createdAt');
      final created = createdRaw == null
          ? user.createdAt
          : DateTime.tryParse(createdRaw) ?? user.createdAt;
      user = AppUser(
        userId: isAppId(storedId) ? storedId : '',
        displayName: '게스트',
        email: '',
        avatarUrl: '',
        createdAt: created,
      );
      if (user.userId.isNotEmpty) {
        await prefs.setString('appId', user.userId);
      }
      await _members.ensureDefaultAdmin();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> ensureAppId() async {
    if (!isAppId(user.userId)) {
      final created = user.createdAt;
      final id = createAppId();
      user = user.copyWith(userId: id, createdAt: created);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('appId', id);
        await prefs.setString('createdAt', created.toIso8601String());
      } catch (_) {}
    }
    final loginId = user.signedIn ? _loginId : '';
    await _members.saveIdentity(appId: user.userId, loginId: loginId);
    notifyListeners();
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final loginId = normalizeEmail(email);
    await _register(
      loginId: loginId,
      password: password,
      kind: 'email',
      email: loginId,
      phone: '',
      nickname: _nicknameFrom(loginId),
    );
  }

  Future<void> registerWithPhone({
    required String country,
    required String number,
    required String password,
  }) async {
    final loginId = normalizePhone(country, number);
    await _register(
      loginId: loginId,
      password: password,
      kind: 'phone',
      email: '',
      phone: loginId,
      nickname: '회원',
    );
  }

  Future<bool> emailExists(String email) =>
      _members.exists(normalizeEmail(email));

  Future<bool> phoneExists(String country, String number) {
    return _members.exists(normalizePhone(country, number));
  }

  Future<bool> emailPasswordAccepted(String email, String password) {
    return _members.passwordAccepted(normalizeEmail(email), password);
  }

  Future<bool> phonePasswordAccepted(
    String country,
    String number,
    String password,
  ) {
    return _members.passwordAccepted(normalizePhone(country, number), password);
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final loginId = normalizeEmail(email);
    final session = await _members.authenticate(loginId, password);
    if (session == null) {
      throw const FormatException('비밀번호가 틀립니다. 다시 확인해 주세요');
    }
    await _enter(
      loginId: loginId,
      nickname: session.nickname,
      kind: 'email',
      email: loginId,
      phone: '',
    );
  }

  Future<void> signInWithPhone({
    required String country,
    required String number,
    required String password,
  }) async {
    final loginId = normalizePhone(country, number);
    final session = await _members.authenticate(loginId, password);
    if (session == null) {
      throw const FormatException('비밀번호가 틀립니다. 다시 확인해 주세요');
    }
    await _enter(
      loginId: loginId,
      nickname: session.nickname,
      kind: 'phone',
      email: '',
      phone: loginId,
    );
  }

  Future<void> signInWithGoogle() async {
    final account = await GoogleAuth.signIn();
    final email = normalizeEmail(account.email);
    if (emailFormatError(email) != null) {
      throw const FormatException('이메일 정보가 없는 Google 계정입니다.');
    }
    var firebaseUid = '';
    if (FirebaseBootstrap.ready) {
      try {
        final token = account.authentication.idToken;
        if (token != null && token.isNotEmpty) {
          final credential = GoogleAuthProvider.credential(idToken: token);
          final result = await FirebaseAuth.instance.signInWithCredential(
            credential,
          );
          firebaseUid = result.user?.uid ?? '';
        }
      } catch (_) {}
    }
    await ensureAppId();
    final nickname = (account.displayName ?? '').trim().isEmpty
        ? _nicknameFrom(email)
        : account.displayName!.trim();
    await _members.registerGoogle(
      email: email,
      nickname: nickname,
      appId: user.userId,
      firebaseUid: firebaseUid,
    );
    final profile = await _members.find(email);
    user = user.copyWith(
      displayName: nickname,
      email: email,
      phone: '',
      avatarUrl: account.photoUrl ?? '',
      loginKind: 'google',
      signedIn: true,
      admin: profile?.admin ?? false,
    );
    notifyListeners();
  }

  Future<void> updateNickname(String nickname) async {
    final name = nickname.trim();
    if (!user.signedIn || name.isEmpty) return;
    await _members.updateNickname(loginId: _loginId, nickname: name);
    user = user.copyWith(displayName: name);
    notifyListeners();
  }

  Future<List<MemberSummary>> memberChoices() {
    if (!user.admin) return Future.value(const []);
    return _members.listMembers();
  }

  Future<void> appointAdmin(String loginId) async {
    if (!user.admin) {
      throw const FormatException('관리자만 다른 관리자를 지정할 수 있습니다.');
    }
    await _members.appointAdmin(loginId);
  }

  Future<void> updatePassword(String password) async {
    if (!user.signedIn) return;
    await _members.updatePassword(loginId: _loginId, password: password);
  }

  Future<void> withdraw() async {
    final loginId = _loginId;
    if (normalizeEmail(loginId) == normalizeEmail(defaultAdminEmail)) {
      throw const FormatException('기본 관리자 계정은 탈퇴할 수 없습니다.');
    }
    final appId = user.userId;
    if (user.signedIn && loginId.isNotEmpty) {
      await _members.withdraw(loginId);
    }
    await _members.unlinkIdentity(appId);
    await _clearAuthProviders();
    user = AppUser(
      userId: appId,
      displayName: '게스트',
      email: '',
      avatarUrl: '',
      createdAt: user.createdAt,
    );
    notifyListeners();
  }

  Future<void> signOut() async {
    await _clearAuthProviders();
    user = user.copyWith(
      displayName: '게스트',
      email: '',
      phone: '',
      avatarUrl: '',
      loginKind: '',
      signedIn: false,
      admin: false,
    );
    notifyListeners();
  }

  Future<void> leaveSite() async {
    if (!user.signedIn) return;
    await _members.saveIdentity(appId: user.userId, loginId: _loginId);
    await signOut();
  }

  Future<void> applyProfile({
    required String displayName,
    required String email,
    required String avatarUrl,
  }) async {
    final name = displayName.trim().isEmpty ? '게스트' : displayName.trim();
    user = user.copyWith(
      displayName: name,
      email: email.trim(),
      avatarUrl: avatarUrl.trim(),
    );
    notifyListeners();
  }

  String get _loginId => user.loginLabel;

  Future<void> _register({
    required String loginId,
    required String password,
    required String kind,
    required String email,
    required String phone,
    required String nickname,
  }) async {
    if (await _members.exists(loginId)) {
      throw const FormatException('이미 등록된 아이디입니다.');
    }
    await ensureAppId();
    await _members.register(
      loginId: loginId,
      nickname: nickname,
      kind: kind,
      password: password,
      appId: user.userId,
      email: email,
    );
    await _enter(
      loginId: loginId,
      nickname: nickname,
      kind: kind,
      email: email,
      phone: phone,
    );
  }

  Future<void> _enter({
    required String loginId,
    required String nickname,
    required String kind,
    required String email,
    required String phone,
  }) async {
    await ensureAppId();
    final profile = await _members.find(loginId);
    user = user.copyWith(
      displayName: nickname.isEmpty ? '회원' : nickname,
      email: email,
      phone: phone,
      loginKind: kind,
      signedIn: true,
      admin: profile?.admin ?? false,
    );
    await _members.saveIdentity(appId: user.userId, loginId: loginId);
    notifyListeners();
  }

  Future<void> _clearAuthProviders() async {
    try {
      await GoogleAuth.signOut();
    } catch (_) {}
    if (!FirebaseBootstrap.ready) return;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  String _nicknameFrom(String email) {
    final name = email.split('@').first.trim();
    return name.isEmpty ? '회원' : name;
  }
}
