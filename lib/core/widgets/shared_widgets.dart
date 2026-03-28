import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../data/models.dart';

/// Reusable card with flat design, rounded corners, minimal border
class VtCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  const VtCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor ?? AppColors.border, width: 1),
        ),
        child: child,
      ),
    );
  }
}

/// Occupancy badge with color coding
class OccupancyBadge extends StatelessWidget {
  final OccupancyLevel level;
  final bool compact;

  const OccupancyBadge({super.key, required this.level, this.compact = false});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (level) {
      case OccupancyLevel.low:
        color = AppColors.occupancyLow;
        label = 'Low';
      case OccupancyLevel.medium:
        color = AppColors.occupancyMedium;
        label = 'Medium';
      case OccupancyLevel.high:
        color = AppColors.occupancyHigh;
        label = 'High';
    }

    if (compact) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Route line badge (colored pill)
class RouteBadge extends StatelessWidget {
  final String text;
  final int colorIndex;
  final double fontSize;

  const RouteBadge({
    super.key,
    required this.text,
    required this.colorIndex,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.busLineColors[colorIndex % AppColors.busLineColors.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// ETA countdown with animated number
class EtaDisplay extends StatelessWidget {
  final int minutes;
  final bool large;

  const EtaDisplay({super.key, required this.minutes, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$minutes',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: large ? 36 : 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        Text(
          'min',
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: large ? 14 : 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Pulsing dot indicator (for live status)
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({super.key, this.color = AppColors.primary, this.size = 8});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size + (_controller.value * 4),
          height: widget.size + (_controller.value * 4),
          decoration: BoxDecoration(
            color: widget.color.withAlpha(
              (153 + _controller.value * 102).round(),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

/// Section header
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          trailing ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

/// Animated progress bar
class ProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final double height;

  const ProgressBar({
    super.key,
    required this.progress,
    this.color = AppColors.primary,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

/// Speed indicator
class SpeedIndicator extends StatelessWidget {
  final double speed;

  const SpeedIndicator({super.key, required this.speed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.speed, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          '${speed.round()} km/h',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Drag handle for bottom sheets
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderLight,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
