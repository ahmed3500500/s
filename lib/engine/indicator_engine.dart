import 'dart:math';

import '../core/utils/number_utils.dart';
import '../data/models.dart';

class IndicatorEngine {
  IndicatorModel compute(List<CandleModel> candles) {
    if (candles.length < 60) {
      final lastClose = candles.isEmpty ? 0.0 : candles.last.close;
      return IndicatorModel(
        rsi: 0,
        ema9: lastClose,
        ema21: lastClose,
        ema50: lastClose,
        macd: 0,
        macdSignal: 0,
        atr: 0,
        bollingerUpper: lastClose,
        bollingerLower: lastClose,
        volumeRatio: 1,
        momentum: 0,
      );
    }

    final closes = candles.map((e) => e.close).toList(growable: false);
    final ema9 = _emaLast(closes, 9);
    final ema21 = _emaLast(closes, 21);
    final ema50 = _emaLast(closes, 50);

    final rsi = _rsi(closes, 14);
    final macd = _emaLast(closes, 12) - _emaLast(closes, 26);
    final macdSignal = _emaLast(_macdSeries(closes), 9);

    final atr = _atr(candles, 14);
    final boll = _bollinger(closes, 20, 2);
    final volumeRatio = _volumeRatio(candles, 20);
    final momentum = closes.last - closes[closes.length - 10];

    return IndicatorModel(
      rsi: rsi,
      ema9: ema9,
      ema21: ema21,
      ema50: ema50,
      macd: macd,
      macdSignal: macdSignal,
      atr: atr,
      bollingerUpper: boll.$1,
      bollingerLower: boll.$2,
      volumeRatio: volumeRatio,
      momentum: momentum,
    );
  }

  bool isTrendUp(List<CandleModel> candles) {
    if (candles.length < 60) return false;
    final closes = candles.map((e) => e.close).toList(growable: false);
    final ema = _emaSeries(closes, 21);
    final end = ema.last;
    final start = ema[ema.length - 12];
    return end > start;
  }

  double atrPercent(List<CandleModel> candles) {
    if (candles.length < 20) return 0;
    final atr = _atr(candles, 14);
    final price = candles.last.close;
    if (price <= 0) return 0;
    return atr / price;
  }

  double _emaLast(List<double> values, int period) {
    final series = _emaSeries(values, period);
    return series.isEmpty ? 0 : series.last;
  }

  List<double> _emaSeries(List<double> values, int period) {
    if (values.isEmpty) return const [];
    final k = 2 / (period + 1);
    final out = List<double>.filled(values.length, 0);
    out[0] = values[0];
    for (var i = 1; i < values.length; i++) {
      out[i] = values[i] * k + out[i - 1] * (1 - k);
    }
    return out;
  }

  double _rsi(List<double> closes, int period) {
    if (closes.length < period + 2) return 0;
    var gains = 0.0;
    var losses = 0.0;
    for (var i = closes.length - period - 1; i < closes.length; i++) {
      final diff = closes[i] - closes[i - 1];
      if (diff >= 0) {
        gains += diff;
      } else {
        losses += -diff;
      }
    }
    if (losses == 0) return 100;
    final rs = gains / losses;
    final rsi = 100 - (100 / (1 + rs));
    return NumberUtils.clampDouble(rsi, 0, 100);
  }

  List<double> _macdSeries(List<double> closes) {
    final ema12 = _emaSeries(closes, 12);
    final ema26 = _emaSeries(closes, 26);
    final out = List<double>.filled(closes.length, 0);
    for (var i = 0; i < closes.length; i++) {
      out[i] = ema12[i] - ema26[i];
    }
    return out;
  }

  double _atr(List<CandleModel> candles, int period) {
    if (candles.length < period + 2) return 0;
    final trs = <double>[];
    for (var i = 1; i < candles.length; i++) {
      final curr = candles[i];
      final prev = candles[i - 1];
      final tr = max(
        curr.high - curr.low,
        max((curr.high - prev.close).abs(), (curr.low - prev.close).abs()),
      );
      trs.add(tr);
    }
    final start = max(0, trs.length - period);
    final slice = trs.sublist(start);
    final sum = slice.fold<double>(0, (a, b) => a + b);
    return sum / slice.length;
  }

  (double, double) _bollinger(List<double> values, int period, double k) {
    if (values.length < period) {
      final last = values.isEmpty ? 0.0 : values.last;
      return (last, last);
    }
    final slice = values.sublist(values.length - period);
    final mean = slice.reduce((a, b) => a + b) / slice.length;
    var variance = 0.0;
    for (final v in slice) {
      variance += pow(v - mean, 2).toDouble();
    }
    variance /= slice.length;
    final std = sqrt(variance);
    return (mean + k * std, mean - k * std);
  }

  double _volumeRatio(List<CandleModel> candles, int period) {
    if (candles.length < period + 2) return 1;
    final volumes = candles.map((e) => e.volume).toList(growable: false);
    final slice = volumes.sublist(volumes.length - period - 1, volumes.length - 1);
    final avg = slice.reduce((a, b) => a + b) / slice.length;
    if (avg <= 0) return 1;
    final last = volumes.last;
    return last / avg;
  }
}
