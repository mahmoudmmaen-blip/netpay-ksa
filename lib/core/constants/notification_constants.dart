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

  static const int idDailySalary = 8001;
  static const int idDailySocial = 8002;
  static const int idDailyBrainRot = 8003;

  /// تذكيرات يومية — Premium فقط.
  static const int idPremiumInsights = 8101;
  static const int idPremiumSocial = 8102;
  static const int idPremiumBrainRot = 8103;

  // ── Daily messages (free) ────────────────────────────────────────────────────

  static const String dailySalaryTitle = 'كم راتبك اليوم؟';
  static const String dailySalaryBody =
      'افتح NetGulf واحسب صافي راتبك بعد GOSI في ثوانٍ.';

  static const String dailySocialTitle = 'قلّل وقت السوشيال';
  static const String dailySocialBody =
      'ساعة أقل على السوشيال اليوم = تركيز أفضل على راتبك الحقيقي.';

  static const String dailyBrainRotTitle = 'Brain Rot Tip';
  static const String dailyBrainRotBody =
      'حدّث Brain Rot Score — هل وقت السوشيال يؤثر على قراراتك المالية؟';

  // ── Daily messages (Premium) ─────────────────────────────────────────────────

  static const String premiumSalaryTitle = 'Premium — راتبك اليوم';
  static const String premiumSalaryBody =
      'راجع تحليلاتك المتقدمة والسجل الكامل بدون إعلانات.';

  static const String premiumSocialTitle = 'Premium — وازن وقتك';
  static const String premiumSocialBody =
      'تذكير ذكي: قلّل السوشيال وافتح مقارنة العروض الكاملة.';

  static const String premiumBrainRotTitle = 'Premium — Brain Rot Pro';
  static const String premiumBrainRotBody =
      'تحليل أعمق لعاداتك — حدّث Brain Rot Score وتابع تقدمك أسبوعياً.';

  // ── Legacy aliases ─────────────────────────────────────────────────────────

  static const String dailyHabitsTitle = dailySocialTitle;
  static const String dailyHabitsBody = dailySocialBody;
  static const String premiumInsightsTitle = premiumSalaryTitle;
  static const String premiumInsightsBody = premiumSalaryBody;
  static const String premiumBrainRotTitleLegacy = premiumBrainRotTitle;
  static const String premiumBrainRotBodyLegacy = premiumBrainRotBody;
}
