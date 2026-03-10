import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_enums.dart';
import '../../providers/recommendations_provider.dart';
import '../../providers/scanner_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/confidence_bar.dart';
import '../../shared/widgets/signal_badge.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  RecommendationAction? _filter;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'التوصيات',
      actions: [
        IconButton(
          onPressed: () => context.read<RecommendationsProvider>().refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: Consumer2<ScannerProvider, RecommendationsProvider>(
        builder: (context, scanner, recs, _) {
          final all = recs.current;
          final filtered = _filter == null ? all : all.where((e) => e.action == _filter).toList();

          return Column(
            children: [
              if (scanner.loading)
                const LinearProgressIndicator(
                  minHeight: 2,
                ),
              const SizedBox(height: 12),
              if (scanner.noInternet)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    'لا يوجد اتصال بالإنترنت. النتائج المعروضة قديمة.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              if (scanner.lastError != null && scanner.lastError != 'no_internet')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    'حدث خطأ أثناء الفحص: ${scanner.lastError}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.avoid),
                  ),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == null,
                      onSelected: () => setState(() => _filter = null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Buy',
                      selected: _filter == RecommendationAction.buy,
                      color: AppColors.buy,
                      onSelected: () => setState(() => _filter = RecommendationAction.buy),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Watch',
                      selected: _filter == RecommendationAction.watch,
                      color: AppColors.watch,
                      onSelected: () => setState(() => _filter = RecommendationAction.watch),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Avoid',
                      selected: _filter == RecommendationAction.avoid,
                      color: AppColors.avoid,
                      onSelected: () => setState(() => _filter = RecommendationAction.avoid),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد نتائج',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final rec = filtered[index];
                          return InkWell(
                            onTap: () => Navigator.pushNamed(
                              context,
                              RouteNames.coinDetails,
                              arguments: rec,
                            ),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          rec.symbol,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(fontWeight: FontWeight.w900),
                                        ),
                                        const Spacer(),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            SignalBadge(action: rec.action),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _MiniChip(
                                                  label: _marketModeLabel(rec.marketMode),
                                                  color: _marketModeColor(rec.marketMode),
                                                ),
                                                const SizedBox(width: 6),
                                                _MiniChip(
                                                  label: _statusLabel(rec.status),
                                                  color: _statusColor(rec.status),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ConfidenceBar(confidence: rec.confidence),
                                    const SizedBox(height: 10),
                                    if (rec.reason.isNotEmpty)
                                      Text(
                                        rec.reason.take(2).join(' • '),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(color: AppColors.textSecondary),
                                      ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        _LevelChip(label: 'Entry', value: rec.entry),
                                        const SizedBox(width: 8),
                                        _LevelChip(label: 'SL', value: rec.stopLoss),
                                        const SizedBox(width: 8),
                                        _LevelChip(label: 'TP1', value: rec.takeProfit1),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: base.withValues(alpha: 0.22),
      onSelected: (_) => onSelected(),
      side: BorderSide(color: selected ? base : AppColors.divider),
      labelStyle: TextStyle(
        color: selected ? base : null,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String label;
  final double value;

  const _LevelChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: ${value.toStringAsFixed(4)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

String _marketModeLabel(MarketMode mode) {
  return switch (mode) {
    MarketMode.bullish => 'Bullish',
    MarketMode.sideways => 'Sideways',
    MarketMode.neutral => 'Neutral',
    MarketMode.volatile => 'Volatile',
    MarketMode.bearish => 'Bearish',
    MarketMode.weakLiquidity => 'Weak Liquidity',
  };
}

Color _marketModeColor(MarketMode mode) {
  return switch (mode) {
    MarketMode.bullish => AppColors.buy,
    MarketMode.bearish => AppColors.avoid,
    MarketMode.neutral => AppColors.watch,
    MarketMode.sideways => AppColors.watch,
    MarketMode.volatile => AppColors.watch,
    MarketMode.weakLiquidity => AppColors.watch,
  };
}

String _statusLabel(SignalStatus status) {
  return switch (status) {
    SignalStatus.active => 'NEW',
    SignalStatus.tp1Hit => 'TP1',
    SignalStatus.tp2Hit => 'TP2',
    SignalStatus.stopLossHit => 'SL',
    SignalStatus.expired => 'EXPIRED',
    SignalStatus.cancelled => 'CANCELLED',
  };
}

Color _statusColor(SignalStatus status) {
  return switch (status) {
    SignalStatus.active => AppColors.textSecondary,
    SignalStatus.tp1Hit => AppColors.buy,
    SignalStatus.tp2Hit => AppColors.buy,
    SignalStatus.stopLossHit => AppColors.avoid,
    SignalStatus.expired => AppColors.textSecondary,
    SignalStatus.cancelled => AppColors.textSecondary,
  };
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}
