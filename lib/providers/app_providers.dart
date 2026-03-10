import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/local_storage_service.dart';
import '../data/market_api_service.dart';
import '../data/repositories.dart';
import '../services/notification_service.dart';
import '../services/scanner_service.dart';
import 'app_provider.dart';
import 'recommendations_provider.dart';
import 'scanner_provider.dart';
import 'settings_provider.dart';

class AppDependencies {
  final MarketRepository marketRepository;
  final RecommendationRepository recommendationRepository;
  final SettingsRepository settingsRepository;

  const AppDependencies({
    required this.marketRepository,
    required this.recommendationRepository,
    required this.settingsRepository,
  });
}

typedef ScannerServiceFactory = ScannerService Function(AppDependencies deps);

List<SingleChildWidget> buildAppProviders({
  required LocalStorageService storage,
  required NotificationService notifications,
  required ScannerServiceFactory scannerServiceFactory,
}) {
  return [
    Provider<LocalStorageService>.value(value: storage),
    Provider<NotificationService>.value(value: notifications),

    Provider<MarketApiService>(create: (_) => MarketApiService()),
    ProxyProvider<MarketApiService, MarketRepository>(
      update: (_, api, __) => MarketRepository(api),
    ),

    ProxyProvider<LocalStorageService, SettingsRepository>(
      update: (_, s, __) => SettingsRepository(s),
    ),
    ProxyProvider<LocalStorageService, RecommendationRepository>(
      update: (_, s, __) => RecommendationRepository(s),
    ),

    ProxyProvider3<MarketRepository, RecommendationRepository, SettingsRepository, AppDependencies>(
      update: (_, market, recs, settings, __) => AppDependencies(
        marketRepository: market,
        recommendationRepository: recs,
        settingsRepository: settings,
      ),
    ),

    ChangeNotifierProvider(create: (_) => AppProvider()),
    ChangeNotifierProxyProvider<SettingsRepository, SettingsProvider>(
      create: (_) => SettingsProvider(),
      update: (_, repo, provider) => (provider ?? SettingsProvider())..bind(repo),
    ),
    ChangeNotifierProxyProvider<RecommendationRepository, RecommendationsProvider>(
      create: (_) => RecommendationsProvider(),
      update: (_, repo, provider) => (provider ?? RecommendationsProvider())..bind(repo),
    ),
    ChangeNotifierProxyProvider3<AppDependencies, RecommendationsProvider, SettingsProvider, ScannerProvider>(
      create: (_) => ScannerProvider(scannerServiceFactory: scannerServiceFactory),
      update: (_, deps, recs, settings, provider) =>
          (provider ?? ScannerProvider(scannerServiceFactory: scannerServiceFactory))
            ..bind(deps: deps, recommendations: recs, settings: settings),
    ),
  ];
}
