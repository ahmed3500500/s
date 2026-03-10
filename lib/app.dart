import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'routes/app_routes.dart';
import 'routes/route_names.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, app, _) {
        return MaterialApp(
          title: 'Smart Crypto Signals',
          theme: AppTheme.dark(),
          debugShowCheckedModeBanner: false,
          initialRoute: RouteNames.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}
