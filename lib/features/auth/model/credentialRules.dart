String? emailFormatError(String value) {
  final email = value.trim();
  final matches = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
      .hasMatch(email);
  return matches ? null : '이메일을 입력하세요';
}

String? passwordFormatError(String value) {
  final matches = RegExp(r'^[A-Za-z0-9]{6,20}$').hasMatch(value);
  return matches ? null : '문자 또는 숫자로만 입력하세요';
}

String? passwordConfirmError(String password, String confirm) {
  if (password == confirm) return null;
  return '비밀번호가 일치하지 않습니다';
}

String? phoneFormatError(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length >= 9 && digits.length <= 11) return null;
  return '휴대폰 번호를 입력하세요';
}

String normalizeEmail(String value) => value.trim().toLowerCase();

String normalizePhone(String country, String number) {
  final code = country.replaceAll(RegExp(r'[^0-9]'), '');
  final digits = number.replaceAll(RegExp(r'[^0-9]'), '');
  return '+$code$digits';
}
