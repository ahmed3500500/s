import '../../core/constants/app_enums.dart';

class ScannerStatusModel {
  final bool running;
  final DateTime? lastUpdate;
  final int analyzedCoins;
  final int recommendationsCount;
  final MarketMode marketMode;

  const ScannerStatusModel({
    required this.running,
    required this.lastUpdate,
    required this.analyzedCoins,
    required this.recommendationsCount,
    required this.marketMode,
  });

  ScannerStatusModel copyWith({
    bool? running,
    DateTime? lastUpdate,
    int? analyzedCoins,
    int? recommendationsCount,
    MarketMode? marketMode,
  }) {
    return ScannerStatusModel(
      running: running ?? this.running,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      analyzedCoins: analyzedCoins ?? this.analyzedCoins,
      recommendationsCount: recommendationsCount ?? this.recommendationsCount,
      marketMode: marketMode ?? this.marketMode,
    );
  }
}

