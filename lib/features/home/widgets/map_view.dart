import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/models.dart';
import '../../../core/providers/passenger_location_provider.dart';
import '../../../core/providers/transit_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/doodle_icons.dart';

class SimulatedMapView extends ConsumerStatefulWidget {
  const SimulatedMapView({super.key});

  @override
  ConsumerState<SimulatedMapView> createState() => _SimulatedMapViewState();
}

class _SimulatedMapViewState extends ConsumerState<SimulatedMapView>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  AnimationController? _busMotionController;
  LatLng? _lastCenteredPosition;
  double _lastZoom = 13.4;
  final Map<String, LatLng> _busAnimationStarts = {};
  final Map<String, LatLng> _busAnimationTargets = {};

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _ensureBusMotionController();
  }

  @override
  void dispose() {
    _busMotionController?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  AnimationController get _resolvedBusMotionController {
    _ensureBusMotionController();
    return _busMotionController!;
  }

  void _ensureBusMotionController() {
    _busMotionController ??=
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 700),
        )..value = 1;
  }

  void _syncAnimatedBuses(List<Bus> buses) {
    final activeIds = buses.map((bus) => bus.id).toSet();
    _busAnimationStarts.removeWhere((id, _) => !activeIds.contains(id));
    _busAnimationTargets.removeWhere((id, _) => !activeIds.contains(id));

    var changed = false;
    for (final bus in buses) {
      final currentTarget = _busAnimationTargets[bus.id];
      if (currentTarget == null) {
        _busAnimationStarts[bus.id] = bus.position;
        _busAnimationTargets[bus.id] = bus.position;
        continue;
      }
      if (currentTarget.distanceTo(bus.position) < 0.5) continue;
      _busAnimationStarts[bus.id] = _animatedPositionFor(bus.id);
      _busAnimationTargets[bus.id] = bus.position;
      changed = true;
    }

    if (changed) {
      _resolvedBusMotionController.forward(from: 0);
    }
  }

  LatLng _animatedPositionFor(String busId) {
    final start = _busAnimationStarts[busId] ?? _busAnimationTargets[busId];
    final target = _busAnimationTargets[busId] ?? start;
    if (start == null || target == null) {
      return const LatLng(0, 0);
    }
    final t = Curves.easeInOutCubic.transform(_resolvedBusMotionController.value);
    return start.interpolate(target, t);
  }

  @override
  Widget build(BuildContext context) {
    _ensureBusMotionController();
    final state = ref.watch(transitProvider);
    final passengerLocation = ref.watch(passengerLocationProvider);
    final mapCenter = passengerLocation.position ?? state.passengerAnchor;
    _syncAnimatedBuses(state.buses);

    final livePassengerMarkers = <Marker>[
      if (passengerLocation.position != null)
        Marker(
          point: passengerLocation.position!,
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.backgroundCard, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
    ];

    final latestPassengerPosition = passengerLocation.position;
    if (latestPassengerPosition != null &&
        (_lastCenteredPosition == null ||
            _lastCenteredPosition!.distanceTo(latestPassengerPosition) > 20)) {
      _lastCenteredPosition = latestPassengerPosition;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(transitProvider.notifier)
            .ensureNetworkForPassenger(latestPassengerPosition);
        final nextZoom = _mapController.camera.zoom < 13.4
            ? 13.4
            : _mapController.camera.zoom;
        _lastZoom = nextZoom;
        _mapController.move(latestPassengerPosition, nextZoom);
      });
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: mapCenter,
        initialZoom: 13.4,
        maxZoom: 18.5,
        minZoom: 10.5,
        interactionOptions: const InteractionOptions(
          flags:
              InteractiveFlag.drag |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom,
        ),
        onPositionChanged: (position, hasGesture) {
          _lastZoom = position.zoom;
        },
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.velocitytransit.app',
          panBuffer: 4,
        ),
        if (state.showHeatmap) _buildHeatmapLayer(),
        _buildRoutesLayer(state.routes),
        _buildStopsLayer(state.routes),
        MarkerLayer(markers: livePassengerMarkers),
        AnimatedBuilder(
          animation: _resolvedBusMotionController,
          builder: (context, _) => _buildBusesLayer(state.buses, state.routes),
        ),
        Positioned(right: 14, bottom: 150, child: _buildMapTools(mapCenter)),
      ],
    );
  }

  Widget _buildMapTools(LatLng mapCenter) {
    return Column(
      children: [
        _MapToolButton(
          icon: Icons.add_rounded,
          onTap: () {
            _lastZoom = (_lastZoom + 0.6).clamp(10.5, 18.5);
            _mapController.move(_mapController.camera.center, _lastZoom);
          },
        ),
        const SizedBox(height: 10),
        _MapToolButton(
          icon: Icons.my_location_rounded,
          onTap: () => _mapController.move(mapCenter, _lastZoom),
        ),
      ],
    );
  }

  Widget _buildHeatmapLayer() {
    final circles = <CircleMarker>[];
    final zones = ref.watch(transitProvider).demandZones;
    for (final zone in zones) {
      Color color;
      if (zone.intensity > 0.8) {
        color = AppColors.heatmapCritical;
      } else if (zone.intensity > 0.6) {
        color = AppColors.heatmapHigh;
      } else if (zone.intensity > 0.3) {
        color = AppColors.heatmapMedium;
      } else {
        color = AppColors.heatmapLow;
      }

      circles.add(
        CircleMarker(
          point: zone.center,
          color: color.withValues(alpha: 0.24),
          borderColor: color.withValues(alpha: 0.5),
          borderStrokeWidth: 1.2,
          radius: zone.radius / 15.0,
          useRadiusInMeter: false,
        ),
      );
    }
    return CircleLayer(circles: circles);
  }

  Widget _buildRoutesLayer(List<TransitRoute> routes) {
    final polylines = <Polyline>[];
    for (final route in routes) {
      if (route.pathPoints.length < 2) continue;
      final color = AppColors
          .busLineColors[route.colorIndex % AppColors.busLineColors.length];

      polylines.add(
        Polyline(
          points: route.pathPoints,
          color: color.withValues(alpha: 0.72),
          strokeWidth: 4.5,
        ),
      );
    }
    return PolylineLayer(polylines: polylines);
  }

  Widget _buildStopsLayer(List<TransitRoute> routes) {
    final markers = <Marker>[];
    for (final route in routes) {
      final color = AppColors
          .busLineColors[route.colorIndex % AppColors.busLineColors.length];

      for (final stop in route.stops) {
        markers.add(
          Marker(
            point: stop.position,
            width: 13,
            height: 13,
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.92),
                  width: 2.5,
                ),
              ),
            ),
          ),
        );
      }
    }
    return MarkerLayer(markers: markers);
  }

  Widget _buildBusesLayer(List<Bus> buses, List<TransitRoute> routes) {
    final markers = <Marker>[];

    for (final bus in buses) {
      final route = routes.cast<TransitRoute?>().firstWhere(
        (r) => r?.id == bus.routeId,
        orElse: () => null,
      );
      final routeColor = route == null
          ? AppColors.primary
          : AppColors
              .busLineColors[route.colorIndex % AppColors.busLineColors.length];

      Color occColor;
      switch (bus.occupancy) {
        case OccupancyLevel.low:
          occColor = AppColors.occupancyLow;
          break;
        case OccupancyLevel.medium:
          occColor = AppColors.occupancyMedium;
          break;
        case OccupancyLevel.high:
          occColor = AppColors.occupancyHigh;
          break;
      }

      markers.add(
        Marker(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          point: _animatedPositionFor(bus.id),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.rotate(
                angle: bus.heading * pi / 180,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: routeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.backgroundCard,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: DoodleIcons.bus(
                      size: 18,
                      color: AppColors.backgroundCard,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 1,
                right: -1,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: occColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.backgroundCard,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return MarkerLayer(markers: markers);
  }
}

class _MapToolButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapToolButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 19, color: AppColors.textPrimary),
      ),
    );
  }
}
