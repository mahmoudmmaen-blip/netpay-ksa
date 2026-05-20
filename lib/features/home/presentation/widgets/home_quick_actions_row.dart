import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:netgulf/core/domain/gulf_country.dart';
import 'package:netgulf/core/theme/app_colors.dart';

/// زر إجراء سريع أفقي.
class HomeQuickActionItem {
  const HomeQuickActionItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
    this.locked = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;
  final bool locked;
}

/// شريط أدوات سريعة — تمرير أفقي.
class HomeQuickActionsRow extends StatelessWidget {
  const HomeQuickActionsRow({
    super.key,
    required this.country,
    required this.items,
  });

  final GulfCountry country;
  final List<HomeQuickActionItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 12),
          child: Text(
            'أدوات سريعة',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.emeraldLight,
            ),
          ),
        ),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _ActionChip(item: item);
            },
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.item});
  final HomeQuickActionItem item;

  @override
  Widget build(BuildContext context) {
    final highlighted = item.highlighted && !item.locked;
    final locked = item.locked;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 118,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: highlighted
                ? const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFF1E293B),
                      Color(0xFF064E3B),
                      AppColors.emeraldDark,
                    ],
                  )
                : null,
            color: highlighted
                ? null
                : locked
                    ? AppColors.navyMid.withValues(alpha: 0.55)
                    : Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.6),
            border: Border.all(
              color: locked
                  ? AppColors.gold.withValues(alpha: 0.4)
                  : highlighted
                      ? AppColors.gold.withValues(alpha: 0.55)
                      : AppColors.glassBorder,
              width: highlighted || locked ? 1.5 : 1,
            ),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 28,
                      color: locked
                          ? AppColors.gold.withValues(alpha: 0.7)
                          : highlighted
                              ? AppColors.goldBright
                              : AppColors.emerald,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: locked
                            ? Colors.white.withValues(alpha: 0.65)
                            : highlighted
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (locked)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.6),
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 14,
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
