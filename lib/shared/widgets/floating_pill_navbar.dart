import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import 'glass_container.dart';

class FloatingPillNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isCollapsed;

  const FloatingPillNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Ana Sayfa'),
      _NavItem(icon: Icons.bar_chart_rounded, label: 'Top 50'),
      _NavItem(icon: Icons.grid_view_rounded, label: 'Kategoriler'),
      _NavItem(icon: Icons.favorite_rounded, label: 'Favoriler'),
      _NavItem(icon: Icons.settings_rounded, label: 'Ayarlar'),
    ];

    return AnimatedContainer(
      duration: AppTokens.animFast,
      margin: const EdgeInsets.fromLTRB(AppTokens.padLg, 0, AppTokens.padLg, AppTokens.padMd),
      child: GlassContainer(
        useBlur: true,
        borderRadius: AppTokens.radiusPill,
        padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 8, vertical: 8),
        color: isDark
            ? AppColors.racingGreenDeepest.withOpacity(0.85)
            : AppColors.lightSurface.withOpacity(0.85),
        border: Border.all(
          color: isDark ? AppColors.wineRedAccent.withOpacity(0.3) : AppColors.glassBorderLight,
          width: 1.5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isSelected = currentIndex == index;
            final item = items[index];

            return InkWell(
              onTap: () => onTap(index),
              borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              child: AnimatedContainer(
                duration: AppTokens.animFast,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected && !isCollapsed ? 14 : 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.wineRedAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  boxShadow: isSelected ? AppTokens.glowShadowGold : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.icon,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      size: 22,
                    ),
                    if (isSelected && !isCollapsed) ...[
                      const SizedBox(width: 6),
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem({required this.icon, required this.label});
}
