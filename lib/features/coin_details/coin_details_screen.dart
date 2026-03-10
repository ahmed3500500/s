import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_enums.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/confidence_bar.dart';
import '../../shared/widgets/signal_badge.dart';

class CoinDetailsScreen extends StatelessWidget {
  final RecommendationModel recommendation;

  const CoinDetailsScreen({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final r = recommendation;
    return AppScaffold(
      title: r.symbol,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      r.symbol,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    SignalBadge(action: r.action),
                  ],
                ),
                const SizedBox(height: 12),
                ConfidenceBar(confidence: r.confidence),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _InfoLine(label: 'السعر الحالي', value: r.currentPrice)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InfoText(
                        label: '24H',
                        value: '${r.change24h.toStringAsFixed(2)}%',
                        color: r.change24h >= 0 ? AppColors.buy : AppColors.avoid,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'وقت الإشارة: ${DateUtilsX.formatDateTime(r.createdAt)} • TF: ${r.timeframe}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniChip(label: _marketModeLabel(r.marketMode), color: _marketModeColor(r.marketMode)),
                    if (r.finalOutcome != null)
                      _MiniChip(
                        label: _finalOutcomeLabel(r.finalOutcome!),
                        color: _finalOutcomeColor(r.finalOutcome!),
                      ),
                    _MiniChip(label: _statusLabel(r.status), color: _statusColor(r.status)),
                    if (r.pnlPct != null)
                      _MiniChip(
                        label: 'PnL: ${r.pnlPct!.toStringAsFixed(2)}%',
                        color: r.pnlPct! >= 0 ? AppColors.buy : AppColors.avoid,
                      ),
                    if (r.closedAt != null)
                      _MiniChip(
                        label: 'Closed: ${DateUtilsX.formatDateTime(r.closedAt!)}',
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مستويات الدخول والخروج',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _InfoLine(label: 'Entry', value: r.entry)),
                    const SizedBox(width: 10),
                    Expanded(child: _InfoLine(label: 'SL', value: r.stopLoss, color: AppColors.avoid)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _InfoLine(label: 'TP1', value: r.takeProfit1, color: AppColors.buy)),
                    const SizedBox(width: 10),
                    Expanded(child: _InfoLine(label: 'TP2', value: r.takeProfit2, color: AppColors.buy)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trend Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ..._trendSummaryLines(r).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      e,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Risk Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ..._riskSummaryLines(r).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      e,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entry Quality',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ..._entryQualityLines(r).map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      e,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market Mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  _marketModeLabel(r.marketMode),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: _marketModeColor(r.marketMode), fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  _marketModeHint(r.marketMode),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why this signal?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                if (r.reason.isEmpty)
                  Text(
                    'لا توجد أسباب مسجلة.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  )
                else
                  ...r.reason.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(
                            child: Text(
                              e,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المؤشرات الفنية',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _InfoText(label: 'RSI', value: r.indicators.rsi.toStringAsFixed(1)),
                const SizedBox(height: 8),
                _InfoText(label: 'MACD', value: r.indicators.macd.toStringAsFixed(5)),
                const SizedBox(height: 8),
                _InfoText(label: 'MACD Signal', value: r.indicators.macdSignal.toStringAsFixed(5)),
                const SizedBox(height: 8),
                _InfoText(label: 'EMA21', value: r.indicators.ema21.toStringAsFixed(4)),
                const SizedBox(height: 8),
                _InfoText(label: 'EMA50', value: r.indicators.ema50.toStringAsFixed(4)),
                const SizedBox(height: 8),
                _InfoText(label: 'ATR', value: r.indicators.atr.toStringAsFixed(6)),
                const SizedBox(height: 8),
                _InfoText(label: 'Volume Ratio', value: r.indicators.volumeRatio.toStringAsFixed(2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;

  const _InfoLine({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return _InfoText(
      label: label,
      value: value.toStringAsFixed(4),
      color: color,
    );
  }
}

class _InfoText extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoText({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
        ),
      ],
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

List<String> _trendSummaryLines(RecommendationModel r) {
  final out = <String>[];
  if (r.indicators.ema21 > 0) {
    out.add(r.currentPrice >= r.indicators.ema21 ? 'السعر أعلى من EMA21' : 'السعر أسفل من EMA21');
  }
  if (r.indicators.ema50 > 0) {
    out.add(r.currentPrice >= r.indicators.ema50 ? 'السعر أعلى من EMA50' : 'السعر أسفل من EMA50');
  }
  if (r.indicators.macd >= r.indicators.macdSignal) {
    out.add('MACD داعم (خط الماكد أعلى من الإشارة)');
  } else {
    out.add('MACD غير داعم (خط الماكد أسفل الإشارة)');
  }
  out.add('RSI: ${r.indicators.rsi.toStringAsFixed(1)}');
  return out;
}

List<String> _riskSummaryLines(RecommendationModel r) {
  final out = <String>[];
  final atrPct = r.currentPrice <= 0 ? 0.0 : (r.indicators.atr / r.currentPrice) * 100.0;
  out.add('ATR: ${atrPct.toStringAsFixed(2)}%');
  final slPct = r.entry <= 0 ? 0.0 : ((r.entry - r.stopLoss) / r.entry) * 100.0;
  out.add('المخاطرة إلى SL: ${slPct.toStringAsFixed(2)}%');
  out.add('Risk Mode: ${r.riskModeAtOpen.name}');
  return out;
}

List<String> _entryQualityLines(RecommendationModel r) {
  final out = <String>[];
  final overEma21 = r.indicators.ema21 <= 0 ? 0.0 : ((r.currentPrice - r.indicators.ema21) / r.indicators.ema21) * 100.0;
  out.add('البعد عن EMA21: ${overEma21.toStringAsFixed(2)}%');
  out.add('Volume Ratio: ${r.indicators.volumeRatio.toStringAsFixed(2)}');
  if (r.reason.any((e) => e.contains('مقاومة'))) out.add('تنبيه: يوجد ذكر لمقاومة قريبة');
  if (r.reason.any((e) => e.contains('دخول متأخر'))) out.add('تنبيه: قد يكون الدخول متأخرًا');
  if (r.reason.any((e) => e.contains('سيولة'))) out.add('تنبيه: راقب السيولة قبل الدخول');
  return out;
}

String _marketModeHint(MarketMode mode) {
  return switch (mode) {
    MarketMode.bullish => 'السوق العام داعم، لكن حافظ على الانضباط.',
    MarketMode.neutral => 'السوق محايد. اجعل شروط BUY أصعب.',
    MarketMode.sideways => 'السوق عرضي. الأفضل تقليل الـ BUY والتركيز على الفرص الواضحة.',
    MarketMode.volatile => 'السوق متذبذب. إدارة المخاطر أهم من أي شيء.',
    MarketMode.bearish => 'السوق هابط. لا تعتمد على BUY إلا في حالات قوية جدًا.',
    MarketMode.weakLiquidity => 'السيولة العامة ضعيفة. لا تدخل إلا عند حجم قوي جدًا وتقلب منطقي.',
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
