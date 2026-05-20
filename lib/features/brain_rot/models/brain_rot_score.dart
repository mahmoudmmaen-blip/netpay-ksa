import 'package:equatable/equatable.dart';

/// درجة Brain Rot — 0 (ممتاز) إلى 100 (يحتاج انتباه).
class BrainRotScore extends Equatable {
  const BrainRotScore({
    required this.score,
    required this.updatedAt,
    this.socialMinutesToday = 0,
    this.tipAr = '',
    this.lastResetDate,
  });

  final int score;
  final DateTime updatedAt;
  final int socialMinutesToday;
  final String tipAr;

  /// آخر إعادة تعيين يومية — last daily reset.
  final DateTime? lastResetDate;

  /// لون الدائرة — أخضر منخفض، أحمر مرتفع.
  bool get isHealthy => score <= 40;
  bool get isWarning => score > 40 && score <= 70;
  bool get isCritical => score > 70;

  static BrainRotScore get initial => BrainRotScore(
        score: 42,
        updatedAt: DateTime.now(),
        socialMinutesToday: 90,
        tipAr: 'قلّل السوشيال ساعة اليوم — ركّز على راتبك الحقيقي',
      );

  BrainRotScore copyWith({
    int? score,
    DateTime? updatedAt,
    int? socialMinutesToday,
    String? tipAr,
    DateTime? lastResetDate,
    bool clearLastResetDate = false,
  }) {
    return BrainRotScore(
      score: score ?? this.score,
      updatedAt: updatedAt ?? this.updatedAt,
      socialMinutesToday: socialMinutesToday ?? this.socialMinutesToday,
      tipAr: tipAr ?? this.tipAr,
      lastResetDate: clearLastResetDate
          ? null
          : (lastResetDate ?? this.lastResetDate),
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'updatedAt': updatedAt.toIso8601String(),
        'socialMinutesToday': socialMinutesToday,
        'tipAr': tipAr,
        if (lastResetDate != null)
          'lastResetDate': lastResetDate!.toIso8601String(),
      };

  factory BrainRotScore.fromJson(Map<String, dynamic> json) {
    return BrainRotScore(
      score: (json['score'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      socialMinutesToday: (json['socialMinutesToday'] as num?)?.toInt() ?? 0,
      tipAr: json['tipAr'] as String? ?? '',
      lastResetDate: json['lastResetDate'] != null
          ? DateTime.tryParse(json['lastResetDate'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props =>
      [score, updatedAt, socialMinutesToday, tipAr, lastResetDate];
}
