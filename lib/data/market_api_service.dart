import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_endpoints.dart';
import '../core/config/app_config.dart';
import '../core/utils/logger.dart';
import 'models.dart';

class MarketApiService {
  final http.Client _client;

  MarketApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<CoinModel> fetchTicker24h(String symbol) async {
    final uri = Uri.parse(ApiEndpoints.ticker24h(symbol));
    final jsonMap = await _getJsonMap(uri, opName: 'ticker24h', symbol: symbol);
    return CoinModel.fromBinance24h(jsonMap);
  }

  Future<List<CandleModel>> fetchCandles({
    required String symbol,
    required String interval,
    required int limit,
  }) async {
    final uri = Uri.parse(
      ApiEndpoints.klines(symbol: symbol, interval: interval, limit: limit),
    );
    final rows = await _getJsonList(uri, opName: 'klines', symbol: symbol, extra: 'tf=$interval');
    return rows.map((e) => CandleModel.fromBinanceKline(e as List)).toList();
  }

  Future<Map<String, dynamic>> _getJsonMap(
    Uri uri, {
    required String opName,
    required String symbol,
  }) async {
    final body = await _get(uri, opName: opName, symbol: symbol);
    final decoded = json.decode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected JSON (map) for $opName:$symbol');
  }

  Future<List<dynamic>> _getJsonList(
    Uri uri, {
    required String opName,
    required String symbol,
    String? extra,
  }) async {
    final body = await _get(uri, opName: opName, symbol: symbol, extra: extra);
    final decoded = json.decode(body);
    if (decoded is List<dynamic>) return decoded;
    throw Exception('Unexpected JSON (list) for $opName:$symbol');
  }

  Future<String> _get(
    Uri uri, {
    required String opName,
    required String symbol,
    String? extra,
  }) async {
    Object? lastError;
    StackTrace? lastStack;
    for (var attempt = 0; attempt <= AppConfig.requestMaxRetries; attempt++) {
      try {
        final res = await _client
            .get(uri)
            .timeout(const Duration(seconds: AppConfig.requestTimeoutSeconds));
        if (res.statusCode == 200) return res.body;
        lastError = Exception('$opName request failed (${res.statusCode})');
      } catch (e, st) {
        lastError = e;
        lastStack = st;
      }

      if (attempt < AppConfig.requestMaxRetries) {
        final delayMs = 300 * (attempt + 1);
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }
    }

    AppLogger.error(
      'API failed: $opName $symbol${extra == null ? '' : ' $extra'}',
      name: 'api',
      error: lastError,
      stackTrace: lastStack,
    );
    throw lastError ?? Exception('Unknown API error: $opName:$symbol');
  }
}
