import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/providers/app_state_provider.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';

/// شاشة التعريف المطورة — تجربة مستخدم سلسة وواضحة
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPageData(
      icon: Icons.calculate_rounded,
      title: AppConstants.onboardingWelcomeTitleAr,
      subtitle: 'حاسبة الراتب الصافي لدول الخليج الست — دقيقة، سريعة، وتعمل بالكامل بدون إنترنت',
    ),
    _OnboardingPageData(
      icon: Icons.shield_rounded,
      title: 'حساب التأمينات ونهاية الخدمة',
      subtitle: 'GOSI • GPSSA • DEWS ومكافأة نهاية الخدمة لكل دولة خليجية وفق أنظمتها المحلية',
    ),
    _OnboardingPageData(
      icon: Icons.rocket_launch_rounded,
      title: 'إدارة وتصدير التقارير',
      subtitle: 'احفظ سجلاتك، صدّر تقاريرك كـ PDF، وقارن بين العروض الوظيفية بكل وضوح وسهولة',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (mounted) {
      setState(() => _currentPage = index);
    }
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      unawaited(_finishOnboarding());
    }
  }

  Future<void> _finishOnboarding() async {
    await ref.read(appStateProvider.notifier).setOnboardingCompleted(true);
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient(brightness),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const ClampingScrollPhysics(),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) => _OnboardingPage(
                    data: _pages[index],
                  ),
                ),
              ),
              _DotIndicator(
                count: _pages.length,
                currentIndex: _currentPage,
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56, // تحسين مساحة الضغط للمخدم
                  child: FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        isLastPage ? 'ابدأ الآن' : 'التالي',
                        key: ValueKey<bool>(isLastPage),
                        style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
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

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.35),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Icon(data.icon, size: 64, color: AppColors.emerald),
          ),
          const SizedBox(height: 48),
          Text(
            data.title,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.emerald,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            style: GoogleFonts.cairo(
              fontSize: 15,
              height: 1.6,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic, // المنحنى الحركي الصحيح والمستقر
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.emerald
                : AppColors.emerald.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}