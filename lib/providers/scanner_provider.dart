import 'package:flutter/foundation.dart';

import '../core/config/app_defaults.dart';
import '../core/constants/app_enums.dart';
import '../data/models.dart';
import '../services/scanner_service.dart';
import 'app_providers.dart';
import 'recommendations_provider.dart';
import 'settings_provider.dart';

class ScannerProvider extends ChangeNotifier {
  final ScannerServiceFactory scannerServiceFactory;

  ScannerProvider({required this.scannerServiceFactory});

  ScannerService? _service;
  RecommendationsProvider? _recommendations;
  SettingsProvider? _settings;

  ScannerStatusModel _status = const ScannerStatusModel(
    running: false,
    lastUpdate: null,
    analyzedCoins: 0,
    recommendationsCount: 0,
    marketMode: MarketMode.neutral,
  );

  ScannerStatusModel get status => _status;
  bool _loading = false;
  bool get loading => _loading;
  bool _noInternet = false;
  bool get noInternet => _noInternet;
  String? _lastError;
  String? get lastError => _lastError;

  void bind({
    required AppDependencies deps,
    required RecommendationsProvider recommendations,
    required SettingsProvider settings,
  }) {
    _recommendations = recommendations;
    _settings = settings;
    _service ??= scannerServiceFactory(deps);
    _status = _status.copyWith(running: _service?.isRunning ?? false);
    notifyListeners();
  }

  Future<void> start() async {
    final service = _service;
    if (service == null) return;
    service.start();
    _status = _status.copyWith(running: true);
    notifyListeners();
    await scanOnce();
  }

  void stop() {
    final service = _service;
    if (service == null) return;
    service.stop();
    _status = _status.copyWith(running: false);
    notifyListeners();
  }

  Future<void> scanOnce() async {
    final service = _service;
    final recsProvider = _recommendations;
    final settings = _settings?.settings;
    if (service == null || recsProvider == null) return;

    final beforeSymbols = settings?.symbols ?? AppDefaults.marketSymbols;
    _status = _status.copyWith(analyzedCoins: beforeSymbols.length);
    _loading = true;
    _lastError = null;
    notifyListeners();

    final res = await service.scanOnce();
    recsProvider.refresh();
    _status = _status.copyWith(
      lastUpdate: res.completedAt,
      recommendationsCount: res.recommendations.length,
      marketMode: res.marketMode,
    );
    _loading = false;
    _noInternet = !res.hadConnectivity;
    _lastError = res.errorMessage;
    notifyListeners();
  }
}
