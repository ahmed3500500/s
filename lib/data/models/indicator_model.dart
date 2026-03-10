import '../../core/utils/number_utils.dart';

class IndicatorModel {
  final double rsi;
  final double ema9;
  final double ema21;
  final double ema50;
  final double macd;
  final double macdSignal;
  final double atr;
  final double bollingerUpper;
  final double bollingerLower;
  final double volumeRatio;
  final double momentum;

  const IndicatorModel({
    required this.rsi,
    required this.ema9,
    required this.ema21,
    required this.ema50,
    required this.macd,
    required this.macdSignal,
    required this.atr,
    required this.bollingerUpper,
    required this.bollingerLower,
    required this.volumeRatio,
    required this.momentum,
  });

  Map<String, dynamic> toJson() => {
        'rsi': rsi,
        'ema9': ema9,
        'ema21': ema21,
        'ema50': ema50,
        'macd': macd,
        'macdSignal': macdSignal,
        'atr': atr,
        'bollingerUpper': bollingerUpper,
        'bollingerLower': bollingerLower,
        'volumeRatio': volumeRatio,
        'momentum': momentum,
      };

  factory IndicatorModel.fromJson(Map<String, dynamic> json) {
    return IndicatorModel(
      rsi: NumberUtils.safeParseDouble(json['rsi']),
      ema9: NumberUtils.safeParseDouble(json['ema9']),
      ema21: NumberUtils.safeParseDouble(json['ema21']),
      ema50: NumberUtils.safeParseDouble(json['ema50']),
      macd: NumberUtils.safeParseDouble(json['macd']),
      macdSignal: NumberUtils.safeParseDouble(json['macdSignal']),
      atr: NumberUtils.safeParseDouble(json['atr']),
      bollingerUpper: NumberUtils.safeParseDouble(json['bollingerUpper']),
      bollingerLower: NumberUtils.safeParseDouble(json['bollingerLower']),
      volumeRatio: NumberUtils.safeParseDouble(json['volumeRatio']),
      momentum: NumberUtils.safeParseDouble(json['momentum']),
    );
  }
}

