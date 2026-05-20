import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/features/brain_rot/models/brain_rot_score.dart';
import 'package:netgulf/features/brain_rot/providers/brain_rot_provider.dart';

/// بطاقة Brain Rot — دائرة تقدم 0–100 (أخضر / أصفر / أحمر).
class BrainRotScoreCard extends ConsumerWidget {
  const BrainRotScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(brainRotScoreProvider);
    final color = _colorForScore(data);
    final progress = data.score / 100;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: color.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: color.withValues(alpha: 0.15),
                    color: color,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${data.score}',
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    Text(
                      '/ 100',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                  data.tipAr,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (data.socialMinutesToday > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'سوشيال اليوم: ${data.socialMinutesToday} د',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForScore(BrainRotScore data) {
    if (data.isHealthy) return AppColors.emerald;
    if (data.isWarning) return AppColors.warning;
    return AppColors.error;
  }
}
