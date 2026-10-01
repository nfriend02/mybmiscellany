import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mybmiscellany/features/auth/api/memberRepository.dart';
import 'package:mybmiscellany/features/auth/model/appIdentity.dart';
import 'package:mybmiscellany/features/auth/model/credentialRules.dart';
import 'package:mybmiscellany/features/auth/model/defaultAdmin.dart';
import 'package:mybmiscellany/features/auth/model/passwordHash.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('app id starts with a letter and stays 16 characters', () {
    final random = Random(7);
    final id = createAppId(random);
    expect(id, hasLength(16));
    expect(isAppId(id), isTrue);
    expect(isAppId('1abcdefghijklmno'), isFalse);
    expect(isAppId('short'), isFalse);
  });

  test('email phone and password rules match the sign-up messages', () {
    expect(emailFormatError('person@example.com'), isNull);
    expect(emailFormatError('person'), '이메일을 입력하세요');
    expect(passwordFormatError('ab12cd'), isNull);
    expect(passwordFormatError('한글비밀번호'), '문자 또는 숫자로만 입력하세요');
    expect(passwordFormatError('short'), '문자 또는 숫자로만 입력하세요');
    expect(passwordConfirmError('abcdef', 'abcdef'), isNull);
    expect(passwordConfirmError('abcdef', 'abcdeg'), '비밀번호가 일치하지 않습니다');
    expect(phoneFormatError('10-1234-5678'), isNull);
    expect(phoneFormatError('1234'), '휴대폰 번호를 입력하세요');
    expect(normalizePhone('+ 82 ', '10-1234-5678'), '+821012345678');
  });

  test('password hash does not keep the original password', () {
    const password = 'secret1';
    final salt = createSalt(Random(3));
    final hash = hashPassword(password, salt);
    expect(hash.contains(password), isFalse);
    expect(passwordMatches(password, salt, hash), isTrue);
    expect(passwordMatches('secret2', salt, hash), isFalse);
  });

  test('default admin can sign in and keep a changed password', () async {
    SharedPreferences.setMockInitialValues({});
    const repository = MemberRepository();
    await repository.ensureDefaultAdmin();
    final admin = await repository.authenticate(
      normalizeEmail(defaultAdminEmail),
      defaultAdminPassword,
    );
    expect(admin, isNotNull);
    expect(admin!.admin, isTrue);
    expect(passwordFormatError(defaultAdminPassword), isNull);

    await repository.updatePassword(
      loginId: normalizeEmail(defaultAdminEmail),
      password: 'changed1',
    );
    await repository.ensureDefaultAdmin();
    expect(
      await repository.passwordAccepted(
        normalizeEmail(defaultAdminEmail),
        'changed1',
      ),
      isTrue,
    );
    expect(
      await repository.passwordAccepted(
        normalizeEmail(defaultAdminEmail),
        defaultAdminPassword,
      ),
      isFalse,
    );

    await repository.register(
      loginId: 'member@example.com',
      nickname: '회원',
      kind: 'email',
      password: 'member1',
      appId: createAppId(Random(1)),
      email: 'member@example.com',
    );
    await repository.appointAdmin('member@example.com');
    final members = await repository.listMembers();
    expect(
      members.any(
        (member) => member.loginId == 'member@example.com' && member.admin,
      ),
      isTrue,
    );
  });
}
