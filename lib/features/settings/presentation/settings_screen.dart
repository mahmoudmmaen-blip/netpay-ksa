import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/constants/app_constants.dart';
import 'package:netgulf/core/providers/theme_provider.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/premium_badge.dart';
import 'package:netgulf/core/widgets/premium_status_card.dart';
import 'package:netgulf/features/salary_calculator/providers/history_notifier.dart';

/// شاشة الإعدادات — ثيم، لغة، عن التطبيق، مسح السجل.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final historyAsync = ref.watch(historyNotifierProvider);
    final recordCount = historyAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الإعدادات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        actions: const [
          Padding(
            padding: EdgeInsetsDirectional.only(end: 12),
            child: Center(child: PremiumBadge()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const PremiumStatusCard(),
          const SizedBox(height: 20),
          _SectionHeader(title: 'المظهر'),
          _SettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                leading: Icon(
                  _themeIcon(themeMode),
                  color: AppColors.emerald,
                ),
                title: Text(
                  'المظهر',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  themeModeLabel(themeMode),
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded, size: 18),
                      label: Text('تلقائي'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded, size: 18),
                      label: Text('فاتح'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded, size: 18),
                      label: Text('داكن'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(selection.first);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'اللغة'),
          _SettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.language_rounded, color: AppColors.emerald),
                title: Text(
                  'لغة التطبيق',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'الإنجليزية قريباً',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.emerald.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    'العربية',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.emerald,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'عن التطبيق'),
          _SettingsCard(
            children: [
              _AboutRow(
                icon: Icons.info_outline_rounded,
                label: 'الإصدار',
                value: '${AppConstants.appVersion} (${AppConstants.appBuildNumber})',
              ),
              const Divider(height: 1, indent: 56),
              _AboutRow(
                icon: Icons.apps_rounded,
                label: 'التطبيق',
                value: AppConstants.appNameAr,
              ),
              const Divider(height: 1, indent: 56),
              _AboutRow(
                icon: Icons.code_rounded,
                label: 'المطوّر',
                value: 'NetGulf Team',
              ),
              const Divider(height: 1, indent: 56),
              _AboutRow(
                icon: Icons.email_outlined,
                label: 'التواصل',
                value: 'support@netgulf.app',
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.emerald),
                title: Text(
                  'سياسة الخصوصية',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Privacy Policy',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: const Icon(Icons.chevron_left_rounded),
                onTap: () => context.push(AppRoutes.privacyPolicy),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Text(
                  AppConstants.appTaglineAr,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'البيانات'),
          _SettingsCard(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
                title: Text(
                  'مسح سجل الرواتب',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                subtitle: Text(
                  recordCount == 0
                      ? 'لا توجد سجلات محفوظة'
                      : '$recordCount سجل محفوظ',
                  style: GoogleFonts.cairo(fontSize: 12),
                ),
                enabled: recordCount > 0,
                onTap: recordCount > 0
                    ? () => _confirmClearHistory(context, ref)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'مسح السجل',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'هل أنت متأكد من حذف جميع سجلات الرواتب المحفوظة؟ لا يمكن التراجع.',
          style: GoogleFonts.cairo(height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('مسح الكل', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(historyNotifierProvider.notifier).clearAll();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم مسح السجل بنجاح',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: AppColors.emerald,
      ),
    );
  }
}

IconData _themeIcon(ThemeMode mode) => switch (mode) {
      ThemeMode.system => Icons.brightness_auto_rounded,
      ThemeMode.light => Icons.light_mode_rounded,
      ThemeMode.dark => Icons.dark_mode_rounded,
    };

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.emerald,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: AppColors.emerald.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.emerald, size: 22),
      title: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 13,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.cairo(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
