import '../local_storage_service.dart';
import '../models.dart';

class RecommendationRepository {
  final LocalStorageService _storage;

  RecommendationRepository(this._storage);

  List<RecommendationModel> loadCurrent() => _storage.loadRecommendations();

  Future<void> saveCurrent(List<RecommendationModel> recs) => _storage.saveRecommendations(recs);

  List<RecommendationModel> loadOpenSignals() => _storage.loadOpenSignals();

  Future<void> saveOpenSignals(List<RecommendationModel> signals) => _storage.saveOpenSignals(signals);

  List<RecommendationModel> loadHistory() => _storage.loadHistory();

  Future<void> addToHistory(RecommendationModel rec) => _storage.addToHistory(rec);

  Set<String> loadLastNotifiedIds() => _storage.loadLastNotifiedIds();

  Future<void> saveLastNotifiedIds(Set<String> ids) => _storage.saveLastNotifiedIds(ids);

  Map<String, int> loadLastNotifiedMeta() => _storage.loadLastNotifiedMeta();

  Future<void> saveLastNotifiedMeta(Map<String, int> meta) => _storage.saveLastNotifiedMeta(meta);
}

