import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:netgulf/core/bootstrap/app_initializer.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/services/notification_service.dart';

const _hiveKeyWorkMin = 'pomodoro_work_minutes';
const _hiveKeyBreakMin = 'pomodoro_break_minutes';

/// مرحلة Pomodoro — work / break / idle.
enum PomodoroPhase { idle, work, breakPhase, paused }

/// حالة المؤقت — Pomodoro timer state.
class PomodoroState {
  const PomodoroState({
    this.phase = PomodoroPhase.idle,
    this.workMinutes = 50,
    this.breakMinutes = 10,
    this.remainingSeconds = 0,
    this.isRunning = false,
  });

  final PomodoroPhase phase;
  final int workMinutes;
  final int breakMinutes;
  final int remainingSeconds;
  final bool isRunning;

  bool get isActive =>
      phase == PomodoroPhase.work || phase == PomodoroPhase.breakPhase;

  String get phaseLabelAr => switch (phase) {
        PomodoroPhase.idle => 'جاهز للتركيز',
        PomodoroPhase.work => 'وقت الشغل',
        PomodoroPhase.breakPhase => 'استراحة',
        PomodoroPhase.paused => 'متوقف مؤقتاً',
      };

  PomodoroState copyWith({
    PomodoroPhase? phase,
    int? workMinutes,
    int? breakMinutes,
    int? remainingSeconds,
    bool? isRunning,
  }) {
    return PomodoroState(
      phase: phase ?? this.phase,
      workMinutes: workMinutes ?? this.workMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

/// Pomodoro — 50 د شغل + 10 د راحة (قابل للتعديل).
class PomodoroNotifier extends StateNotifier<PomodoroState> {
  PomodoroNotifier() : super(const PomodoroState()) {
    _loadDurations();
  }

  Timer? _timer;

  Box<dynamic>? get _box {
    if (!AppInitializer.isHiveReady) return null;
    if (!Hive.isBoxOpen(AppConstants.hiveBoxBrainRot)) return null;
    return Hive.box<dynamic>(AppConstants.hiveBoxBrainRot);
  }

  Future<void> _loadDurations() async {
    try {
      if (!Hive.isBoxOpen(AppConstants.hiveBoxBrainRot)) {
        await Hive.openBox<dynamic>(AppConstants.hiveBoxBrainRot);
      }
      final work = _box?.get(_hiveKeyWorkMin) as int? ?? 50;
      final brk = _box?.get(_hiveKeyBreakMin) as int? ?? 10;
      state = state.copyWith(
        workMinutes: work.clamp(5, 120),
        breakMinutes: brk.clamp(1, 60),
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('PomodoroNotifier._loadDurations: $e\n$st');
    }
  }

  Future<void> setWorkMinutes(int minutes) async {
    final m = minutes.clamp(5, 120);
    state = state.copyWith(workMinutes: m);
    await _box?.put(_hiveKeyWorkMin, m);
  }

  Future<void> setBreakMinutes(int minutes) async {
    final m = minutes.clamp(1, 60);
    state = state.copyWith(breakMinutes: m);
    await _box?.put(_hiveKeyBreakMin, m);
  }

  /// بدء / استئناف الجلسة.
  Future<void> start() async {
    _timer?.cancel();

    if (state.phase == PomodoroPhase.breakPhase) {
      state = state.copyWith(isRunning: true);
      _tick();
      return;
    }

    if (state.phase == PomodoroPhase.paused && state.remainingSeconds > 0) {
      final resumeWork = state.remainingSeconds > state.breakMinutes * 60;
      state = state.copyWith(
        phase: resumeWork ? PomodoroPhase.work : PomodoroPhase.breakPhase,
        isRunning: true,
      );
      _tick();
      return;
    }

    state = state.copyWith(
      phase: PomodoroPhase.work,
      remainingSeconds: state.workMinutes * 60,
      isRunning: true,
    );
    _tick();
  }

  void pause() {
    _timer?.cancel();
    if (state.isActive) {
      state = state.copyWith(
        phase: PomodoroPhase.paused,
        isRunning: false,
      );
    }
  }

  void reset() {
    _timer?.cancel();
    state = state.copyWith(
      phase: PomodoroPhase.idle,
      remainingSeconds: 0,
      isRunning: false,
    );
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (state.remainingSeconds <= 1) {
        await _onSegmentComplete();
        return;
      }
      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
    });
  }

  Future<void> _onSegmentComplete() async {
    _timer?.cancel();
    if (state.phase == PomodoroPhase.work) {
      await NotificationService.instance.showPomodoroComplete(
        title: 'انتهى وقت الشغل — Pomodoro',
        body: 'خذ استراحة ${state.breakMinutes} دقائق بعيداً عن السوشيال',
      );
      state = state.copyWith(
        phase: PomodoroPhase.breakPhase,
        remainingSeconds: state.breakMinutes * 60,
        isRunning: true,
      );
      _tick();
      return;
    }

    if (state.phase == PomodoroPhase.breakPhase) {
      await NotificationService.instance.showPomodoroComplete(
        title: 'انتهت الاستراحة',
        body: 'عد للتركيز — جلسة شغل جديدة؟',
      );
      state = state.copyWith(
        phase: PomodoroPhase.idle,
        remainingSeconds: 0,
        isRunning: false,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pomodoroNotifierProvider =
    StateNotifierProvider<PomodoroNotifier, PomodoroState>((ref) {
  return PomodoroNotifier();
});
