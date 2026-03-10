import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class ConfidenceBar extends StatelessWidget {
  final int confidence;

  const ConfidenceBar({super.key, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final clamped = confidence.clamp(0, 100);
    final fraction = clamped / 100;

    Color color;
    if (clamped >= 85) {
      color = AppColors.buy;
    } else if (clamped >= 70) {
      color = AppColors.watch;
    } else {
      color = AppColors.avoid;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'الثقة',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const Spacer(),
            Text(
              '$clamped%',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction.toDouble(),
            minHeight: 8,
            color: color,
            backgroundColor: AppColors.divider,
          ),
        ),
      ],
    );
  }
}
