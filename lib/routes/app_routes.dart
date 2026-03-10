import 'package:flutter/material.dart';

import '../data/models.dart';
import '../features/about/about_screen.dart';
import '../features/coin_details/coin_details_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/recommendations/recommendations_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/statistics/statistics_screen.dart';
import 'route_names.dart';

class AppRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case RouteNames.recommendations:
        return MaterialPageRoute(builder: (_) => const RecommendationsScreen());
      case RouteNames.coinDetails:
        final args = settings.arguments;
        if (args is RecommendationModel) {
          return MaterialPageRoute(
            builder: (_) => CoinDetailsScreen(recommendation: args),
          );
        }
        return _badArgs(settings.name, 'RecommendationModel');
      case RouteNames.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case RouteNames.history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case RouteNames.statistics:
        return MaterialPageRoute(builder: (_) => const StatisticsScreen());
      case RouteNames.about:
        return MaterialPageRoute(builder: (_) => const AboutScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found: ${settings.name}')),
          ),
        );
    }
  }

  static Route<dynamic> _badArgs(String? route, String expected) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text('Bad arguments for $route. Expected: $expected'),
        ),
      ),
    );
  }
}
