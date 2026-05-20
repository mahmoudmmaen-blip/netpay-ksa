/// ثوابت الإشعارات المحلية — معرّفات، قنوات، نصوص.
abstract final class NotificationConstants {
  NotificationConstants._();

  // ── Android channels ───────────────────────────────────────────────────────

  static const String channelDailyId = 'netgulf_daily';
  static const String channelDailyName = 'تذكيرات يومية';
  static const String channelDailyDesc = 'تذكيرات يومية لمراجعة الراتب والعادات';

  static const String channelPremiumId = 'netgulf_premium';
  static const String channelPremiumName = 'Premium — NetGulf';
  static const String channelPremiumDesc = 'إشعارات حصرية لمشتركي Premium';

  static const String channelAlertsId = 'netgulf_alerts';
  static const String channelAlertsName = 'تنبيهات NetGulf';
  static const String channelAlertsDesc = 'تذكيرات GOSI ومراجعة الراتب';

  // ── Notification IDs ─────────────────────────────────────────────────────────

  static const int idYearlyReminder = 9001;
  static const int idGosiBase = 9100;

  /// تذكيرات يومية — مجاني.
  static const int idDailySalary = 8001;
  static const int idDailyHabits = 8002;
  static const int idDailyBrainRot = 8003;

  /// تذكيرات يومية — Premium فقط.
  static const int idPremiumInsights = 8101;
  static const int idPremiumBrainRot = 8102;

  // ── Daily messages (free) ────────────────────────────────────────────────────

  static const String dailySalaryTitle = 'كم راتبك اليوم؟';
  static const String dailySalaryBody =
      'افتح NetGulf واحسب صافي راتبك بعد GOSI في ثوانٍ.';

  static const String dailyHabitsTitle = 'حافظ على عاداتك';
  static const String dailyHabitsBody =
      'دقيقة واحدة لمراجعة عاداتك المالية — استمر على المسار الصحيح.';

  static const String dailyBrainRotTitle = 'Brain Rot Score';
  static const String dailyBrainRotBody =
      'هل تعرف صافي راتبك الحقيقي؟ حدّث Brain Rot Score الآن.';

  // ── Daily messages (Premium) ─────────────────────────────────────────────────

  static const String premiumInsightsTitle = 'Premium — رؤى راتبك';
  static const String premiumInsightsBody =
      'راجع تحليلاتك المتقدمة والسجل الكامل بدون إعلانات.';

  static const String premiumBrainRotTitle = 'Premium — Brain Rot Score';
  static const String premiumBrainRotBody =
      'كم وفّرت هذا الأسبوع؟ افتح NetGulf Premium وقارن عروضك.';
}
