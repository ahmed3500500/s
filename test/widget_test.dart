import 'package:flutter_test/flutter_test.dart';

import 'package:smart_crypto_signals/core/constants/app_enums.dart';
import 'package:smart_crypto_signals/data/models.dart';
import 'package:smart_crypto_signals/engine/indicator_engine.dart';
import 'package:smart_crypto_signals/engine/recommendation_engine.dart';

void main() {
  test('يولد توصية قوية في اتجاه صاعد', () {
    final candles = _buildUptrendCandles(length: 120, start: 100);
    final engine = RecommendationEngine(IndicatorEngine());

    final coin = CoinModel(
      symbol: 'BTCUSDT',
      price: candles.last.close,
      change24h: 2.5,
      volume: 12000000,
      high24h: candles.map((c) => c.high).reduce((a, b) => a > b ? a : b),
      low24h: candles.map((c) => c.low).reduce((a, b) => a < b ? a : b),
    );

    final rec = engine.generate(
      coin: coin,
      candles15m: candles,
      candles1h: candles,
      candles4h: candles,
      riskMode: RiskMode.balanced,
      minConfidence: 70,
      timeframe: '15m',
      marketMode: MarketMode.bullish,
    );

    expect(rec.confidence, inInclusiveRange(0, 100));
    expect(rec.confidence, greaterThanOrEqualTo(70));
    expect(rec.action, isNot(RecommendationAction.avoid));

    expect(rec.stopLoss, lessThan(rec.entry));
    expect(rec.takeProfit1, greaterThan(rec.entry));
    expect(rec.takeProfit2, greaterThan(rec.takeProfit1));
  });
}

List<CandleModel> _buildUptrendCandles({required int length, required double start}) {
  final out = <CandleModel>[];
  var close = start;
  for (var i = 0; i < length; i++) {
    final downMove = i % 6 == 0;
    final delta = downMove ? -0.12 : 0.28;
    final nextClose = close + delta;

    final open = downMove ? nextClose + 0.12 : nextClose - 0.12;
    final baseHigh = (open > nextClose ? open : nextClose);
    final baseLow = (open < nextClose ? open : nextClose);
    final high = baseHigh + 0.06;
    final low = baseLow - 0.06;

    final volume = i == length - 1 ? 4200.0 : 1000.0;

    out.add(
      CandleModel(
        openTimeMs: i * 60000,
        open: open,
        high: high,
        low: low,
        close: nextClose,
        volume: volume,
        closeTimeMs: (i + 1) * 60000,
      ),
    );

    close = nextClose;
  }

  if (out.isNotEmpty) {
    final last = out.last;
    out[out.length - 1] = CandleModel(
      openTimeMs: last.openTimeMs,
      open: last.open,
      high: last.close * 1.02,
      low: last.low,
      close: last.close,
      volume: last.volume,
      closeTimeMs: last.closeTimeMs,
    );
  }

  return out;
}
