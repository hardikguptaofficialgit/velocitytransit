import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/doodle_icons.dart';
import '../../core/data/models.dart';
import '../../core/providers/transit_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/shared_widgets.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final String busId;

  const LiveTrackingScreen({super.key, required this.busId});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitProvider);
    final bus = state.buses.cast<Bus?>().firstWhere(
          (b) => b?.id == widget.busId,
          orElse: () => null,
        );

    if (bus == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(title: const Text('Bus Not Found')),
        body: const Center(
          child: Text(
            'Bus data unavailable',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final route = state.routes.firstWhere((r) => r.id == bus.routeId);
    final nextStopIdx =
        (bus.currentStopIndex + 1).clamp(0, route.stops.length - 1);
    final nextStop = route.stops[nextStopIdx];
    final etaMinutes = 1 + Random(bus.id.hashCode + DateTime.now().second).nextInt(8);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Simulated tracking map
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: bus.position,
                initialZoom: 14.5,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.velocitytransit.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: route.pathPoints,
                      color: AppColors.busLineColors[route.colorIndex % AppColors.busLineColors.length].withValues(alpha: 0.6),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    ...route.stops.map(
                      (stop) {
                        final isPast = route.stops.indexOf(stop) < bus.currentStopIndex;
                        return Marker(
                          point: stop.position,
                          width: isPast ? 10 : 14,
                          height: isPast ? 10 : 14,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.backgroundCard,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.busLineColors[route.colorIndex % AppColors.busLineColors.length].withValues(alpha: isPast ? 0.4 : 1.0),
                                width: isPast ? 2 : 3,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Marker(
                      point: bus.position,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.busLineColors[route.colorIndex % AppColors.busLineColors.length],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.busLineColors[route.colorIndex % AppColors.busLineColors.length].withValues(alpha: 0.4),
                              blurRadius: 10 + (_pulseController.value * 12),
                              spreadRadius: _pulseController.value * 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: DoodleIcons.bus(size: 20, color: AppColors.backgroundCard),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              color: AppColors.backgroundLight.withValues(alpha: 0.85),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Icon(Icons.arrow_back_ios_new,
                            size: 16, color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  RouteBadge(
                    text: route.shortName,
                    colorIndex: route.colorIndex,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bus ${bus.number}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            PulsingDot(color: AppColors.primary, size: 5),
                            const SizedBox(width: 6),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Playback button
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRouter.tripPlayback,
                      arguments: widget.busId,
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: DoodleIcons.play(
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ETA Countdown overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 16,
            child: _buildEtaCard(etaMinutes, nextStop.name),
          ),

          // Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(bus, route),
          ),
        ],
      ),
    );
  }

  Widget _buildEtaCard(int etaMinutes, String nextStop) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          EtaDisplay(minutes: etaMinutes, large: true),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DoodleIcons.pin(size: 12, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(
                nextStop,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(Bus bus, TransitRoute route) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),

          // Status row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                OccupancyBadge(level: bus.occupancy),
                const SizedBox(width: 12),
                SpeedIndicator(speed: bus.speed),
                const Spacer(),
                const Text(
                  'On time',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Route progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ProgressBar(progress: bus.progress),
          ),

          const SizedBox(height: 16),

          // Stops timeline
          SizedBox(
            height: 180,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: route.stops.length,
              itemBuilder: (context, index) {
                final stop = route.stops[index];
                final isPast = index < bus.currentStopIndex;
                final isCurrent = index == bus.currentStopIndex;
                final isNext = index == bus.currentStopIndex + 1;
                final color = AppColors.busLineColors[
                    route.colorIndex % AppColors.busLineColors.length];

                return Row(
                  children: [
                    // Timeline
                    SizedBox(
                      width: 30,
                      child: Column(
                        children: [
                          if (index > 0)
                            Container(
                              width: 2,
                              height: 12,
                              color: isPast || isCurrent
                                  ? color
                                  : AppColors.borderLight,
                            ),
                          Container(
                            width: isCurrent ? 14 : 10,
                            height: isCurrent ? 14 : 10,
                            decoration: BoxDecoration(
                              color: isPast || isCurrent
                                  ? color
                                  : AppColors.backgroundElevated,
                              shape: BoxShape.circle,
                              border: isPast || isCurrent
                                  ? null
                                  : Border.all(
                                      color: AppColors.borderLight, width: 2),
                            ),
                          ),
                          if (index < route.stops.length - 1)
                            Container(
                              width: 2,
                              height: 12,
                              color: isPast
                                  ? color
                                  : AppColors.borderLight,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              stop.name,
                              style: TextStyle(
                                color: isCurrent || isNext
                                    ? AppColors.textPrimary
                                    : isPast
                                        ? AppColors.textTertiary
                                        : AppColors.textSecondary,
                                fontSize: isCurrent ? 14 : 13,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryMuted,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'NOW',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}

