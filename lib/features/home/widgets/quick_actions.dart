import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shapes.dart';
import '../../../core/theme/doodle_icons.dart';

class QuickActionsColumn extends StatelessWidget {
  final bool showHeatmap;
  final VoidCallback onToggleHeatmap;
  final VoidCallback onOpenFavorites;

  const QuickActionsColumn({
    super.key,
    required this.showHeatmap,
    required this.onToggleHeatmap,
    required this.onOpenFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionButton(
          icon: DoodleIcons.heatmap(
            size: 18,
            color: showHeatmap ? AppColors.primary : AppColors.textSecondary,
          ),
          isActive: showHeatmap,
          onTap: onToggleHeatmap,
        ),
        const SizedBox(height: 12),
        _ActionButton(
          icon: DoodleIcons.star(size: 18, color: AppColors.textSecondary),
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
        width: 48,
        height: 48,
        decoration: ShapeDecoration(
          color: isActive ? AppColors.primaryMuted : AppColors.backgroundCard,
          shape: AppShapes.hex,
        ),
        child: Center(child: icon),
      ),
    );
  }
}
