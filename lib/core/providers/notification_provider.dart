import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:netgulf/core/bootstrap/app_initializer.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/providers/premium_provider.dart';
import 'package:netgulf/core/services/notification_service.dart';
import 'package:netgulf/features/gosi/providers/gosi_calculator_provider.dart';
import 'package:netgulf/features/notifications/gosi_notification_impact.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';

/// هل الإشعارات مفعّلة (محفوظة محلياً).
final notificationsEnabledProvider =
    StateNotifierProvider<NotificationNotifier, bool>(
  (ref) => NotificationNotifier(ref),
);

/// مزامنة تلقائية عند تغيّر Premium.
final notificationPremiumSyncProvider = Provider<void>((ref) {
  ref.listen<bool>(isPremiumProvider, (previous, isPremium) {
    if (ref.read(notificationsEnabledProvider)) {
      ref.read(notificationsEnabledProvider.notifier).syncAll();
    }
  });
});

class NotificationNotifier extends StateNotifier<bool> {
  NotificationNotifier(this._ref) : super(false) {
    _load();
  }

  final Ref _ref;

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

  Future<void> setEnabled(bool value) async {
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
      await syncAll();
    } else {
      await NotificationService.instance.cancelAll();
    }
  }

  /// مزامنة GOSI + يومي + Premium.
  Future<void> syncAll() async {
    if (!state) return;
    if (!NotificationService.instance.isInitialized) return;

    final salary = _ref.read(salaryNotifierProvider);
    final calculator = _ref.read(gosiCalculatorProvider);
    final warnings = buildUpcomingGosiNotificationItems(salary, calculator)
        .map((e) => e.warning)
        .toList();
    final isPremium = _ref.read(isPremiumProvider);

    await NotificationService.instance.syncAll(
      gosiWarnings: warnings,
      isPremium: isPremium,
    );
  }

  /// @deprecated استخدم [syncAll].
  Future<void> syncFromSalary(WidgetRef ref) => syncAll();
}

/// عناصر زيادة GOSI مع الأثر المالي.
final gosiNotificationItemsProvider =
    Provider<List<GosiNotificationItem>>((ref) {
  final salary = ref.watch(salaryNotifierProvider);
  final calculator = ref.read(gosiCalculatorProvider);
  return buildUpcomingGosiNotificationItems(salary, calculator);
});

/// شارة الجرس — زيادة خلال 30 يوماً.
final gosiAlertWithin30DaysProvider = Provider<bool>((ref) {
  final salary = ref.watch(salaryNotifierProvider);
  final calculator = ref.read(gosiCalculatorProvider);
  return hasGosiIncreaseWithinDays(salary, calculator, withinDays: 30);
});
