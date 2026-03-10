import 'dart:math';

import '../core/constants/app_enums.dart';
import '../core/utils/number_utils.dart';
import '../data/models.dart';
import 'indicator_engine.dart';

class ScoreResult {
  final int score;
  final List<String> reasons;

  const ScoreResult({required this.score, required this.reasons});
}

class ScoringEngine {
  final IndicatorEngine _indicators;

  ScoringEngine(this._indicators);

  ScoreResult score({
    required CoinModel coin,
    required List<CandleModel> candles15m,
    required List<CandleModel> candles1h,
    required List<CandleModel> candles4h,
    required RiskMode riskMode,
    required MarketMode marketMode,
  }) {
    final reasons = <String>[];

    final ind15m = _indicators.compute(candles15m);
    final price = coin.price;
    final atrPct = _indicators.atrPercent(candles15m);

    var trendPoints = 0;
    if (price > ind15m.ema21) {
      trendPoints += 5;
      reasons.add('السعر فوق EMA21');
    }
    if (price > ind15m.ema50) {
      trendPoints += 5;
      reasons.add('السعر فوق EMA50');
    }
    if (ind15m.ema21 > ind15m.ema50) {
      trendPoints += 5;
      reasons.add('EMA21 أعلى من EMA50');
    }
    if (_indicators.isTrendUp(candles1h)) {
      trendPoints += 5;
      reasons.add('اتجاه 1H صاعد');
    }
    if (_indicators.isTrendUp(candles4h)) {
      trendPoints += 5;
      reasons.add('اتجاه 4H صاعد');
    }
    final trend = NumberUtils.clampDouble(trendPoints.toDouble(), 0, 25).toInt();

    var momentumPoints = 0;
    if (ind15m.rsi >= 50 && ind15m.rsi <= 65) {
      momentumPoints += 8;
      reasons.add('RSI ضمن نطاق صحي');
    } else if (ind15m.rsi > 70) {
      reasons.add('RSI في تشبع شرائي');
    } else if (ind15m.rsi < 35) {
      reasons.add('RSI ضعيف');
    }
    if (ind15m.macd > ind15m.macdSignal) {
      momentumPoints += 7;
      reasons.add('MACD إيجابي');
    }
    if (ind15m.momentum > 0) {
      momentumPoints += 5;
      reasons.add('الزخم إيجابي');
    }
    final momentum = NumberUtils.clampDouble(momentumPoints.toDouble(), 0, 20).toInt();

    final volume = _volumeScore(
      volumeRatio: ind15m.volumeRatio,
      quoteVolume24h: coin.volume,
      reasons: reasons,
    );

    final risk = _riskScore(
      candles: candles15m,
      atrPct: atrPct,
      quoteVolume24h: coin.volume,
      reasons: reasons,
    );

    var confirmPoints = 0;
    final tfAligned = _indicators.isTrendUp(candles1h) && _indicators.isTrendUp(candles4h);
    if (tfAligned) {
      confirmPoints += 8;
    }
    final tooCloseToResistance = _isCloseToResistance(candles15m, price: price);
    if (tooCloseToResistance) {
      reasons.add('قريب من مقاومة');
    } else {
      confirmPoints += 4;
    }
    if (_isNearSupport(candles15m, price: price)) {
      confirmPoints += 3;
      reasons.add('قريب من دعم');
    }
    if (_conflicts(ind15m)) {
      reasons.add('تضارب مؤشرات');
    } else {
      confirmPoints += 3;
    }
    final confirm = NumberUtils.clampDouble(confirmPoints.toDouble(), 0, 15).toInt();

    final weights = _weightsForMarket(marketMode);
    var total = _weightedTotal(
      trend: trend,
      momentum: momentum,
      volume: volume,
      risk: risk,
      confirm: confirm,
      weights: weights,
    );

    total = _adjustForRiskMode(total, riskMode);
    total = _applyHardFilters(
      total: total,
      coin: coin,
      candles15m: candles15m,
      atr: ind15m.atr,
      marketMode: marketMode,
      reasons: reasons,
    );

    return ScoreResult(score: total, reasons: reasons);
  }

  int _adjustForRiskMode(int score, RiskMode mode) {
    switch (mode) {
      case RiskMode.conservative:
        return NumberUtils.clampDouble((score * 0.92), 0, 100).toInt();
      case RiskMode.balanced:
        return NumberUtils.clampDouble(score.toDouble(), 0, 100).toInt();
      case RiskMode.aggressive:
        return NumberUtils.clampDouble((score * 1.05), 0, 100).toInt();
    }
  }

  ({int trend, int momentum, int volume, int risk, int confirm}) _weightsForMarket(MarketMode mode) {
    switch (mode) {
      case MarketMode.bullish:
        return (trend: 30, momentum: 25, volume: 20, risk: 10, confirm: 15);
      case MarketMode.sideways:
        return (trend: 15, momentum: 10, volume: 15, risk: 35, confirm: 25);
      case MarketMode.volatile:
        return (trend: 20, momentum: 15, volume: 15, risk: 30, confirm: 20);
      case MarketMode.bearish:
        return (trend: 20, momentum: 15, volume: 15, risk: 30, confirm: 20);
      case MarketMode.neutral:
        return (trend: 25, momentum: 20, volume: 20, risk: 20, confirm: 15);
      case MarketMode.weakLiquidity:
        return (trend: 15, momentum: 10, volume: 20, risk: 35, confirm: 20);
    }
  }

  int _weightedTotal({
    required int trend,
    required int momentum,
    required int volume,
    required int risk,
    required int confirm,
    required ({int trend, int momentum, int volume, int risk, int confirm}) weights,
  }) {
    final t = trend / 25.0;
    final m = momentum / 20.0;
    final v = volume / 20.0;
    final r = risk / 20.0;
    final c = confirm / 15.0;
    final sum = t * weights.trend + m * weights.momentum + v * weights.volume + r * weights.risk + c * weights.confirm;
    return NumberUtils.clampDouble(sum, 0, 100).toInt();
  }

  int _volumeScore({
    required double volumeRatio,
    required double quoteVolume24h,
    required List<String> reasons,
  }) {
    var points = 0;
    if (volumeRatio >= 1.8) {
      points += 12;
      reasons.add('حجم ممتاز (1.8x+)');
    } else if (volumeRatio >= 1.3) {
      points += 9;
      reasons.add('حجم جيد (1.3x+)');
    } else if (volumeRatio >= 1.0) {
      points += 6;
      reasons.add('حجم متوسط (1.0x+)');
    } else {
      reasons.add('حجم ضعيف (< 1.0x)');
    }

    const strongQuoteVolume24h = 8000000.0;
    const minQuoteVolume24h = 2000000.0;
    if (quoteVolume24h >= strongQuoteVolume24h) {
      points += 8;
      reasons.add('سيولة 24H قوية');
    } else if (quoteVolume24h >= minQuoteVolume24h) {
      points += 4;
      reasons.add('سيولة 24H مقبولة');
    } else if (quoteVolume24h > 0) {
      reasons.add('سيولة 24H ضعيفة');
    } else {
      reasons.add('سيولة 24H غير متاحة');
    }

    return NumberUtils.clampDouble(points.toDouble(), 0, 20).toInt();
  }

  int _riskScore({
    required List<CandleModel> candles,
    required double atrPct,
    required double quoteVolume24h,
    required List<String> reasons,
  }) {
    var points = 0;
    if (atrPct > 0.004 && atrPct < 0.035) {
      points += 6;
    } else {
      reasons.add('ATR غير مناسب');
    }
    if (!_isChaotic(candles)) {
      points += 6;
    } else {
      reasons.add('سوق متذبذب جدًا');
    }
    if (!_hasAbnormalWicks(candles)) {
      points += 4;
    } else {
      reasons.add('ذيول شموع عالية');
    }
    if (quoteVolume24h >= 5000000) {
      points += 4;
    }
    return NumberUtils.clampDouble(points.toDouble(), 0, 20).toInt();
  }

  int _applyHardFilters({
    required int total,
    required CoinModel coin,
    required List<CandleModel> candles15m,
    required double atr,
    required MarketMode marketMode,
    required List<String> reasons,
  }) {
    var out = total;

    if (marketMode == MarketMode.bearish) {
      out = (out * 0.85).toInt();
      reasons.add('السوق العام هابط');
    } else if (marketMode == MarketMode.volatile) {
      out = (out * 0.90).toInt();
      reasons.add('السوق العام متذبذب');
    } else if (marketMode == MarketMode.sideways) {
      out = (out * 0.93).toInt();
      reasons.add('السوق العام عرضي');
    } else if (marketMode == MarketMode.weakLiquidity) {
      out = (out * 0.90).toInt();
      reasons.add('السيولة العامة ضعيفة');
    }

    if (_isSideways(candles15m)) {
      out = (out * 0.90).toInt();
      reasons.add('حركة عرضية مزعجة');
    }

    if (coin.volume > 0 && coin.volume < 1500000) {
      out = (out - 18).clamp(0, 100);
      reasons.add('سيولة ضعيفة جدًا');
    }

    if (_isLateEntry(candles15m, price: coin.price)) {
      out = (out - 10).clamp(0, 100);
      reasons.add('دخول متأخر');
    }

    if (_isOverextendedCandle(candles15m, atr: atr)) {
      out = (out - 10).clamp(0, 100);
      reasons.add('شمعة ممتدة');
    }

    if (_isCloseToResistance(candles15m, price: coin.price)) {
      out = (out - 12).clamp(0, 100);
    }

    return out;
  }

  bool _conflicts(IndicatorModel ind) {
    final bearishMacd = ind.macd < ind.macdSignal;
    final overbought = ind.rsi > 72;
    return bearishMacd && overbought;
  }

  bool _isSideways(List<CandleModel> candles) {
    if (candles.length < 80) return true;
    final recent = candles.sublist(candles.length - 60);
    final closes = recent.map((e) => e.close).toList(growable: false);
    final high = closes.reduce((a, b) => a > b ? a : b);
    final low = closes.reduce((a, b) => a < b ? a : b);
    final last = closes.last;
    if (last <= 0) return true;
    final rangePct = (high - low).abs() / last;
    final indNow = _indicators.compute(recent);
    final indEarly = _indicators.compute(candles.sublist(candles.length - 80, candles.length - 20));
    final slopePct = ((indNow.ema21 - indEarly.ema21).abs()) / last;
    final emaGapPct = indNow.ema50 <= 0 ? 1.0 : ((indNow.ema21 - indNow.ema50).abs()) / indNow.ema50;
    final rsiMid = (indNow.rsi - 50).abs();
    return rangePct < 0.018 && slopePct < 0.006 && emaGapPct < 0.004 && rsiMid < 7;
  }

  bool _isLateEntry(List<CandleModel> candles, {required double price}) {
    if (candles.length < 80) return true;
    final recent = candles.sublist(candles.length - 60);
    final closes = recent.map((e) => e.close).toList(growable: false);
    final ema21 = _indicators.compute(recent).ema21;
    if (ema21 <= 0) return true;
    final overEma = (price - ema21) / ema21;
    final high = closes.reduce((a, b) => a > b ? a : b);
    final pullbackFromHigh = (high - price) / price;
    final closeToRes = _isCloseToResistance(candles, price: price);
    return (overEma > 0.03 && pullbackFromHigh < 0.01) || (overEma > 0.025 && closeToRes);
  }

  bool _isOverextendedCandle(List<CandleModel> candles, {required double atr}) {
    if (candles.length < 10 || atr <= 0) return false;
    final last = candles.last;
    final range = (last.high - last.low).abs();
    return range > atr * 2.6;
  }

  bool _isCloseToResistance(List<CandleModel> candles, {required double price}) {
    if (candles.length < 60 || price <= 0) return false;
    final recent = candles.sublist(candles.length - 50);
    final highs = recent.map((e) => e.high).toList(growable: false);
    final high = highs.reduce((a, b) => a > b ? a : b);
    final dist = (high - price) / price;
    return dist >= 0 && dist < 0.008;
  }

  bool _isNearSupport(List<CandleModel> candles, {required double price}) {
    if (candles.length < 60 || price <= 0) return false;
    final recent = candles.sublist(candles.length - 50);
    final lows = recent.map((e) => e.low).toList(growable: false);
    final low = lows.reduce((a, b) => a < b ? a : b);
    final dist = (price - low) / price;
    return dist >= 0 && dist < 0.010;
  }

  bool _isChaotic(List<CandleModel> candles) {
    if (candles.length < 40) return true;
    final returns = <double>[];
    for (var i = 1; i < candles.length; i++) {
      final prev = candles[i - 1].close;
      final curr = candles[i].close;
      if (prev <= 0) continue;
      returns.add((curr - prev).abs() / prev);
    }
    if (returns.isEmpty) return true;
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    var variance = 0.0;
    for (final r in returns) {
      variance += (r - mean) * (r - mean);
    }
    variance /= returns.length;
    final std = variance.isNaN ? 0 : sqrt(variance);
    return std > 0.02;
  }

  bool _hasAbnormalWicks(List<CandleModel> candles) {
    if (candles.length < 30) return true;
    final recent = candles.sublist(candles.length - 25);
    var abnormal = 0;
    for (final c in recent) {
      final body = (c.close - c.open).abs();
      final range = (c.high - c.low).abs();
      if (range <= 0) continue;
      final wickRatio = (range - body) / range;
      if (wickRatio > 0.75) abnormal++;
    }
    return abnormal >= 5;
  }
}
