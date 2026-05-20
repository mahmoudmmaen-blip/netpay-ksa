import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:netgulf/core/bootstrap/app_initializer.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/features/brain_rot/models/brain_rot_level.dart';
import 'package:netgulf/features/brain_rot/models/brain_rot_score.dart';

const _hiveKeyScore = 'brain_rot_score';

/// إدارة Brain Rot — Hive + Riverpod.
/// Brain Rot state — Hive persistence + Riverpod.
class BrainRotNotifier extends StateNotifier<BrainRotScore> {
  BrainRotNotifier() : super(BrainRotScore.initial) {
    _init();
  }

  Box<dynamic>? get _box {
    if (!AppInitializer.isHiveReady) return null;
    if (!Hive.isBoxOpen(AppConstants.hiveBoxBrainRot)) return null;
    return Hive.box<dynamic>(AppConstants.hiveBoxBrainRot);
  }

  Future<void> _init() async {
    await _load();
    await resetDaily();
  }

  /// الدرجة الحالية 0–100.
  int get currentScore => state.score;

  Future<void> _load() async {
    try {
      await _ensureBox();
      final raw = _box?.get(_hiveKeyScore);
      if (raw is Map) {
        state = BrainRotScore.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('BrainRotNotifier._load: $e\n$st');
    }
  }

  Future<void> _ensureBox() async {
    if (!AppInitializer.isHiveReady) return;
    if (!Hive.isBoxOpen(AppConstants.hiveBoxBrainRot)) {
      await Hive.openBox<dynamic>(AppConstants.hiveBoxBrainRot);
    }
  }

  /// تحديث الدرجة وحفظها.
  Future<void> updateScore(int score, {int? socialMinutes}) async {
    final clamped = score.clamp(0, 100);
    final next = state.copyWith(
      score: clamped,
      updatedAt: DateTime.now(),
      socialMinutesToday: socialMinutes ?? state.socialMinutesToday,
      tipAr: _tipForScore(clamped),
    );
    state = next;
    await _persist(next);
  }

  /// إعادة تعيين يومية — دقائق سوشيال + خفض طفيف للدرجة.
  Future<void> resetDaily() async {
    try {
      final now = DateTime.now();
      final last = state.lastResetDate;
      if (last != null && _isSameDay(last, now)) return;

      final refreshed = state.copyWith(
        socialMinutesToday: 0,
        lastResetDate: now,
        score: (state.score * 0.85).round().clamp(0, 100),
        updatedAt: now,
        tipAr: _tipForScore((state.score * 0.85).round().clamp(0, 100)),
      );
      state = refreshed;
      await _persist(refreshed);
    } catch (e, st) {
      if (kDebugMode) debugPrint('BrainRotNotifier.resetDaily: $e\n$st');
    }
  }

  /// مستوى Brain Rot من الدرجة الحالية.
  BrainRotLevel getBrainRotLevel() => brainRotLevelFromScore(currentScore);

  /// زيادة دقائق السوشيال وإعادة حساب الدرجة (تفاعل المستخدم).
  Future<void> addSocialMinutes(int minutes) async {
    final total = state.socialMinutesToday + minutes;
    await updateScore(_scoreFromSocialMinutes(total), socialMinutes: total);
  }

  int _scoreFromSocialMinutes(int minutes) =>
      (25 + (minutes * 0.55)).round().clamp(0, 100);

  Future<void> _persist(BrainRotScore score) async {
    try {
      await _ensureBox();
      await _box?.put(_hiveKeyScore, score.toJson());
    } catch (e, st) {
      if (kDebugMode) debugPrint('BrainRotNotifier._persist: $e\n$st');
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _tipForScore(int score) {
    final level = brainRotLevelFromScore(score);
    return switch (level) {
      BrainRotLevel.clean =>
        'ممتاز! وازن بين السوشيال والراتب الحقيقي',
      BrainRotLevel.warning =>
        'قلّل وقت السوشيال — راجع صافي راتبك في NetGulf',
      BrainRotLevel.danger =>
        'Brain Rot مرتفع — خذ استراحة وابدأ Pomodoro',
    };
  }
}

final brainRotNotifierProvider =
    StateNotifierProvider<BrainRotNotifier, BrainRotScore>((ref) {
  return BrainRotNotifier();
});

final brainRotScoreProvider = Provider<BrainRotScore>((ref) {
  return ref.watch(brainRotNotifierProvider);
});

/// الدرجة الحالية — convenience.
final currentBrainRotScoreProvider = Provider<int>((ref) {
  return ref.watch(brainRotScoreProvider).score;
});

final brainRotLevelProvider = Provider<BrainRotLevel>((ref) {
  return brainRotLevelFromScore(ref.watch(currentBrainRotScoreProvider));
});
