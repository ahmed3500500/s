import 'dart:math';

import '../core/config/app_defaults.dart';
import '../core/constants/app_enums.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import 'indicator_engine.dart';

class MarketModeEngine {
  final MarketRepository _market;
  final IndicatorEngine _indicators;

  MarketModeEngine(this._market, this._indicators);

  Future<MarketMode> compute() async {
    final btc = await _market.fetchCoin24h('BTCUSDT');
    final eth = await _market.fetchCoin24h('ETHUSDT');
    final btcCandles1h = await _market.fetchCandles1h('BTCUSDT');
    final ethCandles1h = await _market.fetchCandles1h('ETHUSDT');
    final btcCandles4h = await _market.fetchCandles4h('BTCUSDT');
    final ethCandles4h = await _market.fetchCandles4h('ETHUSDT');
    final btcCandles15m = await _market.fetchCandles15m('BTCUSDT');

    final btcUp1h = _indicators.isTrendUp(btcCandles1h);
    final ethUp1h = _indicators.isTrendUp(ethCandles1h);
    final btcUp4h = _indicators.isTrendUp(btcCandles4h);
    final ethUp4h = _indicators.isTrendUp(ethCandles4h);
    final btcAtrPct15m = _indicators.atrPercent(btcCandles15m);
    final btcAtrPct1h = _indicators.atrPercent(btcCandles1h);

    if (min(btc.volume, eth.volume) > 0 &&
        min(btc.volume, eth.volume) < AppDefaults.marketWeakLiquidityMinQuoteVolume24h) {
      return MarketMode.weakLiquidity;
    }

    if (max(btcAtrPct15m, btcAtrPct1h) > 0.038) return MarketMode.volatile;

    final btcInd1h = _indicators.compute(btcCandles1h);
    final ethInd1h = _indicators.compute(ethCandles1h);
    final btcInd4h = _indicators.compute(btcCandles4h);
    final ethInd4h = _indicators.compute(ethCandles4h);

    if (_isSidewaysMarket(candles: btcCandles1h, price: btc.price, indicators: btcInd1h) &&
        _isSidewaysMarket(candles: btcCandles4h, price: btc.price, indicators: btcInd4h) &&
        _isSidewaysMarket(candles: ethCandles1h, price: eth.price, indicators: ethInd1h) &&
        _isSidewaysMarket(candles: ethCandles4h, price: eth.price, indicators: ethInd4h)) {
      return MarketMode.sideways;
    }

    final btcAbove1h = btc.price > btcInd1h.ema21 && btc.price > btcInd1h.ema50;
    final ethAbove1h = eth.price > ethInd1h.ema21 && eth.price > ethInd1h.ema50;
    final btcAbove4h = btc.price > btcInd4h.ema21 && btc.price > btcInd4h.ema50;
    final ethAbove4h = eth.price > ethInd4h.ema21 && eth.price > ethInd4h.ema50;
    final rsiOk = min(min(btcInd1h.rsi, btcInd4h.rsi), min(ethInd1h.rsi, ethInd4h.rsi)) >= 45;

    if (btc.change24h >= 1 &&
        eth.change24h >= 1 &&
        btcUp1h &&
        btcUp4h &&
        ethUp1h &&
        ethUp4h &&
        btcAbove1h &&
        btcAbove4h &&
        ethAbove1h &&
        ethAbove4h &&
        rsiOk) {
      return MarketMode.bullish;
    }

    final btcBelow1h = btc.price < btcInd1h.ema21 && btc.price < btcInd1h.ema50;
    final ethBelow1h = eth.price < ethInd1h.ema21 && eth.price < ethInd1h.ema50;
    final btcBelow4h = btc.price < btcInd4h.ema21 && btc.price < btcInd4h.ema50;
    final ethBelow4h = eth.price < ethInd4h.ema21 && eth.price < ethInd4h.ema50;
    final rsiWeak = max(max(btcInd1h.rsi, btcInd4h.rsi), max(ethInd1h.rsi, ethInd4h.rsi)) <= 55;

    if (btc.change24h <= -1 &&
        eth.change24h <= -1 &&
        !btcUp1h &&
        !btcUp4h &&
        !ethUp1h &&
        !ethUp4h &&
        btcBelow1h &&
        btcBelow4h &&
        ethBelow1h &&
        ethBelow4h &&
        rsiWeak) {
      return MarketMode.bearish;
    }

    return MarketMode.neutral;
  }

  bool _isSidewaysMarket({
    required List<CandleModel> candles,
    required double price,
    required IndicatorModel indicators,
  }) {
    if (candles.length < 80 || price <= 0) return false;
    if (indicators.ema21 <= 0 || indicators.ema50 <= 0) return false;
    final recent = candles.sublist(candles.length - 60);
    var high = 0.0;
    var low = double.infinity;
    for (final c in recent) {
      if (c.high > high) high = c.high;
      if (c.low < low) low = c.low;
    }
    final rangePct = (high - low).abs() / price;
    final emaGapPct = ((indicators.ema21 - indicators.ema50).abs()) / indicators.ema50;
    final rsiMid = (indicators.rsi - 50).abs();
    final priceToEma21Pct = ((price - indicators.ema21).abs()) / indicators.ema21;
    return rangePct < 0.018 && emaGapPct < 0.004 && rsiMid < 7 && priceToEma21Pct < 0.012;
  }
}
