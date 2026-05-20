import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/constants/premium_constants.dart';

class PremiumBadge extends StatelessWidget {
  final bool isPremium;
  final double size;

  const PremiumBadge({
    super.key,
    this.isPremium = true,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    if (!isPremium) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            PremiumConstants.premiumGradientStart,
            PremiumConstants.premiumGradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: PremiumConstants.premiumColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: size * 0.7,
          ),
          const SizedBox(width: 6),
          Text(
            PremiumConstants.premiumBadgeText,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: size * 0.55,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}