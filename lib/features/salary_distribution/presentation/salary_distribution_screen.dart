import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:netgulf/core/router/app_routes.dart';
import 'package:netgulf/core/theme/app_colors.dart';
import 'package:netgulf/core/widgets/glass_surface.dart';
import 'package:netgulf/features/home/presentation/widgets/home_salary_field.dart';
import 'package:netgulf/features/salary_distribution/domain/salary_distribution_calculator.dart';
import 'package:netgulf/features/salary_distribution/providers/salary_distribution_provider.dart';

const _customEmojiOptions = ['🏠', '🚗', '🎯', '💊', '✈️', '📚', '🎮'];

const _categoryColors = [
  AppColors.emerald,
  Color(0xFF2563EB),
  AppColors.gold,
  Color(0xFFEA580C),
  Color(0xFF9333EA),
  Color(0xFF0D9488),
];

class _CustomCategory {
  _CustomCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.percent,
    required this.isBuiltin,
  });

  final String id;
  String name;
  String emoji;
  double percent;
  final bool isBuiltin;

  _CustomCategory copyWith({
    String? name,
    String? emoji,
    double? percent,
  }) {
    return _CustomCategory(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      percent: percent ?? this.percent,
      isBuiltin: isBuiltin,
    );
  }
}

List<_CustomCategory> _defaultCustomCategories(SalaryDistributionState state) {
  return [
    _CustomCategory(
      id: 'needs',
      name: 'الأساسيات (احتياجات)',
      emoji: '🏠',
      percent: state.needsPercent,
      isBuiltin: true,
    ),
    _CustomCategory(
      id: 'wants',
      name: 'الرغبات (ترفيه)',
      emoji: '🎯',
      percent: state.wantsPercent,
      isBuiltin: true,
    ),
    _CustomCategory(
      id: 'savings',
      name: 'الادخار والديون',
      emoji: '💰',
      percent: state.savingsPercent,
      isBuiltin: true,
    ),
  ];
}

void _adjustPercentProportionally(
  List<_CustomCategory> categories,
  int changedIndex,
  double newPercent,
) {
  newPercent = newPercent.clamp(0, 100);
  categories[changedIndex] =
      categories[changedIndex].copyWith(percent: newPercent);

  final otherIndices = <int>[
    for (var i = 0; i < categories.length; i++)
      if (i != changedIndex) i,
  ];
  if (otherIndices.isEmpty) return;

  final remaining = (100 - newPercent).clamp(0.0, 100.0);
  final otherSum = otherIndices.fold<double>(
    0,
    (sum, i) => sum + categories[i].percent,
  );

  if (otherSum <= 0.001) {
    final each = remaining / otherIndices.length;
    for (final i in otherIndices) {
      categories[i] = categories[i].copyWith(percent: each);
    }
  } else {
    for (final i in otherIndices) {
      categories[i] = categories[i].copyWith(
        percent: categories[i].percent / otherSum * remaining,
      );
    }
  }

  var total = categories.fold<double>(0, (s, c) => s + c.percent);
  final diff = 100 - total;
  if (diff.abs() > 0.01 && otherIndices.isNotEmpty) {
    final fixIndex = otherIndices.last;
    categories[fixIndex] = categories[fixIndex].copyWith(
      percent: (categories[fixIndex].percent + diff).clamp(0, 100),
    );
    total = categories.fold<double>(0, (s, c) => s + c.percent);
    if ((total - 100).abs() > 0.01) {
      categories[changedIndex] = categories[changedIndex].copyWith(
        percent: categories[changedIndex].percent + (100 - total),
      );
    }
  }
}

class SalaryDistributionScreen extends ConsumerStatefulWidget {
  const SalaryDistributionScreen({super.key});

  @override
  ConsumerState<SalaryDistributionScreen> createState() =>
      _SalaryDistributionScreenState();
}

class _SalaryDistributionScreenState
    extends ConsumerState<SalaryDistributionScreen> {
  List<_CustomCategory>? _customCategories;

  void _ensureCustomCategories(SalaryDistributionState state) {
    if (state.mode != DistributionMode.custom) return;
    _customCategories ??= _defaultCustomCategories(state);
  }

  void _syncBuiltinToProvider(List<_CustomCategory> categories) {
    final notifier = ref.read(salaryDistributionProvider.notifier);
    for (final c in categories) {
      switch (c.id) {
        case 'needs':
          notifier.setNeeds(c.percent);
        case 'wants':
          notifier.setWants(c.percent);
        case 'savings':
          notifier.setSavings(c.percent);
      }
    }
  }

  void _onCustomPercentChanged(int index, double value) {
    final cats = List<_CustomCategory>.from(_customCategories!);
    _adjustPercentProportionally(cats, index, value);
    setState(() => _customCategories = cats);
    _syncBuiltinToProvider(cats);
  }

  void _deleteCategory(int index) {
    final cats = List<_CustomCategory>.from(_customCategories!);
    if (cats[index].isBuiltin || cats.length <= 1) return;

    final removed = cats.removeAt(index);
    final others = List.generate(cats.length, (i) => i);
    if (others.isEmpty) {
      setState(() => _customCategories = cats);
      return;
    }

    final otherSum = cats.fold<double>(0, (s, c) => s + c.percent);
    if (otherSum <= 0.001) {
      final each = removed.percent / others.length;
      for (var i = 0; i < cats.length; i++) {
        cats[i] = cats[i].copyWith(percent: cats[i].percent + each);
      }
    } else {
      for (var i = 0; i < cats.length; i++) {
        cats[i] = cats[i].copyWith(
          percent: cats[i].percent + removed.percent * (cats[i].percent / otherSum),
        );
      }
    }

    final total = cats.fold<double>(0, (s, c) => s + c.percent);
    if (total > 0.001 && (total - 100).abs() > 0.5) {
      for (var i = 0; i < cats.length; i++) {
        cats[i] = cats[i].copyWith(percent: cats[i].percent / total * 100);
      }
    }
    setState(() => _customCategories = cats);
    _syncBuiltinToProvider(cats);
  }

  Future<void> _showAddCategoryDialog() async {
    if ((_customCategories?.length ?? 0) >= 6) return;

    final nameController = TextEditingController();
    var selectedEmoji = _customEmojiOptions.first;

    try {
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('إضافة بند', style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم البند',
                    labelStyle: GoogleFonts.cairo(),
                    border: const OutlineInputBorder(),
                  ),
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 16),
                Text('الأيقونة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _customEmojiOptions.map((emoji) {
                    final selected = emoji == selectedEmoji;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedEmoji = emoji),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.emerald
                                : Theme.of(context).dividerColor,
                            width: selected ? 2 : 1,
                          ),
                          color: selected
                              ? AppColors.emerald.withValues(alpha: 0.12)
                              : null,
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('إلغاء', style: GoogleFonts.cairo()),
              ),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: Text('إضافة', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );

    if (added != true || !mounted) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    final cats = List<_CustomCategory>.from(_customCategories!);
    cats.add(
      _CustomCategory(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        emoji: selectedEmoji,
        percent: 0,
        isBuiltin: false,
      ),
    );
    setState(() => _customCategories = cats);
    } finally {
      nameController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salaryDistributionProvider);
    final result = ref.watch(salaryDistributionResultProvider);
    final notifier = ref.read(salaryDistributionProvider.notifier);
    final fmt = NumberFormat.currency(
      locale: 'ar_SA',
      symbol: 'ر.س',
      decimalDigits: 0,
    );

    ref.listen<SalaryDistributionState>(salaryDistributionProvider, (prev, next) {
      if (next.mode == DistributionMode.custom &&
          prev?.mode != DistributionMode.custom) {
        setState(() => _customCategories = _defaultCustomCategories(next));
      } else if (next.mode != DistributionMode.custom) {
        setState(() => _customCategories = null);
      }
    });

    _ensureCustomCategories(state);
    final isCustom = state.mode == DistributionMode.custom;
    final customCats = _customCategories;
    final customTotal = isCustom && customCats != null
        ? customCats.fold<double>(0, (s, c) => s + c.percent)
        : 0.0;

    final displayCategories = isCustom && customCats != null
        ? customCats
        : [
            _CustomCategory(
              id: 'needs',
              name: 'الأساسيات (احتياجات)',
              emoji: '🏠',
              percent: result.needsPercent,
              isBuiltin: true,
            ),
            _CustomCategory(
              id: 'wants',
              name: 'الرغبات (ترفيه)',
              emoji: '🎯',
              percent: result.wantsPercent,
              isBuiltin: true,
            ),
            _CustomCategory(
              id: 'savings',
              name: 'الادخار والديون',
              emoji: '💰',
              percent: result.savingsPercent,
              isBuiltin: true,
            ),
          ];

    double amountFor(_CustomCategory c) {
      if (!isCustom || customCats == null) {
        switch (c.id) {
          case 'needs':
            return result.needsAmount;
          case 'wants':
            return result.wantsAmount;
          case 'savings':
            return result.savingsAmount;
          default:
            return state.netSalary * c.percent / 100;
        }
      }
      final total = customCats.fold<double>(0, (s, x) => s + x.percent);
      final pct = total > 0 ? c.percent / total * 100 : c.percent;
      return state.netSalary * pct / 100;
    }

    final savingsCategory = displayCategories.firstWhere(
      (c) => c.id == 'savings',
      orElse: () => displayCategories.last,
    );
    final projectedSavings =
        amountFor(savingsCategory) * 12 * state.savingsYears;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AppRoutes.home),
        ),
        title: Text('توزيع الراتب',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.homeGradient(Theme.of(context).brightness),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              HomeSalaryField(
                label: 'الراتب الصافي',
                value: state.netSalary,
                currencySymbol: 'ر.س',
                onChanged: notifier.setNet,
              ),
              SegmentedButton<DistributionMode>(
                segments: const [
                  ButtonSegment(
                    value: DistributionMode.classic503020,
                    label: Text('50/30/20'),
                  ),
                  ButtonSegment(
                    value: DistributionMode.mode602020,
                    label: Text('60/20/20'),
                  ),
                  ButtonSegment(
                    value: DistributionMode.custom,
                    label: Text('مخصص'),
                  ),
                ],
                selected: {state.mode},
                onSelectionChanged: (s) => notifier.setMode(s.first),
              ),
              if (isCustom && customCats != null) ...[
                const SizedBox(height: 8),
                ...List.generate(customCats.length, (index) {
                  final cat = customCats[index];
                  return _CustomPercentRow(
                    category: cat,
                    onPercentChanged: (v) => _onCustomPercentChanged(index, v),
                    onDelete: cat.isBuiltin
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            _deleteCategory(index);
                          },
                  );
                }),
                Text(
                  'الإجمالي: ${customTotal.round()}%',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: (customTotal - 100).abs() > 0.5
                        ? Colors.red.shade700
                        : AppColors.emerald,
                  ),
                ),
                if (customCats.length < 6) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _showAddCategoryDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      '+ إضافة بند',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emerald,
                      side: const BorderSide(color: AppColors.emerald),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ],
              HomeSalaryField(
                label: 'الإيجار (اختياري)',
                value: state.rent,
                currencySymbol: 'ر.س',
                onChanged: notifier.setRent,
              ),
              if (result.rentWarning)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'إيجارك مرتفع — يستنزف ${result.rentPercentOfNet.toStringAsFixed(0)}% من راتبك',
                    style: GoogleFonts.cairo(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              ...List.generate(displayCategories.length, (i) {
                final cat = displayCategories[i];
                final color = _categoryColors[i % _categoryColors.length];
                final amount = amountFor(cat);
                final pct = isCustom && customCats != null
                    ? (customTotal > 0
                        ? cat.percent / customTotal * 100
                        : cat.percent)
                    : cat.percent;
                return _CategoryCard(
                  emoji: cat.emoji,
                  title: cat.name,
                  amount: amount,
                  percent: pct,
                  color: color,
                  fmt: fmt,
                );
              }),
              if (state.netSalary > 0) ...[
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: List.generate(displayCategories.length, (i) {
                        final cat = displayCategories[i];
                        final amount = amountFor(cat);
                        final pct = isCustom && customCats != null
                            ? (customTotal > 0
                                ? cat.percent / customTotal * 100
                                : cat.percent)
                            : cat.percent;
                        return PieChartSectionData(
                          value: amount > 0 ? amount : pct,
                          color: _categoryColors[i % _categoryColors.length],
                          title: '${pct.round()}%',
                          radius: 50 - (i * 4).toDouble(),
                          titleStyle: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        );
                      }),
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                    ),
                  ),
                ),
                Text(
                  'إذا ادّخرت ${fmt.format(amountFor(savingsCategory))} شهرياً لمدة ${state.savingsYears} سنوات = ${fmt.format(projectedSavings)}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 12, height: 1.45),
                ),
                Slider(
                  value: state.savingsYears.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: '${state.savingsYears} سنة',
                  onChanged: (v) => notifier.setYears(v.round()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomPercentRow extends StatelessWidget {
  const _CustomPercentRow({
    required this.category,
    required this.onPercentChanged,
    this.onDelete,
  });

  final _CustomCategory category;
  final ValueChanged<double> onPercentChanged;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassSurface(
        borderRadius: 14,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                category.name,
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            SizedBox(
              width: 64,
              child: TextFormField(
                key: ValueKey('${category.id}_${category.percent.round()}'),
                initialValue: category.percent.round().toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.cairo(fontWeight: FontWeight.w800),
                decoration: InputDecoration(
                  suffixText: '%',
                  suffixStyle: GoogleFonts.cairo(fontSize: 12),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onEditingComplete: () {
                  FocusScope.of(context).unfocus();
                },
                onFieldSubmitted: (text) {
                  final v = double.tryParse(text) ?? category.percent;
                  onPercentChanged(v);
                },
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                onPressed: onDelete,
                tooltip: 'حذف',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.emoji,
    required this.title,
    required this.amount,
    required this.percent,
    required this.color,
    required this.fmt,
  });

  final String emoji;
  final String title;
  final double amount;
  final double percent;
  final Color color;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassSurface(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w800)),
                  Text(
                    '${percent.round()}% · ${fmt.format(amount)}',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
