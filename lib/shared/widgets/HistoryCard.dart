import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format/formatTimestamp.dart';
import '../../core/history/saveResult.dart';
import '../../core/models/historyEntry.dart';
import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';

class HistoryCard extends StatelessWidget {
  const HistoryCard({super.key, required this.entry, required this.onDelete});

  final HistoryEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final sync = switch (entry.sync) {
      CloudSync.synced => ('동기화됨', AppColors.blue),
      CloudSync.local => ('이 기기', AppColors.muted),
      CloudSync.failed => ('동기화 실패', AppColors.neonOrange),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  style: labelText(color: AppColors.ink, size: 14),
                ),
              ),
              Text(sync.$1, style: labelText(color: sync.$2, size: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            entry.preview,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: bodyText(size: 13, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                formatTimestamp(entry.createdAt),
                style: labelText(size: 12),
              ),
              const Spacer(),
              IconButton(
                tooltip: '복사',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: entry.preview));
                  if (!context.mounted) return;
                  showAppMessage(context, '결과를 복사했습니다.');
                },
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
              IconButton(
                tooltip: '삭제',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
