import 'package:flutter/material.dart';

import '../../../core/theme/appColors.dart';
import '../../../core/theme/appTheme.dart';
import '../../../shared/widgets/AppLogo.dart';

const maskedPassword = '*********';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.markSize = 112});

  final double markSize;

  @override
  Widget build(BuildContext context) {
    return AppLogo(markSize: markSize, onDark: false);
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class StackedButton extends StatelessWidget {
  const StackedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = Text(label);
    final button = filled
        ? FilledButton(onPressed: onPressed, child: child)
        : OutlinedButton(onPressed: onPressed, child: child);
    return SizedBox(width: double.infinity, child: button);
  }
}

class FieldBalloon extends StatelessWidget {
  const FieldBalloon({super.key, required this.message, required this.child});

  final String? message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message != null) ...[
          _Bubble(message: message!),
          const SizedBox(height: 6),
        ],
        child,
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              message,
              style: bodyText(size: 12, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: CustomPaint(
              size: const Size(14, 8),
              painter: _BalloonTail(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalloonTail extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.navy;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SecretField extends StatefulWidget {
  const SecretField({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
    this.onChanged,
    this.textInputAction,
    this.onEditingComplete,
  });

  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;

  @override
  State<SecretField> createState() => _SecretFieldState();
}

class _SecretFieldState extends State<SecretField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscured,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      onEditingComplete: widget.onEditingComplete,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          tooltip: _obscured ? '비밀번호 보기' : '비밀번호 숨기기',
          onPressed: () => setState(() => _obscured = !_obscured),
          icon: Icon(
            _obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          ),
        ),
      ),
    );
  }
}
