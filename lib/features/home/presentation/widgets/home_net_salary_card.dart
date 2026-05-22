import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/theme/app_typography.dart';
import 'package:netgulf/core/widgets/animated_currency_text.dart';
import 'package:netgulf/core/widgets/app_logo.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';

/// بطاقة الراتب الصافي — Hero مع Gradient + Shadow + Animation.
class HomeNetSalaryCard extends StatefulWidget {
  const HomeNetSalaryCard({
    super.key,
    required this.country,
    required this.net,
    required this.gross,
    required this.deduction,
    required this.isDark,
    required this.formatValue,
  });

  final GulfCountry country;
  final double net;
  final double gross;
  final double deduction;
  final bool isDark;
  final String Function(double) formatValue;

  @override
  State<HomeNetSalaryCard> createState() => _HomeNetSalaryCardState();
}

class _HomeNetSalaryCardState extends State<HomeNetSalaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(HomeNetSalaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.country != widget.country ||
        oldWidget.net != widget.net) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _deductionColumnLabel => 'خصم ${widget.country.schemeShort}';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 228),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            ...AppColors.premiumCardGlow(isDark: widget.isDark),
            BoxShadow(
              color: AppColors.emerald.withValues(alpha: 0.2),
              blurRadius: 28,
              spreadRadius: -6,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: AppColors.premiumCardBorder,
          ),
          padding: const EdgeInsets.all(2.5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(29.5),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.heroSalaryGradient(
                        isDark: widget.isDark,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: 0.07,
                      child: AppLogo(size: 160, showShadow: false),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: _FlagBadge(country: widget.country),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 56, 28, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'الراتب الصافي',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedCurrencyText(
                        key: ValueKey('${widget.country.nameEn}-${widget.net}'),
                        value: widget.net,
                        formatter: widget.formatValue,
                        duration: const Duration(milliseconds: 750),
                        style: AppTypography.displayNumber(size: 68),
                      ),
                      const SizedBox(height: 22),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _StatColumn(
                                      label: _deductionColumnLabel,
                                      value: widget.deduction,
                                      formatValue: widget.formatValue,
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    color:
                                        Colors.white.withValues(alpha: 0.22),
                                  ),
                                  Expanded(
                                    child: _StatColumn(
                                      label: 'الإجمالي',
                                      value: widget.gross,
                                      formatValue: widget.formatValue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlagBadge extends StatelessWidget {
  const _FlagBadge({required this.country});
  final GulfCountry country;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: 20,
      blur: 8,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(country.flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 6),
          Text(
            country.nameAr,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.formatValue,
  });

  final String label;
  final double value;
  final String Function(double) formatValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.cairo(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedCurrencyText(
          value: value,
          formatter: formatValue,
          goldGradient: false,
          duration: const Duration(milliseconds: 750),
          style: AppTypography.statNumber(
            size: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
