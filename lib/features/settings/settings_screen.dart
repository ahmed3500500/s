import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_defaults.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_enums.dart';
import '../../providers/scanner_provider.dart';
import '../../providers/settings_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? _minConfidenceDraft;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'الإعدادات',
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final s = settings.settings;
          _minConfidenceDraft ??= s.minConfidence;

          final enabledSymbols = s.symbols.toSet();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scanner',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'التحديث كل',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        DropdownButton<int>(
                          value: s.scanIntervalSeconds,
                          items: const [
                            DropdownMenuItem(value: 60, child: Text('1 دقيقة')),
                            DropdownMenuItem(value: 180, child: Text('3 دقائق')),
                            DropdownMenuItem(value: 300, child: Text('5 دقائق')),
                            DropdownMenuItem(value: 600, child: Text('10 دقائق')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            settings.setScanIntervalSeconds(value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'الحد الأدنى للثقة: ${_minConfidenceDraft!}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Slider(
                      value: _minConfidenceDraft!.toDouble(),
                      min: 50,
                      max: 95,
                      divisions: 45,
                      onChanged: (v) => setState(() => _minConfidenceDraft = v.round()),
                      onChangeEnd: (v) => settings.setMinConfidence(v.round()),
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
                      'Background',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<bool>(
                      future: FlutterForegroundTask.isIgnoringBatteryOptimizations,
                      builder: (context, snap) {
                        final ignoring = snap.data;
                        final label = ignoring == null
                            ? 'Battery Optimization: —'
                            : (ignoring ? 'Battery Optimization: Disabled' : 'Battery Optimization: Enabled');
                        final color = ignoring == true ? AppColors.buy : AppColors.watch;
                        return Text(
                          label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              await FlutterForegroundTask.requestIgnoreBatteryOptimization();
                              if (!context.mounted) return;
                              setState(() {});
                            },
                            child: const Text('Disable Battery Optimization'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Consumer<ScannerProvider>(
                      builder: (context, scanner, _) {
                        return Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: scanner.status.running ? null : () => scanner.start(),
                                child: const Text('Enable background mode'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: scanner.status.running ? () => scanner.stop() : null,
                                child: const Text('Stop background mode'),
                              ),
                            ),
                          ],
                        );
                      },
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
                      'نمط المخاطرة',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<RiskMode>(
                      groupValue: s.riskMode,
                      onChanged: (v) => v == null ? null : settings.setRiskMode(v),
                      child: Column(
                        children: [
                          RadioListTile<RiskMode>(
                            value: RiskMode.conservative,
                            title: const Text('Conservative'),
                            subtitle: Text(
                              'إشارات أقل وثقة أعلى',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          RadioListTile<RiskMode>(
                            value: RiskMode.balanced,
                            title: const Text('Balanced'),
                            subtitle: Text(
                              'توازن بين الفرص والفلترة',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          RadioListTile<RiskMode>(
                            value: RiskMode.aggressive,
                            title: const Text('Aggressive'),
                            subtitle: Text(
                              'إشارات أكثر وحساسية أعلى',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
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
                      'العملات',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'فعّل 10 إلى 20 عملة في البداية.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ...AppDefaults.marketSymbols.map((symbol) {
                      final enabled = enabledSymbols.contains(symbol);
                      return CheckboxListTile(
                        value: enabled,
                        title: Text(symbol),
                        onChanged: (v) {
                          final next = enabledSymbols.toSet();
                          if (v == true) {
                            next.add(symbol);
                          } else {
                            next.remove(symbol);
                          }
                          settings.setSymbols(next.toList());
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
