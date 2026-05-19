import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netpay_ksa/core/bootstrap/app_initializer.dart';
import 'package:netpay_ksa/core/constants/app_constants.dart';
import 'package:netpay_ksa/features/gosi/providers/gosi_calculator_provider.dart';
import 'package:netpay_ksa/features/notifications/gosi_notification_impact.dart';
import 'package:netpay_ksa/features/notifications/notification_service.dart';
import 'package:netpay_ksa/features/salary_calculator/providers/salary_notifier.dart';

/// هل التنبيهات مفعّلة (محفوظة محلياً).
final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsEnabledNotifier, bool>(
  (ref) => NotificationsEnabledNotifier(),
);

class NotificationsEnabledNotifier extends StateNotifier<bool> {
  NotificationsEnabledNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    try {
      final enabled = AppInitializer.prefs.getBool(
            AppConstants.prefNotificationsEnabled,
          ) ??
          false;
      state = enabled;
    } catch (_) {
      state = false;
    }
  }

  Future<void> setEnabled(bool value, WidgetRef ref) async {
    state = value;
    try {
      await AppInitializer.prefs.setBool(
        AppConstants.prefNotificationsEnabled,
        value,
      );
    } catch (_) {
      return;
    }

    if (!NotificationService.instance.isInitialized) return;

    if (value) {
      await syncFromSalary(ref);
    } else {
      await NotificationService.instance.cancelAll();
    }
  }

  Future<void> syncFromSalary(WidgetRef ref) async {
    if (!state) return;
    final salary = ref.read(salaryNotifierProvider);
    final calculator = ref.read(gosiCalculatorProvider);
    final warnings = buildUpcomingGosiNotificationItems(salary, calculator)
        .map((e) => e.warning)
        .toList();
    await NotificationService.instance.syncScheduledAlerts(warnings);
  }
}

/// عناصر زيادة GOSI مع الأثر المالي.
final gosiNotificationItemsProvider = Provider<List<GosiNotificationItem>>((ref) {
  final salary = ref.watch(salaryNotifierProvider);
  final calculator = ref.read(gosiCalculatorProvider);
  return buildUpcomingGosiNotificationItems(salary, calculator);
});

/// شارة الجرس — زيادة خلال 30 يوماً (بغض النظر عن تفعيل الإشعارات).
final gosiAlertWithin30DaysProvider = Provider<bool>((ref) {
  final salary = ref.watch(salaryNotifierProvider);
  final calculator = ref.read(gosiCalculatorProvider);
  return hasGosiIncreaseWithinDays(salary, calculator, withinDays: 30);
});
