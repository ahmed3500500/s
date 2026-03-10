import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../core/config/app_defaults.dart';
import '../core/constants/app_enums.dart';
import '../core/utils/logger.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../engine/indicator_engine.dart';
import '../engine/market_mode_engine.dart';
import '../engine/recommendation_engine.dart';
import '../engine/signal_tracking_engine.dart';
import 'notification_service.dart';

class ScanResult {
  final List<RecommendationModel> recommendations;
  final DateTime completedAt;
  final MarketMode marketMode;
  final bool hadConnectivity;
  final String? errorMessage;

  const ScanResult({
    required this.recommendations,
    required this.completedAt,
    required this.marketMode,
    required this.hadConnectivity,
    required this.errorMessage,
  });
}

class ScannerService {
  final MarketRepository marketRepository;
  final RecommendationRepository recommendationRepository;
  final SettingsRepository settingsRepository;
  final NotificationService notificationService;

  final IndicatorEngine _indicatorEngine = IndicatorEngine();
  late final RecommendationEngine _recommendationEngine = RecommendationEngine(_indicatorEngine);
  final SignalTrackingEngine _trackingEngine = const SignalTrackingEngine();
  late final MarketModeEngine _marketModeEngine;

  Timer? _timer;
  bool _scanInProgress = false;
  bool _taskCallbackRegistered = false;
  DateTime? _lastScanStartedAt;

  ScannerService({
    required this.marketRepository,
    required this.recommendationRepository,
    required this.settingsRepository,
    required this.notificationService,
  }) {
    _marketModeEngine = MarketModeEngine(marketRepository, _indicatorEngine);
  }

  bool get isRunning => _timer != null;

  void start() {
    stop();
    unawaited(_ensureForegroundServiceRunning());
    _registerTaskCallback();
    unawaited(scanOnce());
    _timer = Timer.periodic(Duration(seconds: _intervalSeconds()), (_) {
      unawaited(scanOnce());
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _unregisterTaskCallback();
    unawaited(_stopForegroundService());
  }

  int _intervalSeconds() {
    final s = settingsRepository.load();
    return s.scanIntervalSeconds <= 0 ? AppDefaults.scanIntervalSeconds : s.scanIntervalSeconds;
  }

  Future<ScanResult> scanOnce() async {
    final now = DateTime.now();
    final last = _lastScanStartedAt;
    if (last != null && now.difference(last).inSeconds < AppDefaults.scanCooldownSeconds) {
      return ScanResult(
        recommendations: recommendationRepository.loadCurrent(),
        completedAt: now,
        marketMode: MarketMode.neutral,
        hadConnectivity: true,
        errorMessage: null,
      );
    }
    if (_scanInProgress) {
      return ScanResult(
        recommendations: recommendationRepository.loadCurrent(),
        completedAt: DateTime.now(),
        marketMode: MarketMode.neutral,
        hadConnectivity: true,
        errorMessage: null,
      );
    }
    _scanInProgress = true;
    _lastScanStartedAt = now;
    try {
      AppLogger.info('scan start', name: 'scanner');

      final hasNet = await _hasConnectivity();
      if (!hasNet) {
        AppLogger.warning('no connectivity', name: 'scanner');
        return ScanResult(
          recommendations: recommendationRepository.loadCurrent(),
          completedAt: DateTime.now(),
          marketMode: MarketMode.neutral,
          hadConnectivity: false,
          errorMessage: 'no_internet',
        );
      }

      final settings = settingsRepository.load();
      final symbols = settings.symbols.isEmpty ? AppDefaults.marketSymbols : settings.symbols;
      final previousRecommendations = recommendationRepository.loadCurrent();

      final marketMode = await _computeMarketMode();
      final pricesBySymbol = <String, double>{};

      final recsByKey = <String, RecommendationModel>{};
      for (final symbol in symbols) {
        try {
          final coin = await marketRepository.fetchCoin24h(symbol);
          pricesBySymbol[symbol] = coin.price;

          final candles15m = await marketRepository.fetchCandles15m(symbol);
          final candles1h = await marketRepository.fetchCandles1h(symbol);
          final candles4h = await marketRepository.fetchCandles4h(symbol);

          if (candles15m.length < 60 || candles1h.length < 60 || candles4h.length < 60) {
            AppLogger.warning('skip $symbol: insufficient candles', name: 'scanner');
            continue;
          }

          final rec = _recommendationEngine.generate(
            coin: coin,
            candles15m: candles15m,
            candles1h: candles1h,
            candles4h: candles4h,
            riskMode: settings.riskMode,
            minConfidence: settings.minConfidence,
            timeframe: AppDefaults.timeframe15m,
            marketMode: marketMode,
          );

          final existing = recsByKey[rec.dedupeKey];
          if (existing == null || rec.confidence > existing.confidence) {
            recsByKey[rec.dedupeKey] = rec;
          }
        } catch (e, st) {
          AppLogger.error('scan failed for $symbol', name: 'scanner', error: e, stackTrace: st);
        }
      }

      final recs = recsByKey.values.toList()..sort((a, b) => b.confidence.compareTo(a.confidence));
      final filtered = recs.where((r) => r.confidence >= settings.minConfidence).toList();
      await recommendationRepository.saveCurrent(filtered);

      await _updateOpenSignals(
        recommendations: filtered,
        previousRecommendations: previousRecommendations,
        latestPricesBySymbol: pricesBySymbol,
        marketMode: marketMode,
        minConfidence: settings.minConfidence,
      );

      AppLogger.info('scan end (${filtered.length} recs)', name: 'scanner');
      return ScanResult(
        recommendations: filtered,
        completedAt: DateTime.now(),
        marketMode: marketMode,
        hadConnectivity: true,
        errorMessage: null,
      );
    } finally {
      _scanInProgress = false;
    }
  }

  Future<MarketMode> _computeMarketMode() async {
    try {
      return await _marketModeEngine.compute();
    } catch (e, st) {
      AppLogger.warning('market mode fallback', name: 'scanner', error: e, stackTrace: st);
      return MarketMode.neutral;
    }
  }

  Future<void> _updateOpenSignals({
    required List<RecommendationModel> recommendations,
    required List<RecommendationModel> previousRecommendations,
    required Map<String, double> latestPricesBySymbol,
    required MarketMode marketMode,
    required int minConfidence,
  }) async {
    final meta = recommendationRepository.loadLastNotifiedMeta();
    final openSignals = recommendationRepository.loadOpenSignals();
    final oldByKey = <String, RecommendationModel>{
      for (final s in openSignals) s.signalKey: s,
    };
    final prevActionBySymTf = <String, RecommendationAction>{};
    for (final r in previousRecommendations) {
      prevActionBySymTf['${r.symbol}-${r.timeframe}'] = r.action;
    }

    final tracking = _trackingEngine.update(
      currentSignals: openSignals,
      latestPricesBySymbol: latestPricesBySymbol,
    );

    final nextOpen = tracking.active.toList();

    for (final updated in tracking.active) {
      if (updated.status != SignalStatus.tp1Hit) continue;
      final old = oldByKey[updated.signalKey];
      if (old == null || old.status == SignalStatus.tp1Hit) continue;
      final key = '${updated.signalKey}-${SignalStatus.tp1Hit.name}';
      if (meta.containsKey(key)) continue;
      meta[key] = updated.confidence;
      await notificationService.showSignal(updated);
    }

    for (final closed in tracking.closed) {
      await recommendationRepository.addToHistory(closed);
      final key = '${closed.signalKey}-${closed.status.name}';
      if (!meta.containsKey(key)) {
        meta[key] = closed.confidence;
        await notificationService.showSignal(closed);
      }
    }

    final buyRecs = recommendations.where((r) => r.action == RecommendationAction.buy && r.confidence >= minConfidence);
    for (final rec in buyRecs) {
      final idx = nextOpen.indexWhere((s) => s.signalKey == rec.signalKey);
      if (idx >= 0) {
        final existing = nextOpen[idx];
        final updated = existing.copyWith(
          confidence: rec.confidence,
          currentPrice: rec.currentPrice,
          reason: rec.reason,
          marketMode: marketMode,
        );
        nextOpen[idx] = updated;
      } else {
        final prevAction = prevActionBySymTf['${rec.symbol}-${rec.timeframe}'];
        final toAdd = prevAction == RecommendationAction.watch
            ? rec.copyWith(reason: <String>[...rec.reason, 'تحوّل من WATCH إلى BUY'])
            : rec;
        nextOpen.add(toAdd);
        if (!meta.containsKey(toAdd.signalKey)) {
          meta[toAdd.signalKey] = toAdd.confidence;
          await notificationService.showSignal(toAdd);
        }
      }
    }

    await recommendationRepository.saveOpenSignals(nextOpen);

    final trimmed = <String, int>{};
    for (final entry in meta.entries.toList().reversed.take(200)) {
      trimmed[entry.key] = entry.value;
    }
    await recommendationRepository.saveLastNotifiedMeta(trimmed);
  }

  Future<bool> _hasConnectivity() async {
    try {
      final res = await InternetAddress.lookup('api.binance.com')
          .timeout(const Duration(seconds: 3));
      return res.isNotEmpty && res.first.rawAddress.isNotEmpty;
    } catch (e, st) {
      AppLogger.warning('connectivity check failed', name: 'scanner', error: e, stackTrace: st);
      return false;
    }
  }

  void _registerTaskCallback() {
    if (!Platform.isAndroid) return;
    if (_taskCallbackRegistered) return;
    _taskCallbackRegistered = true;
    FlutterForegroundTask.addTaskDataCallback(_onTaskData);
  }

  void _unregisterTaskCallback() {
    if (!Platform.isAndroid) return;
    if (!_taskCallbackRegistered) return;
    _taskCallbackRegistered = false;
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
  }

  void _onTaskData(Object data) {
    unawaited(scanOnce());
  }

  Future<void> _ensureForegroundServiceRunning() async {
    if (!Platform.isAndroid) return;
    try {
      final notificationPermission = await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }

      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.restartService();
        return;
      }

      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Smart Crypto Signals',
        notificationText: 'Scanning signals in background',
        callback: _startCallback,
      );
    } catch (e, st) {
      AppLogger.warning('foreground service start failed', name: 'scanner', error: e, stackTrace: st);
    }
  }

  Future<void> _stopForegroundService() async {
    if (!Platform.isAndroid) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (e, st) {
      AppLogger.warning('foreground service stop failed', name: 'scanner', error: e, stackTrace: st);
    }
  }
}

@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_ScannerTaskHandler());
}

class _ScannerTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    FlutterForegroundTask.sendDataToMain(<String, dynamic>{
      'ts': timestamp.millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
