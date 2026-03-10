import 'dart:math';

import '../core/constants/app_enums.dart';
import '../core/utils/number_utils.dart';
import '../data/models.dart';
import 'indicator_engine.dart';
import 'scoring_engine.dart';

class RecommendationEngine {
  final IndicatorEngine _indicators;
  final ScoringEngine _scoring;

  RecommendationEngine(this._indicators) : _scoring = ScoringEngine(_indicators);

  RecommendationModel generate({
    required CoinModel coin,
    required List<CandleModel> candles15m,
    required List<CandleModel> candles1h,
    required List<CandleModel> candles4h,
    required RiskMode riskMode,
    required int minConfidence,
    required String timeframe,
    required MarketMode marketMode,
  }) {
    if (candles15m.length < 60 || candles1h.length < 60 || candles4h.length < 60 || coin.price <= 0) {
      final now = DateTime.now();
      const action = RecommendationAction.avoid;
      final dedupeKey = '${coin.symbol}-$timeframe-${action.name}';
      return RecommendationModel(
        id: dedupeKey,
        dedupeKey: dedupeKey,
        symbol: coin.symbol,
        action: action,
        confidence: 0,
        currentPrice: coin.price,
        entry: coin.price,
        stopLoss: coin.price,
        takeProfit1: coin.price,
        takeProfit2: coin.price,
        reason: const ['بيانات غير كافية للتحليل'],
        createdAt: now,
        closedAt: null,
        closedPrice: null,
        pnlPct: null,
        status: SignalStatus.cancelled,
        timeframe: timeframe,
        indicators: _indicators.compute(candles15m),
        change24h: coin.change24h,
        volume24h: coin.volume,
        marketMode: marketMode,
        riskModeAtOpen: riskMode,
      );
    }

    final indicators = _indicators.compute(candles15m);
    final scored = _scoring.score(
      coin: coin,
      candles15m: candles15m,
      candles1h: candles1h,
      candles4h: candles4h,
      riskMode: riskMode,
      marketMode: marketMode,
    );

    final rawAction = _actionFromScore(scored.score, minConfidence: minConfidence);
    final action = _applyConfidenceDiscipline(
      action: rawAction,
      score: scored.score,
      coin: coin,
      candles15m: candles15m,
      candles1h: candles1h,
      candles4h: candles4h,
      indicators15m: indicators,
      marketMode: marketMode,
    );
    final levels = _levels(
      price: coin.price,
      atr: indicators.atr,
      riskMode: riskMode,
    );

    final dedupeKey = '${coin.symbol}-$timeframe-${action.name}';
    final id = '$dedupeKey-${DateTime.now().microsecondsSinceEpoch}';
    return RecommendationModel(
      id: id,
      dedupeKey: dedupeKey,
      symbol: coin.symbol,
      action: action,
      confidence: scored.score,
      currentPrice: coin.price,
      entry: levels.entry,
      stopLoss: levels.stopLoss,
      takeProfit1: levels.tp1,
      takeProfit2: levels.tp2,
      reason: _dedupeReasons(scored.reasons, max: 6),
      createdAt: DateTime.now(),
      closedAt: null,
      closedPrice: null,
      pnlPct: null,
      status: action == RecommendationAction.buy ? SignalStatus.active : SignalStatus.cancelled,
      timeframe: timeframe,
      indicators: indicators,
      change24h: coin.change24h,
      volume24h: coin.volume,
      marketMode: marketMode,
      riskModeAtOpen: riskMode,
    );
  }

  RecommendationAction _actionFromScore(int score, {required int minConfidence}) {
    if (score >= max(85, minConfidence)) return RecommendationAction.buy;
    if (score >= max(70, minConfidence - 10)) return RecommendationAction.watch;
    return RecommendationAction.avoid;
  }

  RecommendationAction _applyConfidenceDiscipline({
    required RecommendationAction action,
    required int score,
    required CoinModel coin,
    required List<CandleModel> candles15m,
    required List<CandleModel> candles1h,
    required List<CandleModel> candles4h,
    required IndicatorModel indicators15m,
    required MarketMode marketMode,
  }) {
    if (action != RecommendationAction.buy) return action;

    if (marketMode == MarketMode.bearish) return RecommendationAction.watch;
    if (marketMode == MarketMode.sideways) return RecommendationAction.watch;
    if (marketMode == MarketMode.weakLiquidity) return RecommendationAction.watch;

    final atrPct = coin.price <= 0 ? 0.0 : indicators15m.atr / coin.price;
    if (atrPct <= 0.004 || atrPct >= 0.035) return RecommendationAction.watch;

    if (coin.volume > 0 && coin.volume < 1500000) return RecommendationAction.watch;
    if (indicators15m.volumeRatio < 1.0) return RecommendationAction.watch;

    if (_isSidewaysMarket(candles15m, indicators15m: indicators15m)) return RecommendationAction.watch;
    if (_isLateEntry(candles15m, price: coin.price, ema21: indicators15m.ema21)) return RecommendationAction.watch;
    if (_isCloseToResistance(candles15m, price: coin.price)) return RecommendationAction.watch;

    if (score < 85) return RecommendationAction.watch;

    final tfAligned = _indicators.isTrendUp(candles1h) && _indicators.isTrendUp(candles4h);
    if (!tfAligned) return RecommendationAction.watch;

    return RecommendationAction.buy;
  }

  bool _isSidewaysMarket(List<CandleModel> candles, {required IndicatorModel indicators15m}) {
    if (candles.length < 80) return true;
    final recent = candles.sublist(candles.length - 60);
    final closes = recent.map((e) => e.close).toList(growable: false);
    final high = closes.reduce((a, b) => a > b ? a : b);
    final low = closes.reduce((a, b) => a < b ? a : b);
    final last = closes.last;
    if (last <= 0) return true;
    final rangePct = (high - low).abs() / last;
    final emaGapPct = indicators15m.ema50 <= 0 ? 1.0 : ((indicators15m.ema21 - indicators15m.ema50).abs()) / indicators15m.ema50;
    final rsiMid = (indicators15m.rsi - 50).abs();
    return rangePct < 0.018 && emaGapPct < 0.004 && rsiMid < 7;
  }

  bool _isLateEntry(List<CandleModel> candles, {required double price, required double ema21}) {
    if (candles.length < 80 || ema21 <= 0) return true;
    final recent = candles.sublist(candles.length - 60);
    final closes = recent.map((e) => e.close).toList(growable: false);
    final overEma = (price - ema21) / ema21;
    final high = closes.reduce((a, b) => a > b ? a : b);
    final pullbackFromHigh = (high - price) / price;
    return (overEma > 0.03 && pullbackFromHigh < 0.01) || (overEma > 0.025 && _isCloseToResistance(candles, price: price));
  }

  bool _isCloseToResistance(List<CandleModel> candles, {required double price}) {
    if (candles.length < 60 || price <= 0) return false;
    final recent = candles.sublist(candles.length - 50);
    final highs = recent.map((e) => e.high).toList(growable: false);
    final high = highs.reduce((a, b) => a > b ? a : b);
    final dist = (high - price) / price;
    return dist >= 0 && dist < 0.008;
  }

  List<String> _dedupeReasons(List<String> reasons, {required int max}) {
    final seen = <String>{};
    final out = <String>[];
    for (final r in reasons) {
      final trimmed = r.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed)) out.add(trimmed);
      if (out.length >= max) break;
    }
    return out;
  }

  _TradeLevels _levels({
    required double price,
    required double atr,
    required RiskMode riskMode,
  }) {
    final entry = price;
    final atrPct = price <= 0 ? 0.0 : atr / price;
    final slPct = switch (riskMode) {
      RiskMode.conservative => max(0.012, atrPct * 1.8),
      RiskMode.balanced => max(0.010, atrPct * 1.6),
      RiskMode.aggressive => max(0.008, atrPct * 1.4),
    };

    final tp1Pct = switch (riskMode) {
      RiskMode.conservative => 0.018,
      RiskMode.balanced => 0.020,
      RiskMode.aggressive => 0.025,
    };

    final tp2Pct = switch (riskMode) {
      RiskMode.conservative => 0.035,
      RiskMode.balanced => 0.040,
      RiskMode.aggressive => 0.050,
    };

    final stopLoss = entry * (1 - NumberUtils.clampDouble(slPct, 0.005, 0.08));
    final tp1 = entry * (1 + tp1Pct);
    final tp2 = entry * (1 + tp2Pct);
    return _TradeLevels(entry: entry, stopLoss: stopLoss, tp1: tp1, tp2: tp2);
  }
}

class _TradeLevels {
  final double entry;
  final double stopLoss;
  final double tp1;
  final double tp2;

  const _TradeLevels({
    required this.entry,
    required this.stopLoss,
    required this.tp1,
    required this.tp2,
  });
}
