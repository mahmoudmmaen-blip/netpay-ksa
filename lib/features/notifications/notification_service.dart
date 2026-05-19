import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:netgulf/features/gosi/domain/logic/gosi_calculator.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// إشعارات محلية — تذكير سنوي وتنبيهات زيادة GOSI.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _idYearlyReminder = 9001;
  static const int _idGosiBase = 9100;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'netpay_alerts',
    'تنبيهات NetGulf',
    channelDescription: 'تذكيرات GOSI ومراجعة الراتب',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  /// تهيئة القناة والمنطقة الزمنية.
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.local);

      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );

      final ok = await _plugin.initialize(
            initSettings,
            onDidReceiveNotificationResponse: (_) {},
          ) ??
          false;

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();

      _initialized = ok;
      return ok;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('NotificationService.initialize: $e\n$st');
      }
      return false;
    }
  }

  /// جدولة تنبيه زيادة GOSI في تاريخ محدد (9:00 صباحاً محلياً).
  Future<void> scheduleGosiWarning(DateTime date, String message) async {
    if (!_initialized) return;

    final scheduled = _atNineAm(date);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      _idForDate(date),
      'تنبيه GOSI — NetGulf',
      message,
      scheduled,
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// تذكير سنوي لمراجعة الراتب.
  Future<void> scheduleYearlyReminder() async {
    if (!_initialized) return;

    final now = DateTime.now();
    var next = DateTime(now.year + 1, now.month, now.day, 9);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 365));
    }

    await _plugin.zonedSchedule(
      _idYearlyReminder,
      'NetGulf — مراجعة سنوية',
      'راجع راتبك — GOSI تغيرت؟',
      _atNineAm(next),
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// يجدول كل تنبيهات GOSI القادمة + التذكير السنوي.
  Future<void> syncScheduledAlerts(List<GosiRateWarning> warnings) async {
    if (!_initialized) return;

    await cancelAll();

    await scheduleYearlyReminder();

    for (final w in warnings) {
      final phase = w.phaseYear;
      final monthLabel = 'يوليو $phase';

      final dayOf = _atNineAm(w.effectiveDate);
      if (dayOf.isAfter(tz.TZDateTime.now(tz.local))) {
        await scheduleGosiWarning(
          w.effectiveDate,
          'اليوم: زيادة GOSI اعتباراً من $monthLabel. راجع راتبك في NetGulf.',
        );
      }

      final thirtyBefore = w.effectiveDate.subtract(const Duration(days: 30));
      if (thirtyBefore.isAfter(DateTime.now())) {
        await scheduleGosiWarning(
          thirtyBefore,
          'بعد 30 يوماً: زيادة GOSI في $monthLabel. جهّز راتبك وقارن الصافي.',
        );
      }

      final sevenBefore = w.effectiveDate.subtract(const Duration(days: 7));
      if (sevenBefore.isAfter(DateTime.now())) {
        await scheduleGosiWarning(
          sevenBefore,
          'بعد أسبوع: زيادة GOSI في $monthLabel. راجع التأمينات في التطبيق.',
        );
      }
    }
  }

  /// إلغاء كل الإشعارات المجدولة.
  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  int _idForDate(DateTime date) =>
      _idGosiBase + date.year * 10000 + date.month * 100 + date.day;

  tz.TZDateTime _atNineAm(DateTime date) {
    final local = tz.local;
    return tz.TZDateTime(
      local,
      date.year,
      date.month,
      date.day,
      9,
    );
  }
}
