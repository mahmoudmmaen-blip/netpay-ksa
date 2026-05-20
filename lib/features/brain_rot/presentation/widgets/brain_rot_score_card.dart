import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/features/brain_rot/models/brain_rot_level.dart';
import 'package:netgulf/features/brain_rot/models/brain_rot_score.dart';
import 'package:netgulf/features/brain_rot/providers/brain_rot_provider.dart';

/// بطاقة Brain Rot — دائرة تفاعلية + حالة عربية.
/// Interactive Brain Rot card — ring color green → yellow → red.
class BrainRotScoreCard extends ConsumerStatefulWidget {
  const BrainRotScoreCard({super.key, this.compact = false});

  /// تخطيط عمودي ضيق بجانب بطاقة الراتب.
  final bool compact;

  @override
  ConsumerState<BrainRotScoreCard> createState() => _BrainRotScoreCardState();
}

class _BrainRotScoreCardState extends ConsumerState<BrainRotScoreCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.95,
      upperBound: 1.0,
    )..value = 1.0;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(brainRotScoreProvider);
    final level = ref.watch(brainRotLevelProvider);
    final color = _colorForLevel(level);
    final progress = data.score / 100;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<int>(currentBrainRotScoreProvider, (prev, next) {
      if (prev != null && prev != next) {
        _pulseController.forward(from: 0.95);
      }
    });

    final ringSize = widget.compact ? 72.0 : 88.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTap(context),
        onLongPress: () => ref
            .read(brainRotNotifierProvider.notifier)
            .updateScore((data.score - 15).clamp(0, 100)),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) => Transform.scale(
            scale: _pulseController.value,
            child: child,
          ),
          child: Container(
            padding: EdgeInsets.all(widget.compact ? 12 : 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : Theme.of(context).colorScheme.surface,
              border: Border.all(color: color.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.14),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: widget.compact
                ? _CompactLayout(
                    data: data,
                    level: level,
                    color: color,
                    progress: progress,
                    ringSize: ringSize,
                  )
                : _FullLayout(
                    data: data,
                    level: level,
                    color: color,
                    progress: progress,
                    ringSize: ringSize,
                  ),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    ref.read(brainRotNotifierProvider.notifier).addSocialMinutes(15);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم تسجيل +15 د سوشيال — اضغط مطولاً لخفض الدرجة',
          style: GoogleFonts.cairo(),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _colorForLevel(BrainRotLevel level) => switch (level) {
        BrainRotLevel.clean => AppColors.emerald,
        BrainRotLevel.warning => AppColors.warning,
        BrainRotLevel.danger => AppColors.error,
      };
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.score,
    required this.progress,
    required this.color,
    required this.ringSize,
  });

  final int score;
  final double progress;
  final Color color;
  final double ringSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => SizedBox(
              width: ringSize,
              height: ringSize,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: _ScoreRing.strokeFor(ringSize),
                backgroundColor: color.withValues(alpha: 0.15),
                color: color,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: GoogleFonts.cairo(
                  fontSize: ringSize * 0.28,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                '/ 100',
                style: GoogleFonts.cairo(
                  fontSize: ringSize * 0.14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static double strokeFor(double size) => size < 80 ? 6 : 8;
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.level, required this.color});

  final BrainRotLevel level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      level.statusAr,
      textAlign: TextAlign.center,
      style: GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
    required this.data,
    required this.level,
    required this.color,
    required this.progress,
    required this.ringSize,
  });

  final BrainRotScore data;
  final BrainRotLevel level;
  final Color color;
  final double progress;
  final double ringSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ScoreRing(
          score: data.score,
          progress: progress,
          color: color,
          ringSize: ringSize,
        ),
        const SizedBox(height: 8),
        _StatusLabel(level: level, color: color),
        const SizedBox(height: 4),
        Text(
          'Brain Rot',
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FullLayout extends StatelessWidget {
  const _FullLayout({
    required this.data,
    required this.level,
    required this.color,
    required this.progress,
    required this.ringSize,
  });

  final BrainRotScore data;
  final BrainRotLevel level;
  final Color color;
  final double progress;
  final double ringSize;

  @override
  Widget build(BuildContext context) {
    final score = data.score;
    final tip = data.tipAr;
    final social = data.socialMinutesToday;

    return Row(
      children: [
        Column(
          children: [
            _ScoreRing(
              score: score,
              progress: progress,
              color: color,
              ringSize: ringSize,
            ),
            const SizedBox(height: 8),
            _StatusLabel(level: level, color: color),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology_outlined, color: color, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Brain Rot Score',
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tip,
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (social > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'سوشيال اليوم: $social د',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'اضغط لتسجيل سوشيال',
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: AppColors.emerald.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
