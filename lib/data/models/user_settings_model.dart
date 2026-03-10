import '../../core/constants/app_enums.dart';
import '../../core/utils/number_utils.dart';

class UserSettingsModel {
  final int scanIntervalSeconds;
  final int minConfidence;
  final RiskMode riskMode;
  final List<String> symbols;

  const UserSettingsModel({
    required this.scanIntervalSeconds,
    required this.minConfidence,
    required this.riskMode,
    required this.symbols,
  });

  Map<String, dynamic> toJson() => {
        'scanIntervalSeconds': scanIntervalSeconds,
        'minConfidence': minConfidence,
        'riskMode': riskMode.name,
        'symbols': symbols,
      };

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    final riskName = json['riskMode']?.toString() ?? RiskMode.balanced.name;
    return UserSettingsModel(
      scanIntervalSeconds: NumberUtils.safeParseInt(json['scanIntervalSeconds']),
      minConfidence: NumberUtils.safeParseInt(json['minConfidence']),
      riskMode: RiskMode.values.firstWhere(
        (e) => e.name == riskName,
        orElse: () => RiskMode.balanced,
      ),
      symbols: (json['symbols'] is List)
          ? (json['symbols'] as List).map((e) => e.toString()).toList()
          : <String>[],
    );
  }
}

