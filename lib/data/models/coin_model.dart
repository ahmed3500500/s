import '../../core/utils/number_utils.dart';

class CoinModel {
  final String symbol;
  final double price;
  final double change24h;
  final double volume;
  final double high24h;
  final double low24h;

  const CoinModel({
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.volume,
    required this.high24h,
    required this.low24h,
  });

  factory CoinModel.fromBinance24h(Map<String, dynamic> json) {
    return CoinModel(
      symbol: json['symbol']?.toString() ?? '',
      price: NumberUtils.safeParseDouble(json['lastPrice']),
      change24h: NumberUtils.safeParseDouble(json['priceChangePercent']),
      volume: NumberUtils.safeParseDouble(json['quoteVolume']),
      high24h: NumberUtils.safeParseDouble(json['highPrice']),
      low24h: NumberUtils.safeParseDouble(json['lowPrice']),
    );
  }

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'price': price,
        'change24h': change24h,
        'volume': volume,
        'high24h': high24h,
        'low24h': low24h,
      };

  factory CoinModel.fromJson(Map<String, dynamic> json) {
    return CoinModel(
      symbol: json['symbol']?.toString() ?? '',
      price: NumberUtils.safeParseDouble(json['price']),
      change24h: NumberUtils.safeParseDouble(json['change24h']),
      volume: NumberUtils.safeParseDouble(json['volume']),
      high24h: NumberUtils.safeParseDouble(json['high24h']),
      low24h: NumberUtils.safeParseDouble(json['low24h']),
    );
  }
}

