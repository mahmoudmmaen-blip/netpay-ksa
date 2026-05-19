import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/features/gosi/domain/enums/gosi_regime.dart';
import 'package:netgulf/features/gosi/domain/enums/nationality_type.dart';
import 'package:netgulf/features/notifications/providers/notifications_provider.dart';
import 'package:netgulf/features/salary_calculator/providers/salary_notifier.dart';

/// شاشة التنبيهات — زيادات GOSI القادمة وتفعيل الإشعارات.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(notificationsEnabledProvider)) {
        ref.read(notificationsEnabledProvider.notifier).syncFromSalary(ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(notificationsEnabledProvider);
    final items = ref.watch(gosiNotificationItemsProvider);
    final salary = ref.watch(salaryNotifierProvider);
    final currency = NumberFormat.currency(
      locale: 'ar_SA',
      symbol: 'ر.س',
      decimalDigits: 2,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final showPhasedOnly = salary.regime == GosiRegime.newLawPhased &&
        salary.nationality == NationalityType.saudi;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'التنبيهات والتذكيرات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            elevation: 0,
            color: AppColors.emerald.withValues(alpha: isDark ? 0.15 : 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.emerald.withValues(alpha: 0.35)),
            ),
            child: SwitchListTile(
              title: Text(
                enabled ? 'إيقاف التنبيهات' : 'تفعيل التنبيهات',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: AppColors.emerald,
                ),
              ),
              subtitle: Text(
                'تذكير سنوي + تنبيه قبل زيادات GOSI في يوليو',
                style: GoogleFonts.cairo(fontSize: 13),
              ),
              value: enabled,
              activeThumbColor: AppColors.emerald,
              onChanged: (v) async {
                await ref
                    .read(notificationsEnabledProvider.notifier)
                    .setEnabled(v, ref);
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'زيادات GOSI القادمة',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (!showPhasedOnly)
            _EmptyHint(
              message:
                  'الزيادات المرحلية تنطبق على السعوديين في النظام الجديد (2024+). '
                  'غيّر الجنسية أو النظام في الحاسبة الرئيسية.',
            )
          else if (items.isEmpty)
            const _EmptyHint(
              message: 'لا توجد زيادات GOSI مجدولة بعد تاريخ حسابك الحالي.',
            )
          else
            ...items.map((item) {
              final w = item.warning;
              final monthAr = DateFormat.MMMM('ar').format(w.effectiveDate);
              final year = w.phaseYear;
              final impact = item.monthlyNetImpactSar > 0
                  ? item.monthlyNetImpactSar
                  : item.monthlyGosiIncreaseSar;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            color: AppColors.emerald,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'زيادة GOSI — $monthAr $year',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'بعد ${w.daysUntilEffective} يوم',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: AppColors.emerald,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'زيادة GOSI القادمة: يوليو $year — '
                        'ستتأثر بـ ${currency.format(impact)} شهرياً',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          height: 1.5,
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'الموظف: ${w.currentEmployeePercent.toStringAsFixed(2)}%'
                        ' → ${w.nextEmployeePercent.toStringAsFixed(2)}% '
                        '(+${w.employeeIncrease.toStringAsFixed(2)} نقطة)',
                        style: GoogleFonts.cairo(fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        w.messageAr,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),
          Text(
            'التذكير السنوي',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '«راجع راتبك — GOSI تغيرت؟» — يُجدول تلقائياً عند تفعيل التنبيهات.',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: GoogleFonts.cairo(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }
}
