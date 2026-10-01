import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/history/historyRepository.dart';
import '../../core/registry/featureModule.dart';
import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';
import 'HistoryCard.dart';
import 'IconSet.dart';

class FeatureFrame extends StatelessWidget {
  const FeatureFrame({super.key, required this.module, required this.children});

  final FeatureModule module;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryRepository>().forFeature(
      module.featureType,
    );
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(module.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                Icon(
                  IconSet.of(module.featureType),
                  color: module.isGame ? AppColors.neonPurple : AppColors.blue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        style: orbitron(18, color: AppColors.navy),
                      ),
                      Text(
                        module.koreanTitle,
                        style: bodyText(size: 13, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(module.description, style: bodyText(color: AppColors.ink)),
            const SizedBox(height: 18),
            ...children,
            const SizedBox(height: 22),
            Text('기록', style: orbitron(16, color: AppColors.navy)),
            const SizedBox(height: 10),
            if (history.isEmpty)
              Text('아직 저장된 결과가 없습니다.', style: bodyText(color: AppColors.muted))
            else
              for (final entry in history)
                HistoryCard(
                  entry: entry,
                  onDelete: () =>
                      context.read<HistoryRepository>().delete(entry.resultId),
                ),
          ],
        ),
      ),
    );
  }
}
