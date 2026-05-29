import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/features/home/presentation/widgets/home_quick_actions_row.dart';

/// أقسام أدوات الشاشة الرئيسية.
class HomeToolsSections extends StatelessWidget {
  const HomeToolsSections({
    super.key,
    required this.country,
    required this.workItems,
    required this.planningItems,
    required this.onContractAnalysis,
  });

  final GulfCountry country;
  final List<HomeQuickActionItem> workItems;
  final List<HomeQuickActionItem> planningItems;
  final VoidCallback onContractAnalysis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle('أدوات العمل'),
        const SizedBox(height: 8),
        HomeQuickActionsRow(country: country, items: workItems),
        const SizedBox(height: 20),
        _SectionTitle('تحليل العقد'),
        const SizedBox(height: 8),
        _ContractAnalysisPromoCard(onTap: onContractAnalysis),
        const SizedBox(height: 20),
        _SectionTitle('التخطيط المالي'),
        const SizedBox(height: 8),
        HomeQuickActionsRow(country: country, items: planningItems),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.emeraldLight,
        ),
      ),
    );
  }
}

class _ContractAnalysisPromoCard extends StatelessWidget {
  const _ContractAnalysisPromoCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFF064E3B),
                AppColors.emeraldDark,
                Color(0xFF1E293B),
              ],
            ),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(
                Icons.document_scanner_rounded,
                color: AppColors.goldBright,
                size: 36,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تحليل عقد PDF',
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'استخراج البنود والمخاطر بالذكاء الاصطناعي',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.goldBright),
                ),
                child: Text(
                  'مدعوم بـ AI',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldBright,
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
