const loremWords = [
  'lorem',
  'ipsum',
  'dolor',
  'sit',
  'amet',
  'consectetur',
  'adipiscing',
  'elit',
  'sed',
  'do',
  'eiusmod',
  'tempor',
  'incididunt',
  'ut',
  'labore',
  'et',
  'dolore',
  'magna',
  'aliqua',
  'enim',
  'ad',
  'minim',
  'veniam',
  'quis',
  'nostrud',
  'exercitation',
  'ullamco',
  'laboris',
  'nisi',
  'aliquip',
  'ex',
  'ea',
  'commodo',
  'consequat',
  'duis',
  'aute',
  'irure',
  'in',
  'reprehenderit',
  'voluptate',
  'velit',
  'esse',
  'cillum',
  'fugiat',
  'nulla',
  'pariatur',
  'excepteur',
  'sint',
  'occaecat',
  'cupidatat',
  'non',
  'proident',
  'sunt',
  'culpa',
  'qui',
  'officia',
  'deserunt',
  'mollit',
  'anim',
  'id',
  'est',
  'laborum',
];

String generateLorem(int length, {String seed = ''}) {
  if (length < 10 || length > 5000) {
    throw const FormatException('길이는 10자에서 5000자 사이여야 합니다.');
  }
  final extra = seed.trim().isEmpty
      ? const <String>[]
      : seed
            .trim()
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .toList();
  final words = extra.isEmpty ? loremWords : [...extra, ...loremWords];
  final buffer = StringBuffer();
  var index = 0;
  while (buffer.length < length) {
    if (buffer.isNotEmpty) buffer.write(' ');
    buffer.write(words[index % words.length]);
    index++;
  }
  return buffer.toString().substring(0, length);
}
