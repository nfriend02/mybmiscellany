import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/historyEntry.dart';
import '../session/sessionController.dart';
import 'historyRepository.dart';

Future<void> saveResult(
  BuildContext context, {
  required String featureType,
  required String title,
  required String preview,
  required Map<String, dynamic> input,
  required Map<String, dynamic> output,
}) async {
  final user = context.read<SessionController>().user;
  final entry = await context.read<HistoryRepository>().add(
    user: user,
    featureType: featureType,
    title: title,
    preview: preview,
    input: input,
    output: output,
  );
  if (!context.mounted) return;
  final message = switch (entry.sync) {
    CloudSync.synced => '기록에 저장하고 Firebase에 동기화했습니다.',
    CloudSync.local => '이 기기에 저장했습니다.',
    CloudSync.failed =>
      '이 기기에 저장했습니다. Firebase 동기화는 연결 규칙이 열린 뒤 다시 시도할 수 있습니다.',
  };
  showAppMessage(context, message);
}

void showAppMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
