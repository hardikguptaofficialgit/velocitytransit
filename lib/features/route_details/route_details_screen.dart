import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/doodle_icons.dart';
import '../../core/data/models.dart';
import '../../core/providers/transit_provider.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/router/app_router.dart';

class RouteDetailsScreen extends ConsumerWidget {
  final String routeId;

  const RouteDetailsScreen({super.key, required this.routeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transitProvider);
    final route = state.routes.cast<TransitRoute?>().firstWhere(
          (r) => r?.id == routeId,
          orElse: () => null,
        );

    if (route == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(title: const Text('Route Not Found')),
        body: const Center(
          child: Text('Route data unavailable',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final busesOnRoute = state.buses.where((b) => b.routeId == routeId).toList();
    final color = AppColors.busLineColors[route.colorIndex % AppColors.busLineColors.length];
    // Simulate a progress value from the first bus on this route
    final activeProgress = busesOnRoute.isNotEmpty
        ? busesOnRoute.first.progress
        : 0.0;
    final activeStopIdx = busesOnRoute.isNotEmpty
        ? busesOnRoute.first.currentStopIndex
        : 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(route.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (busesOnRoute.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRouter.liveTracking,
                  arguments: busesOnRoute.first.id,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PulsingDot(color: AppColors.primary, size: 5),
                      const SizedBox(width: 6),
                      const Text(
                        'Track Live',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.backgroundCard,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  RouteBadge(
                    text: route.shortName,
                    colorIndex: route.colorIndex,
                    fontSize: 16,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${route.stops.length} stops · ${busesOnRoute.length} buses active',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Route progress bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ROUTE PROGRESS',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ProgressBar(progress: activeProgress, color: color),
                ],
              ),
            ),

            // Active buses
            if (busesOnRoute.isNotEmpty) ...[
              const SectionHeader(title: 'Active Buses'),
              const SizedBox(height: 4),
              SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: busesOnRoute.length,
                  itemBuilder: (context, index) {
                    final bus = busesOnRoute[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRouter.liveTracking,
                          arguments: bus.id,
                        ),
                        child: VtCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              DoodleIcons.bus(size: 20, color: color),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bus.number,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  if (bus.driverName?.isNotEmpty == true)
                                    Text(
                                      bus.driverName!,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  if (bus.driverName?.isNotEmpty == true)
                                    const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      OccupancyBadge(
                                        level: bus.occupancy,
                                        compact: true,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${bus.speed.round()} km/h',
                                        style: const TextStyle(
                                          color: AppColors.textTertiary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Vertical stop timeline
            const SectionHeader(title: 'Stops'),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: List.generate(route.stops.length, (index) {
                  final stop = route.stops[index];
                  final isPast = index < activeStopIdx;
                  final isCurrent = index == activeStopIdx;

                  return _StopTimelineItem(
                    name: stop.name,
                    color: color,
                    isPast: isPast,
                    isCurrent: isCurrent,
                    isFirst: index == 0,
                    isLast: index == route.stops.length - 1,
                    index: index,
                  );
                }),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StopTimelineItem extends StatelessWidget {
  final String name;
  final Color color;
  final bool isPast;
  final bool isCurrent;
  final bool isFirst;
  final bool isLast;
  final int index;

  const _StopTimelineItem({
    required this.name,
    required this.color,
    required this.isPast,
    required this.isCurrent,
    required this.isFirst,
    required this.isLast,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Timeline column
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  if (!isFirst)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isPast || isCurrent
                            ? color
                            : AppColors.borderLight,
                      ),
                    ),
                  Container(
                    width: isCurrent ? 18 : 12,
                    height: isCurrent ? 18 : 12,
                    decoration: BoxDecoration(
                      color: isPast || isCurrent
                          ? color
                          : AppColors.backgroundElevated,
                      shape: BoxShape.circle,
                      border: isPast || isCurrent
                          ? null
                          : Border.all(color: AppColors.borderLight, width: 2),
                    ),
                    child: isCurrent
                        ? Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.textOnPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isPast ? color : AppColors.borderLight,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Stop info
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(color: AppColors.divider),
                        ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: isCurrent
                                  ? AppColors.textPrimary
                                  : isPast
                                      ? AppColors.textTertiary
                                      : AppColors.textSecondary,
                              fontSize: isCurrent ? 15 : 14,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                          if (isCurrent)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Bus approaching',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMuted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    if (isPast)
                      const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
