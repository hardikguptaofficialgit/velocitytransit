import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/doodle_icons.dart';
import '../../../core/data/models.dart';
import '../../../core/widgets/shared_widgets.dart';

class NearbyBusCard extends StatelessWidget {
  final Bus bus;
  final TransitRoute route;
  final VoidCallback? onTap;

  const NearbyBusCard({
    super.key,
    required this.bus,
    required this.route,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    var etaMinutes = 2 + Random(bus.id.hashCode).nextInt(15);
    // Add real-time AI delay
    etaMinutes += bus.estimatedDelay;

    final nextStop = route.stops[
        (bus.currentStopIndex + 1).clamp(0, route.stops.length - 1)];

    return VtCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Route badge
          RouteBadge(text: route.shortName, colorIndex: route.colorIndex),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    DoodleIcons.pin(size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Next: ${nextStop.name}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(child: Wrap(children: [OccupancyBadge(level: bus.occupancy, compact: false)])),
                    const SizedBox(width: 8),
                    Flexible(child: SpeedIndicator(speed: bus.speed)),
                  ],
                ),
                if (bus.suggestedAction != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            bus.suggestedAction!,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),
          // ETA
          EtaDisplay(minutes: etaMinutes),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }
}
