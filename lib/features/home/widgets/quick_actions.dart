import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/doodle_icons.dart';

class QuickActionsColumn extends StatelessWidget {
  final bool showHeatmap;
  final VoidCallback onToggleHeatmap;
  final VoidCallback onOpenAlerts;
  final VoidCallback onOpenFavorites;
  final int alertCount;

  const QuickActionsColumn({
    super.key,
    required this.showHeatmap,
    required this.onToggleHeatmap,
    required this.onOpenAlerts,
    required this.onOpenFavorites,
    this.alertCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionButton(
          icon: DoodleIcons.heatmap(
            size: 20,
            color: showHeatmap ? AppColors.primary : AppColors.textSecondary,
          ),
          isActive: showHeatmap,
          onTap: onToggleHeatmap,
        ),
        const SizedBox(height: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _ActionButton(
              icon: DoodleIcons.alert(
                size: 20,
                color: AppColors.textSecondary,
              ),
              onTap: onOpenAlerts,
            ),
            if (alertCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$alertCount',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _ActionButton(
          icon: DoodleIcons.star(
            size: 20,
            color: AppColors.textSecondary,
          ),
          onTap: onOpenFavorites,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryMuted
              : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border,
          ),
        ),
        child: Center(child: icon),
      ),
    );
  }
}
