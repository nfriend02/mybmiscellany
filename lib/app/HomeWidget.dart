import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/appSecrets.dart';
import '../core/registry/featureModule.dart';
import '../core/registry/featureRegistry.dart';
import '../core/theme/appColors.dart';
import '../core/theme/appTheme.dart';
import '../shared/widgets/HoverPop.dart';
import '../shared/widgets/IconSet.dart';

class HomeWidget extends StatelessWidget {
  const HomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [AppColors.navy, AppColors.blue, Color(0xFF3A1D6E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PLAY & LEARN',
                    style: pixel(11, color: AppColors.neonGreen),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '배우고, 즐기고, 만드는 작업실',
                    style: orbitron(26, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '학습 플랫폼의 안정감과 게임 허브의 활기를 한 화면에 두었습니다. 게임 센터에서 한 판 즐기고, 학습 툴박스에서 결과물을 남기세요.',
                    style: bodyText(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _ApiStatus(),
            const SizedBox(height: 28),
            _Section(
              icon: IconSet.gameCenter,
              title: 'GAME CENTER',
              caption: '게임 센터',
              accent: AppColors.neonGreen,
              modules: FeatureRegistry.inSection(FeatureSection.gameCenter),
            ),
            const SizedBox(height: 28),
            _Section(
              icon: IconSet.toolbox,
              title: 'LEARNING TOOLBOX',
              caption: '학습 툴박스',
              accent: AppColors.blue,
              modules: FeatureRegistry.inSection(
                FeatureSection.learningToolbox,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApiStatus extends StatelessWidget {
  const _ApiStatus();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('날씨', AppSecrets.hasOpenWeather),
      ('환율', AppSecrets.hasExchangeRate),
      ('Gemini', AppSecrets.hasGemini),
      ('Google 로그인', AppSecrets.hasOAuth),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: item.$2 ? AppColors.neonGreen : AppColors.line,
              ),
            ),
            child: Text(
              '${item.$1} ${item.$2 ? '준비됨' : '키 없음'}',
              style: labelText(size: 12, color: AppColors.ink),
            ),
          ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.caption,
    required this.accent,
    required this.modules,
  });

  final IconData icon;
  final String title;
  final String caption;
  final Color accent;
  final List<FeatureModule> modules;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: orbitron(18, color: AppColors.navy)),
                Text(
                  caption,
                  style: bodyText(size: 13, color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 980
                ? 3
                : constraints.maxWidth >= 620
                ? 2
                : 1;
            final cardWidth =
                (constraints.maxWidth - (columns - 1) * 14) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final module in modules)
                  SizedBox(
                    width: cardWidth,
                    child: HoverPop(
                      onTap: () => context.go(module.route),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: module.isGame
                                ? AppColors.neonGreen
                                : AppColors.line,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  module.emoji,
                                  style: const TextStyle(fontSize: 26),
                                ),
                                const Spacer(),
                                Icon(
                                  IconSet.of(module.featureType),
                                  color: module.isGame
                                      ? AppColors.neonPurple
                                      : AppColors.blue,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              module.title,
                              style: orbitron(13, color: AppColors.navy),
                            ),
                            Text(
                              module.koreanTitle,
                              style: bodyText(size: 13, color: AppColors.muted),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              module.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: bodyText(size: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
