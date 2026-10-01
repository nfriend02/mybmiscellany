import 'package:flutter/material.dart';

import '../../core/theme/appColors.dart';
import '../../core/theme/appTheme.dart';

class ResultPanel extends StatelessWidget {
  const ResultPanel({super.key, required this.child, this.title});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: labelText(color: AppColors.ink, size: 14)),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.accent = AppColors.blue,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelText(size: 12)),
          const SizedBox(height: 6),
          Text(value, style: orbitron(20, color: accent)),
        ],
      ),
    );
  }
}

class NoteText extends StatelessWidget {
  const NoteText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: bodyText(size: 13, color: AppColors.muted));
  }
}
