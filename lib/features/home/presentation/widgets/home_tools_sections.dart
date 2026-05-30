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
    required this.onLegalQa,
    required this.onArticle77,
    required this.onContractExplainer,
    this.legalQaPremium = false,
  });

  final GulfCountry country;
  final List<HomeQuickActionItem> workItems;
  final List<HomeQuickActionItem> planningItems;
  final VoidCallback onContractAnalysis;
  final VoidCallback onLegalQa;
  final VoidCallback onArticle77;
  final VoidCallback onContractExplainer;
  final bool legalQaPremium;

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
        _SectionTitle('الحقوق القانونية'),
        const SizedBox(height: 8),
        _LegalRightsCards(
          onLegalQa: onLegalQa,
          onArticle77: onArticle77,
          onContractExplainer: onContractExplainer,
          showPremiumBadge: legalQaPremium,
        ),
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
              Icon(
                Icons.chevron_left_rounded,
                color: Colors.white.withValues(alpha: 0.7),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalRightsCards extends StatelessWidget {
  const _LegalRightsCards({
    required this.onLegalQa,
    required this.onArticle77,
    required this.onContractExplainer,
    required this.showPremiumBadge,
  });

  final VoidCallback onLegalQa;
  final VoidCallback onArticle77;
  final VoidCallback onContractExplainer;
  final bool showPremiumBadge;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LegalToolCard(
          icon: Icons.chat_rounded,
          title: 'استفسار قانوني',
          subtitle: 'اسأل عن حقوقك في قانون العمل',
          onTap: onLegalQa,
          premiumBadge: showPremiumBadge,
        ),
        const SizedBox(height: 10),
        _LegalToolCard(
          icon: Icons.gavel_rounded,
          title: 'فسخ تعسفي — المادة 77',
          subtitle: 'احسب التعويض المستحق',
          onTap: onArticle77,
        ),
        const SizedBox(height: 10),
        _LegalToolCard(
          icon: Icons.menu_book_rounded,
          title: 'مصطلحات العقد',
          subtitle: 'فهم بنود عقدك بلغة بسيطة',
          onTap: onContractExplainer,
        ),
      ],
    );
  }
}

class _LegalToolCard extends StatelessWidget {
  const _LegalToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.premiumBadge = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool premiumBadge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context)
                .colorScheme
                .surface
                .withValues(alpha: 0.55),
            border: Border.all(color: AppColors.glassBorder),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.emerald, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (premiumBadge)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.goldBright),
                  ),
                  child: Text(
                    'Premium',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.goldBright,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_left_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
