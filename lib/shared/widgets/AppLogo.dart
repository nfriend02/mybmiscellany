import 'package:flutter/material.dart';

import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.markSize = 88,
    this.onDark = true,
    this.compact = false,
  });

  final double markSize;
  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleColor = onDark ? Colors.white : AppColors.navy;
    final mark = _LogoBadge(size: markSize);
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'mybmiscellany',
                  style: orbitron(14, color: titleColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'PLAY & LEARN',
                  style: pixel(6, color: AppColors.neonGreen),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        mark,
        SizedBox(height: markSize > 96 ? 18 : 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'mybmiscellany',
            style: orbitron(markSize > 96 ? 26 : 18, color: titleColor),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.neonGreen.withValues(alpha: 0.8),
            ),
            color: AppColors.neonGreen.withValues(alpha: onDark ? 0.12 : 0.16),
          ),
          child: Text(
            'PLAY & LEARN',
            style: pixel(
              7,
              color: onDark ? AppColors.neonGreen : AppColors.blue,
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: const _LogoBadgePainter()),
    );
  }
}

class _LogoBadgePainter extends CustomPainter {
  const _LogoBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final badge = RRect.fromRectAndRadius(
      rect.deflate(size.width * 0.04),
      Radius.circular(size.width * 0.3),
    );

    canvas.drawRRect(
      badge.shift(const Offset(0, 3)),
      Paint()
        ..color = AppColors.neonGreen.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      badge,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF10243F), Color(0xFF1B4F8A), Color(0xFF3A1D6E)],
        ).createShader(rect),
    );
    canvas.drawRRect(
      badge.deflate(1.4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.028
        ..color = AppColors.neonGreen,
    );
    canvas.drawRRect(
      badge.deflate(size.width * 0.08),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AppColors.aqua.withValues(alpha: 0.75),
    );

    final stem = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;
    final branch = Path()
      ..moveTo(size.width * 0.34, size.height * 0.74)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.46,
        size.width * 0.56,
        size.height * 0.4,
      );
    canvas.drawPath(branch, stem);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.46, size.height * 0.52)
        ..quadraticBezierTo(
          size.width * 0.62,
          size.height * 0.46,
          size.width * 0.7,
          size.height * 0.32,
        ),
      stem..color = AppColors.aqua,
    );

    final play = Path()
      ..moveTo(size.width * 0.4, size.height * 0.34)
      ..lineTo(size.width * 0.4, size.height * 0.62)
      ..lineTo(size.width * 0.64, size.height * 0.48)
      ..close();
    canvas.drawPath(play, Paint()..color = AppColors.neonGreen);
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.3),
      size.width * 0.035,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
