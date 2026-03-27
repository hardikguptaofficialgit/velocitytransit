import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/doodle_icons.dart';
import '../../../core/data/models.dart';
import '../../../core/data/simulation_data.dart';
import '../../../core/providers/transit_provider.dart';

/// Interactive Map using flutter_map and OpenStreetMap
class SimulatedMapView extends ConsumerStatefulWidget {
  const SimulatedMapView({super.key});

  @override
  ConsumerState<SimulatedMapView> createState() => _SimulatedMapViewState();
}

class _SimulatedMapViewState extends ConsumerState<SimulatedMapView> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitProvider);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(20.2961, 85.8245), // Bhubaneswar Center
        initialZoom: 13.0,
        maxZoom: 18.0,
        minZoom: 10.0,
      ),
      children: [
        // Beautiful minimal light map theme (Carto Voyager)
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.velocitytransit.app',
        ),

        // Heatmap layer
        if (state.showHeatmap) _buildHeatmapLayer(),

        // Routes
        _buildRoutesLayer(state.routes),

        // Stops
        _buildStopsLayer(state.routes),

        // Live buses
        _buildBusesLayer(state.buses, state.routes),
      ],
    );
  }

  Widget _buildHeatmapLayer() {
    final circles = <CircleMarker>[];
    for (final zone in SimulationData.demandZones) {
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
          color: color.withValues(alpha: 0.3),
          borderColor: color.withValues(alpha: 0.6),
          borderStrokeWidth: 1.5,
          radius: zone.radius / 15.0, // Scale down virtual radius for map zoom presentation
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
      final color = AppColors.busLineColors[route.colorIndex % AppColors.busLineColors.length];
      
      polylines.add(
        Polyline(
          points: route.pathPoints,
          color: color.withValues(alpha: 0.6),
          strokeWidth: 4.0,
        ),
      );
    }
    return PolylineLayer(polylines: polylines);
  }

  Widget _buildStopsLayer(List<TransitRoute> routes) {
    final markers = <Marker>[];
    for (final route in routes) {
      final color = AppColors.busLineColors[route.colorIndex % AppColors.busLineColors.length];
      
      for (final stop in route.stops) {
        markers.add(
          Marker(
            point: stop.position,
            width: 14,
            height: 14,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
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
      final route = routes.firstWhere((r) => r.id == bus.routeId);
      final routeColor = AppColors.busLineColors[route.colorIndex % AppColors.busLineColors.length];

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
          point: bus.position,
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Bus background pill
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: routeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.backgroundCard, width: 2),
                ),
                child: Center(
                  child: DoodleIcons.bus(size: 20, color: AppColors.backgroundCard),
                ),
              ),
              // Occupancy indicator pip
              Positioned(
                top: 0,
                right: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: occColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.backgroundCard, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // An animated layer representation ensures the markers render dynamically
    return MarkerLayer(markers: markers);
  }
}
