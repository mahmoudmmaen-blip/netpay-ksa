import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/constants/premium_constants.dart';
import 'package:netgulf/core/models/premium_status.dart';
import 'package:netgulf/core/providers/premium_provider.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/core/widgets/premium_badge.dart';
import 'package:netgulf/core/widgets/premium_gate_sheet.dart';

/// بطاقة حالة Premium — نشط / منتهي / غير مشترك.
class PremiumStatusCard extends ConsumerWidget {
  const PremiumStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(premiumStatusProvider);
    final state = status.subscriptionState;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusHeader(state: state),
        const SizedBox(height: 12),
        switch (state) {
          PremiumSubscriptionState.active => _ActiveCard(status: status),
          PremiumSubscriptionState.expired =>
            _ExpiredCard(expiresAt: status.expiresAt),
          PremiumSubscriptionState.notSubscribed => const _UpgradeCard(),
        },
      ],
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.state});

  final PremiumSubscriptionState state;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (state) {
      PremiumSubscriptionState.active => (
          '● اشتراك نشط',
          AppColors.emerald,
          Icons.verified_rounded,
        ),
      PremiumSubscriptionState.expired => (
          '● اشتراك منتهي',
          AppColors.warning,
          Icons.error_outline_rounded,
        ),
      PremiumSubscriptionState.notSubscribed => (
          '● غير مشترك',
          AppColors.lightMuted,
          Icons.lock_outline_rounded,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: color,
            ),
          ),
          if (state == PremiumSubscriptionState.active) ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'بدون إعلانات',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emeraldLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.status});

  final PremiumStatus status;

  @override
  Widget build(BuildContext context) {
    final expiryText = status.expiresAt != null
        ? DateFormat('dd MMMM yyyy', 'ar').format(status.expiresAt!)
        : '—';
    final days = status.daysRemaining;

    return GlassSurface(
      highlighted: true,
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _StatusIcon(
                icon: Icons.verified_rounded,
                colors: [AppColors.emerald, AppColors.emeraldDark],
                borderColor: AppColors.emerald,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusChip(
                      label: PremiumConstants.statusActive,
                      color: AppColors.emerald,
                      textColor: AppColors.emeraldLight,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      PremiumConstants.statusActiveSubtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              const PremiumBadge(compact: false),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.event_rounded,
            label: 'ينتهي في',
            value: expiryText,
          ),
          if (days != null) ...[
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.timelapse_rounded,
              label: 'متبقي',
              value: '$days يوم',
              valueColor: AppColors.emeraldLight,
            ),
          ],
          const SizedBox(height: 14),
          Text(
            PremiumConstants.premiumBenefitsTitle,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.emerald,
            ),
          ),
          const SizedBox(height: 8),
          const _BenefitsPreview(maxItems: 3),
        ],
      ),
    );
  }
}

class _ExpiredCard extends StatelessWidget {
  const _ExpiredCard({required this.expiresAt});

  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
    final expiredText = expiresAt != null
        ? DateFormat('dd MMMM yyyy', 'ar').format(expiresAt!)
        : '—';

    return GlassSurface(
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _StatusIcon(
                icon: Icons.history_toggle_off_rounded,
                colors: [
                  AppColors.warning.withValues(alpha: 0.35),
                  AppColors.gold.withValues(alpha: 0.2),
                ],
                borderColor: AppColors.warning,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusChip(
                      label: PremiumConstants.statusExpired,
                      color: AppColors.warning,
                      textColor: AppColors.warning,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      PremiumConstants.statusExpiredSubtitle,
                      style: GoogleFonts.cairo(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.event_busy_rounded,
            label: 'انتهى في',
            value: expiredText,
            valueColor: AppColors.warning,
          ),
          const SizedBox(height: 16),
          _PremiumCtaButton(
            label: PremiumConstants.renewCta,
            icon: Icons.refresh_rounded,
          ),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard();

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _StatusIcon(
                icon: Icons.workspace_premium_rounded,
                colors: [
                  AppColors.gold.withValues(alpha: 0.35),
                  AppColors.emerald.withValues(alpha: 0.25),
                ],
                borderColor: AppColors.gold,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PremiumConstants.statusNotSubscribed,
                      style: GoogleFonts.cairo(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      PremiumConstants.premiumPriceFull,
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            PremiumConstants.statusNotSubscribedSubtitle,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            PremiumConstants.benefits,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.emerald,
            ),
          ),
          const SizedBox(height: 8),
          const _BenefitsPreview(),
          const SizedBox(height: 16),
          _PremiumCtaButton(
            label: PremiumConstants.upgradeButtonText,
            icon: Icons.rocket_launch_rounded,
          ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.icon,
    required this.colors,
    required this.borderColor,
  });

  final IconData icon;
  final List<Color> colors;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors),
        border: Border.all(color: borderColor.withValues(alpha: 0.55)),
      ),
      child: Icon(icon, color: AppColors.goldBright, size: 28),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.emerald.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.cairo(fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _BenefitsPreview extends StatelessWidget {
  const _BenefitsPreview({this.maxItems});

  final int? maxItems;

  @override
  Widget build(BuildContext context) {
    final items = maxItems != null
        ? PremiumConstants.benefitItems.take(maxItems!).toList()
        : PremiumConstants.benefitItems;

    return Column(
      children: items
          .map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.emerald,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PremiumCtaButton extends StatelessWidget {
  const _PremiumCtaButton({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [AppColors.goldBright, AppColors.gold, AppColors.emerald],
            stops: [0.0, 0.4, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => showPremiumGate(
            context,
            feature: PremiumFeature.pdfExport,
          ),
          icon: Icon(icon ?? Icons.workspace_premium_rounded, color: AppColors.navy),
          label: Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
