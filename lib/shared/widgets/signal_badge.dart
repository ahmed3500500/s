import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_enums.dart';

class SignalBadge extends StatelessWidget {
  final RecommendationAction action;

  const SignalBadge({super.key, required this.action});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (action) {
      RecommendationAction.buy => ('BUY', AppColors.buy),
      RecommendationAction.watch => ('WATCH', AppColors.watch),
      RecommendationAction.avoid => ('AVOID', AppColors.avoid),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
