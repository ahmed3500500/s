class ApiEndpoints {
  static const baseUrl = 'https://api.binance.com';

  static String ticker24h(String symbol) => '$baseUrl/api/v3/ticker/24hr?symbol=$symbol';

  static String klines({
    required String symbol,
    required String interval,
    required int limit,
  }) {
    return '$baseUrl/api/v3/klines?symbol=$symbol&interval=$interval&limit=$limit';
  }
}
