import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:netgulf/core/constants/notification_constants.dart';
import 'package:netgulf/features/gosi/domain/logic/gosi_calculator.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// إشعارات محلية — يومية، GOSI، Premium.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  static const AndroidNotificationDetails _androidDaily =
      AndroidNotificationDetails(
    NotificationConstants.channelDailyId,
    NotificationConstants.channelDailyName,
    channelDescription: NotificationConstants.channelDailyDesc,
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  static const AndroidNotificationDetails _androidPremium =
      AndroidNotificationDetails(
    NotificationConstants.channelPremiumId,
    NotificationConstants.channelPremiumName,
    channelDescription: NotificationConstants.channelPremiumDesc,
    importance: Importance.high,
    priority: Priority.high,
  );

  static const AndroidNotificationDetails _androidAlerts =
      AndroidNotificationDetails(
    NotificationConstants.channelAlertsId,
    NotificationConstants.channelAlertsName,
    channelDescription: NotificationConstants.channelAlertsDesc,
    importance: Importance.high,
    priority: Priority.high,
  );

  static const NotificationDetails _dailyDetails = NotificationDetails(
    android: _androidDaily,
    iOS: DarwinNotificationDetails(),
  );

  static const NotificationDetails _premiumDetails = NotificationDetails(
    android: _androidPremium,
    iOS: DarwinNotificationDetails(),
  );

  static const NotificationDetails _alertDetails = NotificationDetails(
    android: _androidAlerts,
    iOS: DarwinNotificationDetails(),
  );

  /// تهيئة القنوات، المنطقة الزمنية، وطلب الإذن.
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      tz_data.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
      } catch (_) {
        tz.setLocalLocation(tz.local);
      }

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

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);

      _initialized = ok;
      return ok;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('NotificationService.initialize: $e\n$st');
      }
      return false;
    }
  }

  /// مزامنة كاملة — يومي + GOSI + Premium.
  Future<void> syncAll({
    required List<GosiRateWarning> gosiWarnings,
    required bool isPremium,
  }) async {
    if (!_initialized) return;

    await cancelAll();
    await _scheduleDailyFree();
    if (isPremium) {
      await _scheduleDailyPremium();
    }
    await scheduleYearlyReminder();
    await _scheduleGosiWarnings(gosiWarnings);
  }

  /// تذكيرات يومية للجميع.
  Future<void> _scheduleDailyFree() async {
    await _scheduleDaily(
      id: NotificationConstants.idDailySalary,
      title: NotificationConstants.dailySalaryTitle,
      body: NotificationConstants.dailySalaryBody,
      hour: 8,
      minute: 0,
      details: _dailyDetails,
    );
    await _scheduleDaily(
      id: NotificationConstants.idDailySocial,
      title: NotificationConstants.dailySocialTitle,
      body: NotificationConstants.dailySocialBody,
      hour: 12,
      minute: 30,
      details: _dailyDetails,
    );
    await _scheduleDaily(
      id: NotificationConstants.idDailyBrainRot,
      title: NotificationConstants.dailyBrainRotTitle,
      body: NotificationConstants.dailyBrainRotBody,
      hour: 20,
      minute: 0,
      details: _dailyDetails,
    );
  }

  /// تذكيرات يومية حصرية لـ Premium.
  Future<void> _scheduleDailyPremium() async {
    await _scheduleDaily(
      id: NotificationConstants.idPremiumInsights,
      title: NotificationConstants.premiumSalaryTitle,
      body: NotificationConstants.premiumSalaryBody,
      hour: 7,
      minute: 30,
      details: _premiumDetails,
    );
    await _scheduleDaily(
      id: NotificationConstants.idPremiumSocial,
      title: NotificationConstants.premiumSocialTitle,
      body: NotificationConstants.premiumSocialBody,
      hour: 15,
      minute: 0,
      details: _premiumDetails,
    );
    await _scheduleDaily(
      id: NotificationConstants.idPremiumBrainRot,
      title: NotificationConstants.premiumBrainRotTitle,
      body: NotificationConstants.premiumBrainRotBody,
      hour: 21,
      minute: 30,
      details: _premiumDetails,
    );
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required NotificationDetails details,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextDailyTime(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// جدولة تنبيه GOSI في تاريخ محدد (9:00 صباحاً).
  Future<void> scheduleGosiWarning(DateTime date, String message) async {
    if (!_initialized) return;

    final scheduled = _atTime(date.year, date.month, date.day, 9, 0);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      _idForDate(date),
      'تنبيه GOSI — NetGulf',
      message,
      scheduled,
      _alertDetails,
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
      NotificationConstants.idYearlyReminder,
      'NetGulf — مراجعة سنوية',
      'راجع راتبك — GOSI تغيرت؟',
      _atTime(next.year, next.month, next.day, 9, 0),
      _alertDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _scheduleGosiWarnings(List<GosiRateWarning> warnings) async {
    for (final w in warnings) {
      final phase = w.phaseYear;
      final monthLabel = 'يوليو $phase';

      final dayOf = _atTime(
        w.effectiveDate.year,
        w.effectiveDate.month,
        w.effectiveDate.day,
        9,
        0,
      );
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

  /// @deprecated استخدم [syncAll].
  Future<void> syncScheduledAlerts(List<GosiRateWarning> warnings) =>
      syncAll(gosiWarnings: warnings, isPremium: false);

  /// إشعار فوري — Pomodoro (انتهاء شغل / راحة).
  Future<void> showPomodoroComplete({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    try {
      await _plugin.show(
        NotificationConstants.idPomodoro,
        title,
        body,
        _alertDetails,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('NotificationService.showPomodoroComplete: $e\n$st');
      }
    }
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  int _idForDate(DateTime date) =>
      NotificationConstants.idGosiBase +
      date.year * 10000 +
      date.month * 100 +
      date.day;

  tz.TZDateTime _nextDailyTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _atTime(int y, int m, int d, int h, int min) {
    return tz.TZDateTime(tz.local, y, m, d, h, min);
  }
}
