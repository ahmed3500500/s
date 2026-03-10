import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_enums.dart';
import '../../providers/recommendations_provider.dart';
import '../../shared/widgets/app_scaffold.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'الإحصائيات',
      body: Consumer<RecommendationsProvider>(
        builder: (context, recs, _) {
          final active = recs.openSignals;
          final history = recs.history;

          if (active.isEmpty && history.isEmpty) {
            return Center(
              child: Text(
                'لا توجد بيانات بعد. شغّل الفحص واترك الإشارات تُغلق.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            );
          }

          final closedSignals = history;
          final totalSignals = active.length + closedSignals.length;
          final fullWins =
              closedSignals.where((e) => _finalOutcomeOf(e) == FinalOutcome.fullWin).length;
          final partialWins =
              closedSignals.where((e) => _finalOutcomeOf(e) == FinalOutcome.partialWin).length;
          final losses = closedSignals.where((e) => _finalOutcomeOf(e) == FinalOutcome.loss).length;
          final expired =
              closedSignals.where((e) => _finalOutcomeOf(e) == FinalOutcome.expired).length;
          final cancelled =
              closedSignals.where((e) => _finalOutcomeOf(e) == FinalOutcome.cancelled).length;
          final winRate = closedSignals.isEmpty
              ? 0.0
              : ((fullWins + partialWins) / closedSignals.length) * 100.0;
          final pnls = closedSignals.where((e) => e.pnlPct != null).map((e) => e.pnlPct!).toList(growable: false);
          final avgPnl = pnls.isEmpty ? 0.0 : pnls.reduce((a, b) => a + b) / pnls.length;

          final bestTf = _bestKey(
            closedSignals,
            keyOf: (e) => e.timeframe,
          );
          final bestCoin = _bestKey(
            closedSignals,
            keyOf: (e) => e.symbol,
          );
          final bestMode = _bestKey(
            closedSignals,
            keyOf: (e) => e.marketMode.name,
          );
          final bestRisk = _bestKey(
            closedSignals,
            keyOf: (e) => e.riskModeAtOpen.name,
          );

          final modeRows = _groupStats(
            closedSignals,
            keyOf: (e) => e.marketMode,
          );
          final tfRows = _groupStats(
            closedSignals,
            keyOf: (e) => e.timeframe,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ملخص',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _StatLine(label: 'Total', value: '$totalSignals')),
                          Expanded(child: _StatLine(label: 'Active', value: '${active.length}')),
                          Expanded(child: _StatLine(label: 'Closed', value: '${closedSignals.length}')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _StatLine(label: 'Full Wins', value: '$fullWins', valueColor: AppColors.buy)),
                          Expanded(child: _StatLine(label: 'Partial Wins', value: '$partialWins', valueColor: AppColors.watch)),
                          Expanded(child: _StatLine(label: 'Losses', value: '$losses', valueColor: AppColors.avoid)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _StatLine(label: 'Expired', value: '$expired', valueColor: AppColors.textSecondary)),
                          Expanded(child: _StatLine(label: 'Cancelled', value: '$cancelled', valueColor: AppColors.textSecondary)),
                          Expanded(child: _StatLine(label: 'Win%', value: '${winRate.toStringAsFixed(1)}%')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _StatLine(
                        label: 'Avg PnL',
                        value: '${avgPnl.toStringAsFixed(2)}%',
                        valueColor: avgPnl >= 0 ? AppColors.buy : AppColors.avoid,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'أفضل نتائج',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      _StatLine(label: 'Best Timeframe', value: bestTf ?? '-'),
                      const SizedBox(height: 8),
                      _StatLine(label: 'Best Coin', value: bestCoin ?? '-'),
                      const SizedBox(height: 8),
                      _StatLine(label: 'Best Market Mode', value: bestMode ?? '-'),
                      const SizedBox(height: 8),
                      _StatLine(label: 'Best Risk Mode', value: bestRisk ?? '-'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Win Rate حسب Market Mode',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      ...modeRows.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RateRow(
                              label: _marketModeLabel(r.key as MarketMode),
                              count: r.total,
                              winRate: r.winRate,
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Win Rate حسب Timeframe',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      ...tfRows.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RateRow(
                              label: r.key.toString(),
                              count: r.total,
                              winRate: r.winRate,
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatLine({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}

class _RateRow extends StatelessWidget {
  final String label;
  final int count;
  final double winRate;

  const _RateRow({required this.label, required this.count, required this.winRate});

  @override
  Widget build(BuildContext context) {
    final color = winRate >= 50 ? AppColors.buy : AppColors.avoid;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          '$count',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Text(
          '${winRate.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }
}

class _GroupRow {
  final Object key;
  final int total;
  final double winRate;

  const _GroupRow({required this.key, required this.total, required this.winRate});
}

List<_GroupRow> _groupStats<T>(
  List<dynamic> recs, {
  required T Function(dynamic e) keyOf,
}) {
  final map = <T, List<dynamic>>{};
  for (final r in recs) {
    final k = keyOf(r);
    (map[k] ??= <dynamic>[]).add(r);
  }

  final out = <_GroupRow>[];
  for (final entry in map.entries) {
    final total = entry.value.length;
    final wins = entry.value
        .where((e) => _finalOutcomeOf(e) == FinalOutcome.fullWin || _finalOutcomeOf(e) == FinalOutcome.partialWin)
        .length;
    final winRate = total == 0 ? 0.0 : (wins / total) * 100.0;
    out.add(_GroupRow(key: entry.key as Object, total: total, winRate: winRate));
  }
  out.sort((a, b) => b.winRate.compareTo(a.winRate));
  return out;
}

String? _bestKey(
  List<dynamic> recs, {
  required String Function(dynamic e) keyOf,
}) {
  if (recs.isEmpty) return null;
  final map = <String, List<dynamic>>{};
  for (final r in recs) {
    final k = keyOf(r);
    (map[k] ??= <dynamic>[]).add(r);
  }

  String? best;
  var bestScore = -1.0;
  for (final entry in map.entries) {
    final total = entry.value.length;
    final wins = entry.value
        .where((e) => _finalOutcomeOf(e) == FinalOutcome.fullWin || _finalOutcomeOf(e) == FinalOutcome.partialWin)
        .length;
    final pnls = entry.value.where((e) => e.pnlPct != null).map((e) => e.pnlPct!);
    final avgPnl = pnls.isEmpty ? 0.0 : pnls.reduce((a, b) => a + b) / pnls.length;
    final winRate = total == 0 ? 0.0 : (wins / total) * 100.0;
    final score = (total >= 3 ? winRate : winRate * 0.75) + avgPnl;
    if (score > bestScore) {
      bestScore = score;
      best = entry.key;
    }
  }
  return best;
}

FinalOutcome _finalOutcomeOf(dynamic rec) {
  final direct = rec.finalOutcome;
  if (direct is FinalOutcome) return direct;
  final status = rec.status;
  if (status == SignalStatus.tp2Hit) return FinalOutcome.fullWin;
  if (status == SignalStatus.tp1Hit) return FinalOutcome.partialWin;
  if (status == SignalStatus.stopLossHit) return FinalOutcome.loss;
  if (status == SignalStatus.expired) return FinalOutcome.expired;
  if (status == SignalStatus.cancelled) return FinalOutcome.cancelled;
  return FinalOutcome.cancelled;
}
