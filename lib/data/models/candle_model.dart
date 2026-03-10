import '../../core/utils/number_utils.dart';

class CandleModel {
  final int openTimeMs;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final int closeTimeMs;

  const CandleModel({
    required this.openTimeMs,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.closeTimeMs,
  });

  factory CandleModel.fromBinanceKline(List<dynamic> row) {
    return CandleModel(
      openTimeMs: NumberUtils.safeParseInt(row[0]),
      open: NumberUtils.safeParseDouble(row[1]),
      high: NumberUtils.safeParseDouble(row[2]),
      low: NumberUtils.safeParseDouble(row[3]),
      close: NumberUtils.safeParseDouble(row[4]),
      volume: NumberUtils.safeParseDouble(row[5]),
      closeTimeMs: NumberUtils.safeParseInt(row[6]),
    );
  }

  Map<String, dynamic> toJson() => {
        'openTimeMs': openTimeMs,
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'volume': volume,
        'closeTimeMs': closeTimeMs,
      };

  factory CandleModel.fromJson(Map<String, dynamic> json) {
    return CandleModel(
      openTimeMs: NumberUtils.safeParseInt(json['openTimeMs']),
      open: NumberUtils.safeParseDouble(json['open']),
      high: NumberUtils.safeParseDouble(json['high']),
      low: NumberUtils.safeParseDouble(json['low']),
      close: NumberUtils.safeParseDouble(json['close']),
      volume: NumberUtils.safeParseDouble(json['volume']),
      closeTimeMs: NumberUtils.safeParseInt(json['closeTimeMs']),
    );
  }
}

