import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';

class GameSplash extends StatefulWidget {
  const GameSplash({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onFinished,
  });

  final String title;
  final String subtitle;
  final VoidCallback onFinished;

  @override
  State<GameSplash> createState() => _GameSplashState();
}

class _GameSplashState extends State<GameSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _timer = Timer(const Duration(milliseconds: 1700), _finish);
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _finish,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                colors: [AppColors.navyDeep, AppColors.blue, Color(0xFF241447)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(
              painter: _RingPainter(_controller.value),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: pixel(14, color: AppColors.neonGreen),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.subtitle,
                      style: bodyText(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '탭하면 바로 시작합니다',
                      style: labelText(color: AppColors.aqua, size: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var i = 0; i < 3; i++) {
      final progress = (t + i * 0.22) % 1;
      paint.color = [
        AppColors.neonGreen,
        AppColors.neonPurple,
        AppColors.neonOrange,
      ][i].withValues(alpha: 1 - progress);
      canvas.drawCircle(
        center,
        30 + progress * math.min(size.width, size.height) * 0.45,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.t != t;
}
