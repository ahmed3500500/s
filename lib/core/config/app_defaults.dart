import '../constants/app_enums.dart';

class AppDefaults {
  static const scanIntervalSeconds = 180;
  static const scanCooldownSeconds = 10;
  static const minConfidence = 70;
  static const riskMode = RiskMode.balanced;
  static const signalExpiryMinutes = 360;
  static const marketSymbols = <String>[
    'BTCUSDT',
    'ETHUSDT',
    'BNBUSDT',
    'SOLUSDT',
    'XRPUSDT',
    'ADAUSDT',
    'DOGEUSDT',
    'AVAXUSDT',
    'LINKUSDT',
    'DOTUSDT',
  ];

  static const timeframe15m = '15m';
  static const timeframe1h = '1h';
  static const timeframe4h = '4h';

  static const marketWeakLiquidityMinQuoteVolume24h = 1200000000.0;
}
