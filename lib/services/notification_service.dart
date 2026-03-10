import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/constants/app_enums.dart';
import '../data/models.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'signals_channel';
  static const _channelName = 'Signals';
  static const _channelDescription = 'Crypto signals notifications';

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> showSignal(RecommendationModel rec) async {
    final statusLabel = switch (rec.status) {
      SignalStatus.active => 'NEW',
      SignalStatus.tp1Hit => 'TP1',
      SignalStatus.tp2Hit => 'TP2',
      SignalStatus.stopLossHit => 'SL',
      SignalStatus.expired => 'EXPIRED',
      SignalStatus.cancelled => 'CANCELLED',
    };

    final title = '${rec.symbol} • ${rec.action.name.toUpperCase()} • $statusLabel • ${rec.confidence}%';

    final pnl = rec.pnlPct?.toStringAsFixed(2);
    final bodyParts = <String>[
      if (pnl != null) 'PnL: $pnl%',
      ...rec.reason.take(2),
    ];
    final body = bodyParts.isEmpty ? 'تحديث إشارة' : bodyParts.join(' • ');

    final color = switch (rec.action) {
      RecommendationAction.buy => 0xFF2ECC71,
      RecommendationAction.watch => 0xFFF1C40F,
      RecommendationAction.avoid => 0xFFE74C3C,
    };

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        color: Color(color),
      ),
    );

    await _plugin.show(
      '${rec.dedupeKey}-${rec.status.name}'.hashCode & 0x7fffffff,
      title,
      body,
      details,
    );
  }
}
