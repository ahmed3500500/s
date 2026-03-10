import 'dart:math';

class NumberUtils {
  static double clampDouble(double value, double minValue, double maxValue) {
    return min(maxValue, max(minValue, value));
  }

  static double safeParseDouble(Object? value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static int safeParseInt(Object? value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static String formatPercent(double fraction) {
    final pct = fraction * 100;
    return '${pct.toStringAsFixed(1)}%';
  }
}
