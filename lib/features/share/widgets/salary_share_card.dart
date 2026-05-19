import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/app_logo.dart';

/// بيانات بطاقة مشاركة الراتب.
class SalaryShareData {
  const SalaryShareData({
    required this.netSalary,
    required this.grossSalary,
    required this.gosiDeduction,
    required this.date,
  });

  final double netSalary;
  final double grossSalary;
  final double gosiDeduction;
  final DateTime date;
}

/// بطاقة مشاركة — تُلتقط كصورة (RTL + زمردي).
class SalaryShareCard extends StatelessWidget {
  const SalaryShareCard({
    super.key,
    required this.data,
    this.width = 360,
  });

  final SalaryShareData data;
  final double width;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'ar_SA',
      symbol: 'ر.س',
      decimalDigits: 2,
    );
    final dateStr = _formatArabicDate(data.date);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.emerald,
                AppColors.emeraldDark,
                AppColors.navyMid,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const AppLogo(size: 52, showShadow: false),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appNameAr,
                            style: GoogleFonts.cairo(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            AppConstants.appNameEn,
                            style: GoogleFonts.cairo(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'صافي الراتب',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currency.format(data.netSalary),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: AppColors.goldBright,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),
                _ShareRow(
                  label: 'الراتب الإجمالي',
                  value: currency.format(data.grossSalary),
                ),
                const SizedBox(height: 10),
                _ShareRow(
                  label: 'خصم التأمينات (GOSI)',
                  value: currency.format(data.gosiDeduction),
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
                const SizedBox(height: 14),
                Text(
                  dateStr,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppConstants.appTaglineAr,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    color: AppColors.gold.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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

String _formatArabicDate(DateTime date) {
  const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  const weekdays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  final weekday = weekdays[date.weekday - 1];
  final month = months[date.month - 1];
  return '$weekday، ${date.day} $month ${date.year}';
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
