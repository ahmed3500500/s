import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_enums.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models.dart';
import '../../providers/recommendations_provider.dart';
import '../../routes/route_names.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/signal_badge.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'السجل',
      actions: [
        IconButton(
          onPressed: () => context.read<RecommendationsProvider>().refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: Consumer<RecommendationsProvider>(
        builder: (context, recs, _) {
          final list = recs.history;
          if (list.isEmpty) {
            return Center(
              child: Text(
                'لا يوجد سجل بعد.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            );
          }

          final total = list.length;
          final fullWins = list.where((e) => _finalOutcomeOf(e) == FinalOutcome.fullWin).length;
          final partialWins =
              list.where((e) => _finalOutcomeOf(e) == FinalOutcome.partialWin).length;
          final losses = list.where((e) => _finalOutcomeOf(e) == FinalOutcome.loss).length;
          final expired = list.where((e) => _finalOutcomeOf(e) == FinalOutcome.expired).length;
          final cancelled = list.where((e) => _finalOutcomeOf(e) == FinalOutcome.cancelled).length;
          final pnls = list.where((e) => e.pnlPct != null).map((e) => e.pnlPct!).toList(growable: false);
          final avgPnl = pnls.isEmpty ? 0.0 : pnls.reduce((a, b) => a + b) / pnls.length;
          final winRate = total == 0 ? 0.0 : ((fullWins + partialWins) / total) * 100.0;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تقييم الأداء',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _StatLine(label: 'إجمالي', value: '$total')),
                            Expanded(child: _StatLine(label: 'Win%', value: '${winRate.toStringAsFixed(1)}%')),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _StatLine(label: 'Full Wins', value: '$fullWins', valueColor: AppColors.buy)),
                            Expanded(
                              child: _StatLine(
                                label: 'Partial Wins',
                                value: '$partialWins',
                                valueColor: AppColors.watch,
                              ),
                            ),
                            Expanded(child: _StatLine(label: 'Losses', value: '$losses')),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _StatLine(label: 'Expired', value: '$expired')),
                            Expanded(child: _StatLine(label: 'Cancelled', value: '$cancelled')),
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
                );
              }

              final rec = list[index - 1];
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
                            Expanded(
                              child: Text(
                                rec.symbol,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SignalBadge(action: rec.action),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniChip(label: _marketModeLabel(rec.marketMode), color: _marketModeColor(rec.marketMode)),
                            _MiniChip(
                              label: _finalOutcomeLabel(_finalOutcomeOf(rec)),
                              color: _finalOutcomeColor(_finalOutcomeOf(rec)),
                            ),
                            _MiniChip(label: _statusLabel(rec.status), color: _statusColor(rec.status)),
                            if (rec.pnlPct != null)
                              _MiniChip(
                                label: 'PnL: ${rec.pnlPct!.toStringAsFixed(2)}%',
                                color: rec.pnlPct! >= 0 ? AppColors.buy : AppColors.avoid,
                              ),
                            _MiniChip(label: '${rec.confidence}%', color: AppColors.textSecondary),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Open: ${DateUtilsX.formatDateTime(rec.createdAt)}'
                          '${rec.closedAt == null ? '' : ' • Close: ${DateUtilsX.formatDateTime(rec.closedAt!)}'}'
                          '${rec.closedAt == null ? '' : ' • ${_durationLabel(rec.createdAt, rec.closedAt!)}'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                        if (rec.reason.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            rec.reason.take(2).join(' • '),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

String _durationLabel(DateTime start, DateTime end) {
  final d = end.difference(start).abs();
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  final days = d.inDays;
  final hours = d.inHours - days * 24;
  return '${days}d ${hours}h';
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

FinalOutcome _finalOutcomeOf(RecommendationModel rec) {
  final direct = rec.finalOutcome;
  if (direct != null) return direct;
  return switch (rec.status) {
    SignalStatus.tp2Hit => FinalOutcome.fullWin,
    SignalStatus.tp1Hit => FinalOutcome.partialWin,
    SignalStatus.stopLossHit => FinalOutcome.loss,
    SignalStatus.expired => FinalOutcome.expired,
    SignalStatus.cancelled => FinalOutcome.cancelled,
    SignalStatus.active => FinalOutcome.cancelled,
  };
}

String _finalOutcomeLabel(FinalOutcome outcome) {
  return switch (outcome) {
    FinalOutcome.fullWin => 'Full Win',
    FinalOutcome.partialWin => 'Partial Win',
    FinalOutcome.loss => 'Loss',
    FinalOutcome.expired => 'Expired',
    FinalOutcome.cancelled => 'Cancelled',
  };
}

Color _finalOutcomeColor(FinalOutcome outcome) {
  return switch (outcome) {
    FinalOutcome.fullWin => AppColors.buy,
    FinalOutcome.partialWin => AppColors.watch,
    FinalOutcome.loss => AppColors.avoid,
    FinalOutcome.expired => AppColors.textSecondary,
    FinalOutcome.cancelled => AppColors.textSecondary,
  };
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
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
