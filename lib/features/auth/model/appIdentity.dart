import 'dart:math';

const appIdPattern = r'^[A-Za-z][A-Za-z0-9]{15}$';

String createAppId([Random? random]) {
  final source = random ?? Random.secure();
  const letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final buffer = StringBuffer(letters[source.nextInt(letters.length)]);
  for (var index = 0; index < 15; index++) {
    buffer.write(chars[source.nextInt(chars.length)]);
  }
  return buffer.toString();
}

bool isAppId(String value) => RegExp(appIdPattern).hasMatch(value);
