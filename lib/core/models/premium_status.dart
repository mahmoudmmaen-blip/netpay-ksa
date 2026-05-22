import 'package:equatable/equatable.dart';

/// حالة اشتراك Premium للعرض في الواجهة.
enum PremiumSubscriptionState {
  /// اشتراك ساري — كل الميزات + بدون إعلانات.
  active,

  /// انتهى الاشتراك — يُعرض زر تجديد.
  expired,

  /// لم يشترك من قبل.
  notSubscribed,
}

/// حالة اشتراك Premium المحفوظة محلياً.
class PremiumStatus extends Equatable {
  const PremiumStatus({
    this.premiumStatus = false,
    this.expiresAt,
  });

  /// علامة التخزين — true إذا اشترك سابقاً (حتى لو انتهى).
  final bool premiumStatus;
  final DateTime? expiresAt;

  /// اشتراك ساري وغير منتهٍ.
  bool get isValid {
    if (!premiumStatus) return false;
    if (expiresAt == null) return true;
    return expiresAt!.isAfter(DateTime.now());
  }

  /// alias — للاستخدام في [showAdsProvider] والواجهة.
  bool get isPremium => isValid;

  /// حالة العرض الموحّدة عبر التطبيق.
  PremiumSubscriptionState get subscriptionState {
    if (!premiumStatus) return PremiumSubscriptionState.notSubscribed;
    if (isValid) return PremiumSubscriptionState.active;
    return PremiumSubscriptionState.expired;
  }

  /// أيام متبقية (null = غير محدود أو غير مشترك).
  int? get daysRemaining {
    if (!isValid || expiresAt == null) return null;
    return expiresAt!.difference(DateTime.now()).inDays.clamp(0, 9999);
  }

  PremiumStatus copyWith({
    bool? premiumStatus,
    DateTime? expiresAt,
    bool clearExpiresAt = false,
  }) {
    return PremiumStatus(
      premiumStatus: premiumStatus ?? this.premiumStatus,
      expiresAt: clearExpiresAt ? null : (expiresAt ?? this.expiresAt),
    );
  }

  @override
  List<Object?> get props => [premiumStatus, expiresAt];
}
