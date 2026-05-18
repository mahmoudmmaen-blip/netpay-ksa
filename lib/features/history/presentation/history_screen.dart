import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netpay_ksa/core/theme/app_colors.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('سجل الحسابات'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_rounded,
                size: 72,
                color: AppColors.emerald.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 20),
              Text(
                'لا توجد حسابات محفوظة بعد',
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'سيُحفظ سجل الحسابات محلياً عبر Hive في التحديث القادم',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
