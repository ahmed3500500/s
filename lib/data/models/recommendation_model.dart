import '../../core/constants/app_enums.dart';
import '../../core/utils/number_utils.dart';
import 'indicator_model.dart';

class RecommendationModel {
  final String id;
  final String dedupeKey;
  final String symbol;
  final RecommendationAction action;
  final int confidence;
  final double currentPrice;
  final double entry;
  final double stopLoss;
  final double takeProfit1;
  final double takeProfit2;
  final List<String> reason;
  final DateTime createdAt;
  final DateTime? closedAt;
  final DateTime? tp1HitAt;
  final DateTime? tp2HitAt;
  final DateTime? slHitAt;
  final double? closedPrice;
  final double? pnlPct;
  final int? durationMinutes;
  final String? result;
  final FinalOutcome? finalOutcome;
  final SignalStatus status;
  final String timeframe;
  final IndicatorModel indicators;
  final double change24h;
  final double volume24h;
  final MarketMode marketMode;
  final RiskMode riskModeAtOpen;

  const RecommendationModel({
    required this.id,
    required this.dedupeKey,
    required this.symbol,
    required this.action,
    required this.confidence,
    required this.currentPrice,
    required this.entry,
    required this.stopLoss,
    required this.takeProfit1,
    required this.takeProfit2,
    required this.reason,
    required this.createdAt,
    required this.closedAt,
    this.tp1HitAt,
    this.tp2HitAt,
    this.slHitAt,
    required this.closedPrice,
    required this.pnlPct,
    this.durationMinutes,
    this.result,
    this.finalOutcome,
    required this.status,
    required this.timeframe,
    required this.indicators,
    required this.change24h,
    required this.volume24h,
    required this.marketMode,
    required this.riskModeAtOpen,
  });

  String get signalKey => dedupeKey;

  Map<String, dynamic> toJson() => {
        'id': id,
        'dedupeKey': dedupeKey,
        'symbol': symbol,
        'action': action.name,
        'confidence': confidence,
        'currentPrice': currentPrice,
        'entry': entry,
        'stopLoss': stopLoss,
        'takeProfit1': takeProfit1,
        'takeProfit2': takeProfit2,
        'reason': reason,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'closedAt': closedAt?.millisecondsSinceEpoch,
        'tp1HitAt': tp1HitAt?.millisecondsSinceEpoch,
        'tp2HitAt': tp2HitAt?.millisecondsSinceEpoch,
        'slHitAt': slHitAt?.millisecondsSinceEpoch,
        'closedPrice': closedPrice,
        'pnlPct': pnlPct,
        'durationMinutes': durationMinutes,
        'result': result,
        'finalOutcome': finalOutcome?.name,
        'status': status.name,
        'timeframe': timeframe,
        'indicators': indicators.toJson(),
        'change24h': change24h,
        'volume24h': volume24h,
        'marketMode': marketMode.name,
        'riskModeAtOpen': riskModeAtOpen.name,
      };

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    final actionName = json['action']?.toString() ?? RecommendationAction.avoid.name;
    final statusName = json['status']?.toString() ?? SignalStatus.active.name;
    final marketModeName = json['marketMode']?.toString() ?? MarketMode.neutral.name;
    final riskName = json['riskModeAtOpen']?.toString() ?? RiskMode.balanced.name;
    final finalOutcomeName = json['finalOutcome']?.toString() ?? json['result']?.toString();
    return RecommendationModel(
      id: json['id']?.toString() ?? '',
      dedupeKey: json['dedupeKey']?.toString() ??
          '${json['symbol']?.toString() ?? ''}-${json['timeframe']?.toString() ?? ''}-$actionName',
      symbol: json['symbol']?.toString() ?? '',
      action: RecommendationAction.values.firstWhere(
        (e) => e.name == actionName,
        orElse: () => RecommendationAction.avoid,
      ),
      confidence: NumberUtils.safeParseInt(json['confidence']),
      currentPrice: NumberUtils.safeParseDouble(json['currentPrice']),
      entry: NumberUtils.safeParseDouble(json['entry']),
      stopLoss: NumberUtils.safeParseDouble(json['stopLoss']),
      takeProfit1: NumberUtils.safeParseDouble(json['takeProfit1']),
      takeProfit2: NumberUtils.safeParseDouble(json['takeProfit2']),
      reason: (json['reason'] is List)
          ? (json['reason'] as List).map((e) => e.toString()).toList()
          : <String>[],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        NumberUtils.safeParseInt(json['createdAt']),
      ),
      closedAt: json['closedAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(NumberUtils.safeParseInt(json['closedAt'])),
      tp1HitAt: json['tp1HitAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(NumberUtils.safeParseInt(json['tp1HitAt'])),
      tp2HitAt: json['tp2HitAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(NumberUtils.safeParseInt(json['tp2HitAt'])),
      slHitAt: json['slHitAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(NumberUtils.safeParseInt(json['slHitAt'])),
      closedPrice: json['closedPrice'] == null ? null : NumberUtils.safeParseDouble(json['closedPrice']),
      pnlPct: json['pnlPct'] == null ? null : NumberUtils.safeParseDouble(json['pnlPct']),
      durationMinutes: json['durationMinutes'] == null ? null : NumberUtils.safeParseInt(json['durationMinutes']),
      result: json['result']?.toString(),
      finalOutcome: finalOutcomeName == null
          ? null
          : FinalOutcome.values.firstWhere(
              (e) => e.name == finalOutcomeName,
              orElse: () => FinalOutcome.loss,
            ),
      status: SignalStatus.values.firstWhere(
        (e) => e.name == statusName,
        orElse: () => SignalStatus.active,
      ),
      timeframe: json['timeframe']?.toString() ?? '',
      indicators: IndicatorModel.fromJson(
        (json['indicators'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      change24h: NumberUtils.safeParseDouble(json['change24h']),
      volume24h: NumberUtils.safeParseDouble(json['volume24h']),
      marketMode: MarketMode.values.firstWhere(
        (e) => e.name == marketModeName,
        orElse: () => MarketMode.neutral,
      ),
      riskModeAtOpen: RiskMode.values.firstWhere(
        (e) => e.name == riskName,
        orElse: () => RiskMode.balanced,
      ),
    );
  }

  RecommendationModel copyWith({
    int? confidence,
    double? currentPrice,
    List<String>? reason,
    DateTime? closedAt,
    DateTime? tp1HitAt,
    DateTime? tp2HitAt,
    DateTime? slHitAt,
    double? closedPrice,
    double? pnlPct,
    int? durationMinutes,
    String? result,
    FinalOutcome? finalOutcome,
    SignalStatus? status,
    RecommendationAction? action,
    MarketMode? marketMode,
  }) {
    return RecommendationModel(
      id: id,
      dedupeKey: dedupeKey,
      symbol: symbol,
      action: action ?? this.action,
      confidence: confidence ?? this.confidence,
      currentPrice: currentPrice ?? this.currentPrice,
      entry: entry,
      stopLoss: stopLoss,
      takeProfit1: takeProfit1,
      takeProfit2: takeProfit2,
      reason: reason ?? this.reason,
      createdAt: createdAt,
      closedAt: closedAt ?? this.closedAt,
      tp1HitAt: tp1HitAt ?? this.tp1HitAt,
      tp2HitAt: tp2HitAt ?? this.tp2HitAt,
      slHitAt: slHitAt ?? this.slHitAt,
      closedPrice: closedPrice ?? this.closedPrice,
      pnlPct: pnlPct ?? this.pnlPct,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      result: result ?? this.result,
      finalOutcome: finalOutcome ?? this.finalOutcome,
      status: status ?? this.status,
      timeframe: timeframe,
      indicators: indicators,
      change24h: change24h,
      volume24h: volume24h,
      marketMode: marketMode ?? this.marketMode,
      riskModeAtOpen: riskModeAtOpen,
    );
  }
}
