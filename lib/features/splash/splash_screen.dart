import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../routes/route_names.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_goNext());
  }

  Future<void> _goNext() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Text(
              'AI Crypto Advisor',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
