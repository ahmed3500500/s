import 'dart:convert';

import 'package:hive/hive.dart';

import '../core/config/app_defaults.dart';
import '../core/utils/number_utils.dart';
import 'models.dart';

class LocalStorageService {
  static const _settingsBoxName = 'settings_box';
  static const _recommendationsBoxName = 'recommendations_box';
  static const _historyBoxName = 'history_box';

  static const _settingsKey = 'user_settings';
  static const _recommendationsKey = 'current_recommendations';
  static const _historyKey = 'history';
  static const _openSignalsKey = 'open_signals';
  static const _lastNotifiedKey = 'last_notified_ids';
  static const _lastNotifiedMetaKey = 'last_notified_meta';

  late final Box _settingsBox;
  late final Box _recommendationsBox;
  late final Box _historyBox;

  Future<void> init() async {
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _recommendationsBox = await Hive.openBox(_recommendationsBoxName);
    _historyBox = await Hive.openBox(_historyBoxName);
  }

  UserSettingsModel loadSettings() {
    final raw = _settingsBox.get(_settingsKey);
    if (raw is String) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final loaded = UserSettingsModel.fromJson(map);
      return UserSettingsModel(
        scanIntervalSeconds: loaded.scanIntervalSeconds == 0
            ? AppDefaults.scanIntervalSeconds
            : loaded.scanIntervalSeconds,
        minConfidence:
            loaded.minConfidence == 0 ? AppDefaults.minConfidence : loaded.minConfidence,
        riskMode: loaded.riskMode,
        symbols: loaded.symbols.isEmpty ? AppDefaults.marketSymbols : loaded.symbols,
      );
    }
    return const UserSettingsModel(
      scanIntervalSeconds: AppDefaults.scanIntervalSeconds,
      minConfidence: AppDefaults.minConfidence,
      riskMode: AppDefaults.riskMode,
      symbols: AppDefaults.marketSymbols,
    );
  }

  Future<void> saveSettings(UserSettingsModel settings) async {
    await _settingsBox.put(_settingsKey, jsonEncode(settings.toJson()));
  }

  List<RecommendationModel> loadRecommendations() {
    final raw = _recommendationsBox.get(_recommendationsKey);
    if (raw is String) {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => RecommendationModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return <RecommendationModel>[];
  }

  Future<void> saveRecommendations(List<RecommendationModel> recs) async {
    final jsonList = recs.map((e) => e.toJson()).toList();
    await _recommendationsBox.put(_recommendationsKey, jsonEncode(jsonList));
  }

  List<RecommendationModel> loadOpenSignals() {
    final raw = _historyBox.get(_openSignalsKey);
    if (raw is String) {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => RecommendationModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return <RecommendationModel>[];
  }

  Future<void> saveOpenSignals(List<RecommendationModel> signals) async {
    final jsonList = signals.map((e) => e.toJson()).toList();
    await _historyBox.put(_openSignalsKey, jsonEncode(jsonList));
  }

  List<RecommendationModel> loadHistory() {
    final raw = _historyBox.get(_historyKey);
    if (raw is String) {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => RecommendationModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return <RecommendationModel>[];
  }

  Future<void> addToHistory(RecommendationModel rec) async {
    final history = loadHistory();
    history.insert(0, rec);
    final trimmed = history.take(300).toList();
    await _historyBox.put(
      _historyKey,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  Set<String> loadLastNotifiedIds() {
    final raw = _historyBox.get(_lastNotifiedKey);
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toSet();
      }
      if (decoded is Map) {
        return decoded.keys.map((e) => e.toString()).toSet();
      }
    }
    return <String>{};
  }

  Future<void> saveLastNotifiedIds(Set<String> ids) async {
    await _historyBox.put(_lastNotifiedKey, jsonEncode(ids.toList()));
  }

  Map<String, int> loadLastNotifiedMeta() {
    final raw = _historyBox.get(_lastNotifiedMetaKey);
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), NumberUtils.safeParseInt(v)));
      }
    }
    return <String, int>{};
  }

  Future<void> saveLastNotifiedMeta(Map<String, int> meta) async {
    await _historyBox.put(_lastNotifiedMetaKey, jsonEncode(meta));
  }

  Future<void> clearAll() async {
    await _settingsBox.clear();
    await _recommendationsBox.clear();
    await _historyBox.clear();
  }
}
