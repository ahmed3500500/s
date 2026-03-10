import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_enums.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/recommendations_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/confidence_bar.dart';
import '../../shared/widgets/signal_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'الرئيسية',
      actions: [
        IconButton(
          onPressed: () => context.read<ScannerProvider>().scanOnce(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: Consumer2<ScannerProvider, RecommendationsProvider>(
        builder: (context, scanner, recs, _) {
          final top = recs.current.isEmpty ? null : recs.current.first;
          final last = scanner.status.lastUpdate;
          final today = DateTime.now();
          final todayHistory = recs.history
              .where(
                (r) =>
                    r.createdAt.year == today.year &&
                    r.createdAt.month == today.month &&
                    r.createdAt.day == today.day,
              )
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (scanner.loading)
                AppCard(
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'جارٍ الفحص...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              if (scanner.loading) const SizedBox(height: 12),
              if (scanner.noInternet)
                AppCard(
                  child: Text(
                    'لا يوجد اتصال بالإنترنت. تم تأجيل الفحص.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              if (scanner.noInternet) const SizedBox(height: 12),
              if (scanner.lastError != null && scanner.lastError != 'no_internet')
                AppCard(
                  child: Text(
                    'حدث خطأ أثناء الفحص: ${scanner.lastError}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.avoid),
                  ),
                ),
              if (scanner.lastError != null && scanner.lastError != 'no_internet') const SizedBox(height: 12),
              AppCard(
                child: _MarketStatusCard(
                  mode: scanner.status.marketMode,
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: _ScannerStatusCard(
                  running: scanner.status.running,
                  analyzed: scanner.status.analyzedCoins,
                  recommendations: scanner.status.recommendationsCount,
                  lastUpdate: last,
                  onStart: () => scanner.start(),
                  onStop: () => scanner.stop(),
                ),
              ),
              const SizedBox(height: 12),
              if (top != null)
                InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    RouteNames.coinDetails,
                    arguments: top,
                  ),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'أقوى توصية الآن',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const Spacer(),
                            SignalBadge(action: top.action),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          top.symbol,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        ConfidenceBar(confidence: top.confidence),
                        const SizedBox(height: 12),
                        if (top.reason.isNotEmpty)
                          Text(
                            top.reason.take(2).join(' • '),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
                  ),
                )
              else
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أقوى توصية الآن',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لا توجد توصيات حالياً. شغّل الفحص أو قلّل الحد الأدنى للثقة.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'توصيات اليوم',
                        value: '${todayHistory.length}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        label: 'BUY اليوم',
                        value: '${todayHistory.where((e) => e.action == RecommendationAction.buy).length}',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'تلميح: التطبيق يعرض إشارات قليلة لكن قوية فقط.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MarketStatusCard extends StatelessWidget {
  final MarketMode mode;

  const _MarketStatusCard({required this.mode});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (mode) {
      MarketMode.bullish => ('Bullish', AppColors.buy),
      MarketMode.sideways => ('Sideways', AppColors.watch),
      MarketMode.neutral => ('Neutral', AppColors.watch),
      MarketMode.volatile => ('Volatile', AppColors.watch),
      MarketMode.bearish => ('Bearish', AppColors.avoid),
      MarketMode.weakLiquidity => ('Weak Liquidity', AppColors.watch),
    };

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'حالة السوق',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const Spacer(),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _ScannerStatusCard extends StatelessWidget {
  final bool running;
  final int analyzed;
  final int recommendations;
  final DateTime? lastUpdate;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _ScannerStatusCard({
    required this.running,
    required this.analyzed,
    required this.recommendations,
    required this.lastUpdate,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'حالة المحرك',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            Text(
              running ? 'Running' : 'Stopped',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: running ? AppColors.buy : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatTile(label: 'Analyzed', value: '$analyzed')),
            const SizedBox(width: 12),
            Expanded(child: _StatTile(label: 'Signals', value: '$recommendations')),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                lastUpdate == null ? 'Last Update: —' : 'Last Update: ${DateUtilsX.formatDateTime(lastUpdate!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: running ? null : onStart,
              child: const Text('Start AI Scanner'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: running ? onStop : null,
              child: const Text('Stop Scanner'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
