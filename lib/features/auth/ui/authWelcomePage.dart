import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/appColors.dart';
import '../../../core/theme/appTheme.dart';
import 'authWidgets.dart';

class AuthWelcomePage extends StatelessWidget {
  const AuthWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      child: Column(
        children: [
          const BrandMark(),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F8FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('이렇게 사용해요', style: orbitron(14, color: AppColors.navy)),
                const SizedBox(height: 8),
                Text(
                  '왼쪽 메뉴에서 게임과 학습 도구를 고르세요. 회원가입 없이도 모든 메뉴를 사용할 수 있습니다. 결과가 마음에 들면 저장을 누르고, 계정은 원할 때 만들면 됩니다.',
                  style: bodyText(size: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '오늘의 작은 호기심이 내일의 실력이 됩니다. 부담 없이 한 가지를 골라 시작해 보세요.',
            style: bodyText(
              size: 14,
              color: AppColors.blue,
              weight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          StackedButton(
            label: '로그인',
            onPressed: () => context.go('/auth/enter'),
          ),
          const SizedBox(height: 10),
          StackedButton(
            label: '신규 회원',
            filled: false,
            onPressed: () => context.go('/auth/join'),
          ),
        ],
      ),
    );
  }
}
