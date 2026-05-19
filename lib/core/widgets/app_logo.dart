import 'package:flutter/material.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/theme/app_colors.dart';

/// Brand logo — uses [AppConstants.logoAsset] with vector fallback.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 96,
    this.showShadow = true,
  });

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brandGradient,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.35),
                  blurRadius: size * 0.2,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          AppConstants.logoAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _FallbackLogo(size: size * 0.45),
        ),
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            size: size,
            color: Colors.white.withValues(alpha: 0.95),
          ),
          const SizedBox(height: 2),
          Text(
            'NP',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w800,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }
}
