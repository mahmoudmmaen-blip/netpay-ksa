import 'package:equatable/equatable.dart';

/// درجة Brain Rot — 0 (ممتاز) إلى 100 (يحتاج انتباه).
class BrainRotScore extends Equatable {
  const BrainRotScore({
    required this.score,
    required this.updatedAt,
    this.socialMinutesToday = 0,
    this.tipAr = '',
  });

  final int score;
  final DateTime updatedAt;
  final int socialMinutesToday;
  final String tipAr;

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
  }) {
    return BrainRotScore(
      score: score ?? this.score,
      updatedAt: updatedAt ?? this.updatedAt,
      socialMinutesToday: socialMinutesToday ?? this.socialMinutesToday,
      tipAr: tipAr ?? this.tipAr,
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'updatedAt': updatedAt.toIso8601String(),
        'socialMinutesToday': socialMinutesToday,
        'tipAr': tipAr,
      };

  factory BrainRotScore.fromJson(Map<String, dynamic> json) {
    return BrainRotScore(
      score: (json['score'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      socialMinutesToday: (json['socialMinutesToday'] as num?)?.toInt() ?? 0,
      tipAr: json['tipAr'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props =>
      [score, updatedAt, socialMinutesToday, tipAr];
}
