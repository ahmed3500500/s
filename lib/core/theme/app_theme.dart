import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: base.colorScheme.copyWith(
        surface: AppColors.surface,
        primary: AppColors.buy,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerColor: AppColors.divider,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
