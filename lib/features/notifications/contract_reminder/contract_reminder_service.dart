import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// نتيجة جدولة تنبيه انتهاء العقد.
enum ContractReminderScheduleResult {
  scheduled,
  notSupportedOnWeb,
  permissionDenied,
  dateInPast,
  failed,
}

/// تنبيه محلي قبل انتهاء عقد العمل بـ 30 يوماً.
abstract final class ContractReminderService {
  ContractReminderService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _notificationId = 9201;
  static const _daysBeforeExpiry = 30;

  static const _title = 'عقدك ينتهي قريباً';
  static const _body =
      'تبقى 30 يوماً على انتهاء عقد عملك — راجع خياراتك';

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'netgulf_contract_reminder',
    'تنبيه انتهاء العقد',
    channelDescription: 'تذكير قبل انتهاء عقد العمل',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  static bool _initialized = false;
  static bool _tzReady = false;

  static void _ensureTimeZone() {
    if (_tzReady) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }
    _tzReady = true;
  }

  static tz.TZDateTime _toTz(DateTime date) {
    return tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
    );
  }

  /// نهاية العقد = اليوم + [contractDurationMonths] شهر.
  static DateTime contractEndDate(int contractDurationMonths) {
    final now = DateTime.now();
    var month = now.month + contractDurationMonths;
    var year = now.year;
    while (month > 12) {
      month -= 12;
      year++;
    }
    final day = now.day.clamp(1, 28);
    return DateTime(year, month, day, 9, 0);
  }

  /// موعد التنبيه = نهاية العقد − 30 يوماً.
  static DateTime reminderDate(int contractDurationMonths) {
    return contractEndDate(contractDurationMonths)
        .subtract(const Duration(days: _daysBeforeExpiry));
  }

  static Future<bool> _ensureInitialized() async {
    if (_initialized) return true;

    _ensureTimeZone();

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    final ok = await _plugin.initialize(initSettings) ?? false;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted =
        await android?.requestNotificationsPermission() ?? true;

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    _initialized = ok && androidGranted && iosGranted;
    return _initialized;
  }

  /// جدولة التنبيه — يعيد حالة التنفيذ.
  static Future<ContractReminderScheduleResult> scheduleExpiryReminder(
    int contractDurationMonths,
  ) async {
    if (kIsWeb) {
      return ContractReminderScheduleResult.notSupportedOnWeb;
    }

    try {
      final scheduledLocal = reminderDate(contractDurationMonths);
      final scheduled = _toTz(scheduledLocal);
      final now = tz.TZDateTime.now(tz.local);

      if (!scheduled.isAfter(now)) {
        return ContractReminderScheduleResult.dateInPast;
      }

      final ready = await _ensureInitialized();
      if (!ready) {
        return ContractReminderScheduleResult.permissionDenied;
      }

      await _plugin.zonedSchedule(
        _notificationId,
        _title,
        _body,
        scheduled,
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      return ContractReminderScheduleResult.scheduled;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ContractReminderService.schedule: $e\n$st');
      }
      return ContractReminderScheduleResult.failed;
    }
  }
}
