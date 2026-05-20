import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:netgulf/core/bootstrap/app_initializer.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/features/brain_rot/models/brain_rot_score.dart';

const _hiveKeyScore = 'brain_rot_score';

/// إدارة Brain Rot Score — Hive.
class BrainRotNotifier extends StateNotifier<BrainRotScore> {
  BrainRotNotifier() : super(BrainRotScore.initial) {
    _load();
  }

  Box<dynamic>? get _box {
    if (!AppInitializer.isHiveReady) return null;
    if (!Hive.isBoxOpen(AppConstants.hiveBoxBrainRot)) return null;
    return Hive.box<dynamic>(AppConstants.hiveBoxBrainRot);
  }

  Future<void> _load() async {
    try {
      if (!AppInitializer.isHiveReady) return;
      if (!Hive.isBoxOpen(AppConstants.hiveBoxBrainRot)) {
        await Hive.openBox<dynamic>(AppConstants.hiveBoxBrainRot);
      }
      final raw = _box?.get(_hiveKeyScore);
      if (raw is Map) {
        state = BrainRotScore.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('BrainRotNotifier._load: $e\n$st');
    }
  }

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

  Future<void> _persist(BrainRotScore score) async {
    try {
      if (!Hive.isBoxOpen(AppConstants.hiveBoxBrainRot)) {
        await Hive.openBox<dynamic>(AppConstants.hiveBoxBrainRot);
      }
      await _box?.put(_hiveKeyScore, score.toJson());
    } catch (e, st) {
      if (kDebugMode) debugPrint('BrainRotNotifier._persist: $e\n$st');
    }
  }

  String _tipForScore(int score) {
    if (score <= 40) {
      return 'ممتاز! وازن بين السوشيال والراتب الحقيقي';
    }
    if (score <= 70) {
      return 'قلّل وقت السوشيال — راجع صافي راتبك في NetGulf';
    }
    return 'Brain Rot مرتفع — خذ استراحة وافتح الحاسبة';
  }
}

final brainRotNotifierProvider =
    StateNotifierProvider<BrainRotNotifier, BrainRotScore>((ref) {
  return BrainRotNotifier();
});

final brainRotScoreProvider = Provider<BrainRotScore>((ref) {
  return ref.watch(brainRotNotifierProvider);
});
