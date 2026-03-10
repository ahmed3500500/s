import 'dart:math';

import '../core/config/app_defaults.dart';
import '../core/constants/app_enums.dart';
import '../core/utils/number_utils.dart';
import '../data/models.dart';

class SignalTrackingUpdate {
  final List<RecommendationModel> active;
  final List<RecommendationModel> closed;

  const SignalTrackingUpdate({required this.active, required this.closed});
}

class SignalTrackingEngine {
  const SignalTrackingEngine();

  SignalTrackingUpdate update({
    required List<RecommendationModel> currentSignals,
    required Map<String, double> latestPricesBySymbol,
    DateTime? now,
  }) {
    final tNow = now ?? DateTime.now();
    final nextActive = <RecommendationModel>[];
    final closed = <RecommendationModel>[];

    for (final sig in currentSignals) {
      if (sig.action != RecommendationAction.buy) continue;

      final price = latestPricesBySymbol[sig.symbol];
      if (price == null || price <= 0) {
        nextActive.add(sig);
        continue;
      }

      final expiryAt = sig.createdAt.add(Duration(minutes: _expiryMinutes(sig.timeframe)));
      if (tNow.isAfter(expiryAt)) {
        closed.add(
          _close(
            sig,
            price: price,
            closedAt: tNow,
            status: SignalStatus.expired,
            finalOutcome: FinalOutcome.expired,
          ),
        );
        continue;
      }

      final tp1Reached = sig.tp1HitAt != null || sig.status == SignalStatus.tp1Hit;
      final effectiveStopLoss = tp1Reached ? max(sig.stopLoss, sig.entry) : sig.stopLoss;
      if (price <= effectiveStopLoss && effectiveStopLoss > 0) {
        closed.add(
          _close(
            sig,
            price: price,
            closedAt: tNow,
            status: SignalStatus.stopLossHit,
            finalOutcome: tp1Reached ? FinalOutcome.partialWin : FinalOutcome.loss,
            slHitAt: tNow,
          ),
        );
        continue;
      }

      if (price >= sig.takeProfit2 && sig.takeProfit2 > 0) {
        closed.add(
          _close(
            sig,
            price: price,
            closedAt: tNow,
            status: SignalStatus.tp2Hit,
            finalOutcome: FinalOutcome.fullWin,
          ),
        );
        continue;
      }

      if (price >= sig.takeProfit1 && sig.takeProfit1 > 0) {
        nextActive.add(
          sig.copyWith(
            status: SignalStatus.tp1Hit,
            currentPrice: price,
            tp1HitAt: sig.tp1HitAt ?? tNow,
            result: SignalStatus.tp1Hit.name,
          ),
        );
        continue;
      }

      nextActive.add(sig.copyWith(currentPrice: price));
    }

    return SignalTrackingUpdate(active: nextActive, closed: closed);
  }

  int _expiryMinutes(String timeframe) {
    return switch (timeframe) {
      '15m' => 120,
      '1h' => 240,
      '4h' => 480,
      _ => AppDefaults.signalExpiryMinutes,
    };
  }

  RecommendationModel _close(
    RecommendationModel sig, {
    required double price,
    required DateTime closedAt,
    required SignalStatus status,
    required FinalOutcome finalOutcome,
    DateTime? slHitAt,
  }) {
    final pnl = sig.entry <= 0 ? 0.0 : ((price - sig.entry) / sig.entry) * 100.0;
    final durationMinutes = closedAt.difference(sig.createdAt).inMinutes;
    return RecommendationModel(
      id: '${sig.symbol}-${sig.timeframe}-${sig.createdAt.microsecondsSinceEpoch}',
      dedupeKey: sig.dedupeKey,
      symbol: sig.symbol,
      action: sig.action,
      confidence: sig.confidence,
      currentPrice: price,
      entry: sig.entry,
      stopLoss: sig.stopLoss,
      takeProfit1: sig.takeProfit1,
      takeProfit2: sig.takeProfit2,
      reason: sig.reason,
      createdAt: sig.createdAt,
      closedAt: closedAt,
      tp1HitAt: sig.tp1HitAt,
      tp2HitAt: status == SignalStatus.tp2Hit ? closedAt : sig.tp2HitAt,
      slHitAt: slHitAt ?? sig.slHitAt,
      closedPrice: price,
      pnlPct: NumberUtils.clampDouble(pnl, -100, 1000),
      durationMinutes: durationMinutes < 0 ? 0 : durationMinutes,
      result: finalOutcome.name,
      finalOutcome: finalOutcome,
      status: status,
      timeframe: sig.timeframe,
      indicators: sig.indicators,
      change24h: sig.change24h,
      volume24h: sig.volume24h,
      marketMode: sig.marketMode,
      riskModeAtOpen: sig.riskModeAtOpen,
    );
  }
}
