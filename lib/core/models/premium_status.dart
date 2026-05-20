import 'package:equatable/equatable.dart';

/// حالة اشتراك Premium المحفوظة محلياً.
class PremiumStatus extends Equatable {
  const PremiumStatus({
    this.premiumStatus = false,
    this.expiresAt,
  });

  /// هل Premium مفعّل وغير منتهٍ.
  final bool premiumStatus;
  final DateTime? expiresAt;

  bool get isValid {
    if (!premiumStatus) return false;
    if (expiresAt == null) return true;
    return expiresAt!.isAfter(DateTime.now());
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
