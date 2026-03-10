import 'package:flutter/foundation.dart';

import '../core/config/app_defaults.dart';
import '../core/constants/app_enums.dart';
import '../data/models.dart';
import '../data/repositories.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsRepository? _repo;
  UserSettingsModel _settings = const UserSettingsModel(
    scanIntervalSeconds: AppDefaults.scanIntervalSeconds,
    minConfidence: AppDefaults.minConfidence,
    riskMode: AppDefaults.riskMode,
    symbols: AppDefaults.marketSymbols,
  );

  UserSettingsModel get settings => _settings;

  void bind(SettingsRepository repo) {
    if (_repo == repo) return;
    _repo = repo;
    _settings = repo.load();
    notifyListeners();
  }

  Future<void> setScanIntervalSeconds(int seconds) async {
    final repo = _repo;
    if (repo == null) return;
    final next = UserSettingsModel(
      scanIntervalSeconds: seconds,
      minConfidence: _settings.minConfidence,
      riskMode: _settings.riskMode,
      symbols: _settings.symbols,
    );
    _settings = next;
    notifyListeners();
    await repo.save(next);
  }

  Future<void> setMinConfidence(int value) async {
    final repo = _repo;
    if (repo == null) return;
    final next = UserSettingsModel(
      scanIntervalSeconds: _settings.scanIntervalSeconds,
      minConfidence: value,
      riskMode: _settings.riskMode,
      symbols: _settings.symbols,
    );
    _settings = next;
    notifyListeners();
    await repo.save(next);
  }

  Future<void> setRiskMode(RiskMode mode) async {
    final repo = _repo;
    if (repo == null) return;
    final next = UserSettingsModel(
      scanIntervalSeconds: _settings.scanIntervalSeconds,
      minConfidence: _settings.minConfidence,
      riskMode: mode,
      symbols: _settings.symbols,
    );
    _settings = next;
    notifyListeners();
    await repo.save(next);
  }

  Future<void> setSymbols(List<String> symbols) async {
    final repo = _repo;
    if (repo == null) return;
    final next = UserSettingsModel(
      scanIntervalSeconds: _settings.scanIntervalSeconds,
      minConfidence: _settings.minConfidence,
      riskMode: _settings.riskMode,
      symbols: symbols,
    );
    _settings = next;
    notifyListeners();
    await repo.save(next);
  }
}
