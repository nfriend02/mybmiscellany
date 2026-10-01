import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

String createSalt([Random? random]) {
  final source = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => source.nextInt(256));
  return base64Url.encode(bytes);
}

String hashPassword(String password, String salt) {
  final hmac = Hmac(sha256, utf8.encode(password));
  var digest = hmac.convert(utf8.encode(salt)).bytes;
  for (var round = 1; round < 10000; round++) {
    digest = hmac.convert(digest).bytes;
  }
  return base64Url.encode(digest);
}

bool passwordMatches(String password, String salt, String expected) {
  final actual = hashPassword(password, salt);
  if (actual.length != expected.length) return false;
  var difference = 0;
  for (var index = 0; index < actual.length; index++) {
    difference |= actual.codeUnitAt(index) ^ expected.codeUnitAt(index);
  }
  return difference == 0;
}
