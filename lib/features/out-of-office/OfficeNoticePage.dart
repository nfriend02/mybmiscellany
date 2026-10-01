import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';
import 'officeNoticeBoard.dart';

class OfficeNoticePage extends StatelessWidget {
  const OfficeNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    final notice = context.watch<OfficeNoticeBoard>();
    final text = notice.text;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OUT OF OFFICE', style: pixel(12, color: AppColors.neonGreen)),
            const SizedBox(height: 8),
            Text(
              notice.title ?? '부재 안내',
              style: orbitron(22, color: AppColors.navy),
            ),
            const SizedBox(height: 16),
            if (text == null)
              Text('게시된 안내가 없습니다.', style: bodyText(color: AppColors.muted))
            else
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 420),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.blue,
                      AppColors.neonPurple,
                      AppColors.neonOrange,
                      AppColors.blueBright,
                    ],
                  ),
                ),
                child: SelectableText(
                  text,
                  style: bodyText(color: Colors.white, size: 22),
                ),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go('/out-of-office'),
              child: const Text('안내 작성으로'),
            ),
          ],
        ),
      ),
    );
  }
}
