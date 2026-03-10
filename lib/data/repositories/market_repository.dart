import '../../core/config/app_config.dart';
import '../../core/config/app_defaults.dart';
import '../market_api_service.dart';
import '../models.dart';

class MarketRepository {
  final MarketApiService _api;

  MarketRepository(this._api);

  Future<CoinModel> fetchCoin24h(String symbol) => _api.fetchTicker24h(symbol);

  Future<List<CandleModel>> fetchCandles15m(String symbol) {
    return _api.fetchCandles(
      symbol: symbol,
      interval: AppDefaults.timeframe15m,
      limit: AppConfig.klinesLimit,
    );
  }

  Future<List<CandleModel>> fetchCandles1h(String symbol) {
    return _api.fetchCandles(
      symbol: symbol,
      interval: AppDefaults.timeframe1h,
      limit: AppConfig.klinesLimitTf1h,
    );
  }

  Future<List<CandleModel>> fetchCandles4h(String symbol) {
    return _api.fetchCandles(
      symbol: symbol,
      interval: AppDefaults.timeframe4h,
      limit: AppConfig.klinesLimitTf4h,
    );
  }
}

