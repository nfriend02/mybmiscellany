import '../../core/format/formatTimestamp.dart';

class OutOfOfficeMessage {
  const OutOfOfficeMessage({
    required this.text,
    required this.start,
    required this.returnAt,
  });

  final String text;
  final DateTime start;
  final DateTime returnAt;
}

OutOfOfficeMessage buildOutOfOffice({
  required String name,
  required String role,
  required DateTime start,
  required DateTime returnAt,
  required String reason,
  required String contact,
}) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    throw const FormatException('이름을 입력해 주세요.');
  }
  if (!returnAt.isAfter(start)) {
    throw const FormatException('복귀 시간은 시작 시각 이후여야 합니다.');
  }
  final who = role.trim().isEmpty ? trimmedName : '${role.trim()} $trimmedName';
  final reasonLine = reason.trim().isEmpty ? '' : '사유: ${reason.trim()}\n';
  final contactLine = contact.trim().isEmpty
      ? '긴급한 용무는 복귀 후 전달해 주세요.'
      : '긴급한 용무는 ${contact.trim()} 로 연락 부탁드립니다.';
  final text =
      '''
안녕하세요. $who 입니다.
${formatTimestamp(start)} 부터 ${formatTimestamp(returnAt)} 까지 자리를 비웁니다.
$reasonLine복귀 후 확인되는 순서대로 답변드리겠습니다.
$contactLine'''
          .trim();
  return OutOfOfficeMessage(text: text, start: start, returnAt: returnAt);
}
