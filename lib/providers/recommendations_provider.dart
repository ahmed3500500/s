import 'package:flutter/foundation.dart';

import '../data/models.dart';
import '../data/repositories.dart';

class RecommendationsProvider extends ChangeNotifier {
  RecommendationRepository? _repo;

  List<RecommendationModel> _current = <RecommendationModel>[];
  List<RecommendationModel> _openSignals = <RecommendationModel>[];
  List<RecommendationModel> _history = <RecommendationModel>[];

  List<RecommendationModel> get current => _current;
  List<RecommendationModel> get openSignals => _openSignals;
  List<RecommendationModel> get history => _history;

  void bind(RecommendationRepository repo) {
    if (_repo == repo) return;
    _repo = repo;
    refresh();
  }

  void refresh() {
    final repo = _repo;
    if (repo == null) return;
    _current = repo.loadCurrent();
    _openSignals = repo.loadOpenSignals();
    _history = repo.loadHistory();
    notifyListeners();
  }

  Future<void> setCurrent(List<RecommendationModel> recs) async {
    final repo = _repo;
    if (repo == null) return;
    _current = recs;
    notifyListeners();
    await repo.saveCurrent(recs);
  }
}
