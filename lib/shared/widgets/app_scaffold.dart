import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../routes/route_names.dart';

class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      drawer: const Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                title: Text(AppStrings.appName),
              ),
              Divider(height: 1),
              _NavTile(
                label: 'الرئيسية',
                route: RouteNames.home,
                icon: Icons.dashboard_outlined,
              ),
              _NavTile(
                label: 'التوصيات',
                route: RouteNames.recommendations,
                icon: Icons.auto_graph_outlined,
              ),
              _NavTile(
                label: 'السجل',
                route: RouteNames.history,
                icon: Icons.history_outlined,
              ),
              _NavTile(
                label: 'الإحصائيات',
                route: RouteNames.statistics,
                icon: Icons.query_stats_outlined,
              ),
              _NavTile(
                label: 'الإعدادات',
                route: RouteNames.settings,
                icon: Icons.settings_outlined,
              ),
              Spacer(),
              _NavTile(
                label: 'حول',
                route: RouteNames.about,
                icon: Icons.info_outline,
              ),
            ],
          ),
        ),
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }
}

class _NavTile extends StatelessWidget {
  final String label;
  final String route;
  final IconData icon;

  const _NavTile({
    required this.label,
    required this.route,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        if (ModalRoute.of(context)?.settings.name == route) return;
        Navigator.pushReplacementNamed(context, route);
      },
    );
  }
}
