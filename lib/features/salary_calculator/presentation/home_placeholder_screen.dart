import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netpay_ksa/core/constants/app_constants.dart';
import 'package:netpay_ksa/core/theme/app_colors.dart';

/// Temporary home until salary calculator UI is built.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appNameAr),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calculate_outlined,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'حاسبة الراتب الصافي',
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'قريباً — الخطوة التالية',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
