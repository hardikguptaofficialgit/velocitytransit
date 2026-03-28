import 'dart:math';
import '../data/models.dart';

/// Predefined simulation data for offline demo mode
class SimulationData {
  SimulationData._();

  // ── City center: simulated coordinates (Bhubaneswar-inspired) ──
  static const _centerLat = 20.2961;
  static const _centerLng = 85.8245;
  static const LatLng defaultAnchor = LatLng(_centerLat, _centerLng);

  static final List<TransitRoute> routes = [
    TransitRoute(
      id: 'route_1',
      name: 'Grand Avenue Express',
      shortName: 'G1',
      colorIndex: 0,
      stops: _route1Stops,
      pathPoints: _generatePathPoints(_route1Stops),
    ),
    TransitRoute(
      id: 'route_2',
      name: 'Tech Park Shuttle',
      shortName: 'T2',
      colorIndex: 1,
      stops: _route2Stops,
      pathPoints: _generatePathPoints(_route2Stops),
    ),
    TransitRoute(
      id: 'route_3',
      name: 'Airport Link',
      shortName: 'A3',
      colorIndex: 2,
      stops: _route3Stops,
      pathPoints: _generatePathPoints(_route3Stops),
    ),
    TransitRoute(
      id: 'route_4',
      name: 'University Loop',
      shortName: 'U4',
      colorIndex: 3,
      stops: _route4Stops,
      pathPoints: _generatePathPoints(_route4Stops),
    ),
    TransitRoute(
      id: 'route_5',
      name: 'Central Business District',
      shortName: 'C5',
      colorIndex: 4,
      stops: _route5Stops,
      pathPoints: _generatePathPoints(_route5Stops),
    ),
  ];

  static final List<BusStop> _route1Stops = [
    BusStop(
      id: 's1_1',
      name: 'West Terminal',
      position: LatLng(_centerLat, _centerLng),
    ),
    BusStop(
      id: 's1_2',
      name: 'Central Square',
      position: LatLng(_centerLat + 0.005, _centerLng + 0.003),
    ),
    BusStop(
      id: 's1_3',
      name: 'Plaza West',
      position: LatLng(_centerLat + 0.01, _centerLng + 0.007),
    ),
    BusStop(
      id: 's1_4',
      name: 'Main Hub',
      position: LatLng(_centerLat + 0.014, _centerLng + 0.012),
    ),
    BusStop(
      id: 's1_5',
      name: 'Bridge Street',
      position: LatLng(_centerLat + 0.018, _centerLng + 0.016),
    ),
    BusStop(
      id: 's1_6',
      name: 'North Point',
      position: LatLng(_centerLat + 0.025, _centerLng + 0.018),
    ),
    BusStop(
      id: 's1_7',
      name: 'East Terminal',
      position: LatLng(_centerLat + 0.035, _centerLng + 0.015),
    ),
  ];

  static final List<BusStop> _route2Stops = [
    BusStop(
      id: 's2_1',
      name: 'Tech Hub Central',
      position: LatLng(_centerLat + 0.02, _centerLng - 0.01),
    ),
    BusStop(
      id: 's2_2',
      name: 'Innovation Park',
      position: LatLng(_centerLat + 0.025, _centerLng - 0.005),
    ),
    BusStop(
      id: 's2_3',
      name: 'Startup Alley',
      position: LatLng(_centerLat + 0.03, _centerLng),
    ),
    BusStop(
      id: 's2_4',
      name: 'Data Center',
      position: LatLng(_centerLat + 0.032, _centerLng + 0.008),
    ),
    BusStop(
      id: 's2_5',
      name: 'Cloud Campus',
      position: LatLng(_centerLat + 0.028, _centerLng + 0.015),
    ),
    BusStop(
      id: 's2_6',
      name: 'Tech Park East',
      position: LatLng(_centerLat + 0.022, _centerLng + 0.022),
    ),
  ];

  static final List<BusStop> _route3Stops = [
    BusStop(
      id: 's3_1',
      name: 'Terminal 1',
      position: LatLng(_centerLat + 0.05, _centerLng + 0.03),
    ),
    BusStop(
      id: 's3_2',
      name: 'Cargo Area',
      position: LatLng(_centerLat + 0.042, _centerLng + 0.025),
    ),
    BusStop(
      id: 's3_3',
      name: 'Airport Metro',
      position: LatLng(_centerLat + 0.035, _centerLng + 0.02),
    ),
    BusStop(
      id: 's3_4',
      name: 'Highway Junction',
      position: LatLng(_centerLat + 0.025, _centerLng + 0.015),
    ),
    BusStop(
      id: 's3_5',
      name: 'City Center',
      position: LatLng(_centerLat + 0.01, _centerLng + 0.005),
    ),
    BusStop(
      id: 's3_6',
      name: 'South Terminal',
      position: LatLng(_centerLat - 0.005, _centerLng),
    ),
  ];

  static final List<BusStop> _route4Stops = [
    BusStop(
      id: 's4_1',
      name: 'University Gate',
      position: LatLng(_centerLat - 0.01, _centerLng + 0.01),
    ),
    BusStop(
      id: 's4_2',
      name: 'Library Point',
      position: LatLng(_centerLat - 0.005, _centerLng + 0.015),
    ),
    BusStop(
      id: 's4_3',
      name: 'Sports Complex',
      position: LatLng(_centerLat, _centerLng + 0.02),
    ),
    BusStop(
      id: 's4_4',
      name: 'Hostel Area',
      position: LatLng(_centerLat + 0.005, _centerLng + 0.015),
    ),
    BusStop(
      id: 's4_5',
      name: 'Research Block',
      position: LatLng(_centerLat + 0.005, _centerLng + 0.01),
    ),
    BusStop(
      id: 's4_6',
      name: 'Main Gate',
      position: LatLng(_centerLat - 0.01, _centerLng + 0.01),
    ),
  ];

  static final List<BusStop> _route5Stops = [
    BusStop(
      id: 's5_1',
      name: 'CBD North',
      position: LatLng(_centerLat + 0.008, _centerLng - 0.005),
    ),
    BusStop(
      id: 's5_2',
      name: 'Financial Tower',
      position: LatLng(_centerLat + 0.012, _centerLng),
    ),
    BusStop(
      id: 's5_3',
      name: 'Stock Exchange',
      position: LatLng(_centerLat + 0.015, _centerLng + 0.005),
    ),
    BusStop(
      id: 's5_4',
      name: 'Trade Center',
      position: LatLng(_centerLat + 0.012, _centerLng + 0.012),
    ),
    BusStop(
      id: 's5_5',
      name: 'Business Bay',
      position: LatLng(_centerLat + 0.008, _centerLng + 0.018),
    ),
    BusStop(
      id: 's5_6',
      name: 'CBD South',
      position: LatLng(_centerLat + 0.003, _centerLng + 0.015),
    ),
  ];

  static List<Bus> initialBuses() {
    return initialBusesForRoutes(routes);
  }

  static List<Bus> initialBusesForRoutes(List<TransitRoute> routes) {
    final occupancies = OccupancyLevel.values;
    final buses = <Bus>[];
    final driverNames = [
      'Amit',
      'Neha',
      'Rohan',
      'Priya',
      'Sanjay',
      'Kiran',
      'Meera',
      'Arjun',
      'Vikram',
      'Isha',
      'Kabir',
      'Naina',
      'Rahul',
      'Pooja',
      'Dev',
    ];

    for (var routeIndex = 0; routeIndex < routes.length; routeIndex++) {
      final route = routes[routeIndex];
      final busCount = (route.stops.length <= 6 ? 4 : 5) + (routeIndex.isEven ? 1 : 0);
      for (var i = 0; i < busCount; i++) {
        final seededOffset = ((routeIndex * 17) + (i * 11)) % 100;
        final progress = (seededOffset / 100).clamp(0.04, 0.96);
        final pos = _positionOnRoute(route, progress);
        final speed = 16 + ((routeIndex * 9 + i * 6) % 23).toDouble();
        final currentStopIndex =
            ((progress * route.stops.length).floor()).clamp(0, route.stops.length - 1);
        final occupancy = occupancies[(routeIndex + i) % occupancies.length];
        final heading = _headingOnRoute(route, progress);
        final estimatedDelay = speed < 20 ? 3 : speed < 26 ? 1 : 0;
        final isHoldingAtStop = i == busCount - 1 && routeIndex.isOdd;
        buses.add(
          Bus(
            id: '${route.id}_bus_$i',
            number: '${route.shortName}-${110 + (routeIndex * 10) + i}',
            routeId: route.id,
            routeName: route.name,
            routeShortName: route.shortName,
            driverId: 'demo_driver_${routeIndex}_$i',
            driverName: driverNames[(routeIndex * 3 + i) % driverNames.length],
            position: pos,
            heading: heading,
            speed: isHoldingAtStop ? 8 : speed,
            occupancy: occupancy,
            currentStopIndex: currentStopIndex,
            progress: progress,
            isOnline: true,
            estimatedDelay: isHoldingAtStop ? 4 : estimatedDelay,
            status: isHoldingAtStop ? 'boarding' : 'active',
            suggestedAction: _demoSuggestedAction(
              route: route,
              progress: progress,
              occupancy: occupancy,
              estimatedDelay: isHoldingAtStop ? 4 : estimatedDelay,
            ),
          ),
        );
      }
    }
    return buses;
  }

  static List<TransitRoute> routesNearPassenger(
    LatLng anchor, {
    Map<String, List<LatLng>> snappedPaths = const {},
  }) {
    final templates = <_RouteTemplate>[
      _RouteTemplate(
        id: 'route_1',
        name: 'Grand Avenue Express',
        shortName: 'G1',
        colorIndex: 0,
        stopNames: const [
          'West Terminal',
          'Civic Center',
          'Market Road',
          'Main Hub',
          'Bridge Street',
          'North Point',
          'East Terminal',
        ],
        stopOffsets: const [
          (-0.018, -0.028),
          (-0.012, -0.017),
          (-0.006, -0.008),
          (0.000, 0.000),
          (0.008, 0.010),
          (0.015, 0.018),
          (0.020, 0.028),
        ],
      ),
      _RouteTemplate(
        id: 'route_2',
        name: 'Tech Park Shuttle',
        shortName: 'T2',
        colorIndex: 1,
        stopNames: const [
          'Depot West',
          'Innovation Park',
          'Startup Square',
          'Data Center',
          'Cloud Campus',
          'Tech Park East',
        ],
        stopOffsets: const [
          (0.010, -0.022),
          (0.016, -0.013),
          (0.020, -0.004),
          (0.018, 0.007),
          (0.012, 0.016),
          (0.006, 0.024),
        ],
      ),
      _RouteTemplate(
        id: 'route_3',
        name: 'Airport Link',
        shortName: 'A3',
        colorIndex: 2,
        stopNames: const [
          'Terminal Spur',
          'Logistics Hub',
          'Metro Interchange',
          'Highway Junction',
          'City Center',
          'South Terminal',
        ],
        stopOffsets: const [
          (0.028, 0.030),
          (0.022, 0.022),
          (0.016, 0.014),
          (0.010, 0.006),
          (0.004, -0.002),
          (-0.006, -0.012),
        ],
      ),
      _RouteTemplate(
        id: 'route_4',
        name: 'University Loop',
        shortName: 'U4',
        colorIndex: 3,
        stopNames: const [
          'Campus Gate',
          'Library Point',
          'Sports Complex',
          'Hostel Area',
          'Research Block',
          'Main Gate',
        ],
        stopOffsets: const [
          (-0.014, 0.004),
          (-0.010, 0.012),
          (-0.002, 0.018),
          (0.006, 0.013),
          (0.003, 0.005),
          (-0.010, 0.002),
        ],
      ),
      _RouteTemplate(
        id: 'route_5',
        name: 'Central Business District',
        shortName: 'C5',
        colorIndex: 4,
        stopNames: const [
          'CBD North',
          'Finance Square',
          'Trade Center',
          'Business Bay',
          'South Exchange',
          'Riverside',
        ],
        stopOffsets: const [
          (0.002, -0.014),
          (0.007, -0.006),
          (0.011, 0.003),
          (0.008, 0.014),
          (0.002, 0.020),
          (-0.005, 0.012),
        ],
      ),
    ];

    return templates.map((template) {
      final stops = <BusStop>[];
      for (var index = 0; index < template.stopNames.length; index++) {
        final offset = template.stopOffsets[index];
        stops.add(
          BusStop(
            id: '${template.id}_stop_$index',
            name: template.stopNames[index],
            position: LatLng(
              anchor.latitude + offset.$1,
              anchor.longitude + offset.$2,
            ),
          ),
        );
      }

      final fallbackPath = _generatePathPoints(stops);
      return TransitRoute(
        id: template.id,
        name: template.name,
        shortName: template.shortName,
        colorIndex: template.colorIndex,
        stops: stops,
        pathPoints: (snappedPaths[template.id]?.length ?? 0) >= 2
            ? snappedPaths[template.id]!
            : fallbackPath,
      );
    }).toList();
  }

  static List<DemandZone> demandZonesForAnchor(LatLng anchor) {
    return [
      DemandZone(center: anchor, radius: 500, intensity: 0.9),
      DemandZone(
        center: LatLng(anchor.latitude + 0.008, anchor.longitude + 0.006),
        radius: 420,
        intensity: 0.75,
      ),
      DemandZone(
        center: LatLng(anchor.latitude + 0.018, anchor.longitude - 0.010),
        radius: 360,
        intensity: 0.55,
      ),
      DemandZone(
        center: LatLng(anchor.latitude - 0.012, anchor.longitude + 0.014),
        radius: 300,
        intensity: 0.45,
      ),
    ];
  }

  static LatLng _positionOnRoute(TransitRoute route, double progress) {
    if (route.pathPoints.isEmpty) return route.stops.first.position;
    final idx = (progress * (route.pathPoints.length - 1)).floor();
    final t = (progress * (route.pathPoints.length - 1)) - idx;
    if (idx >= route.pathPoints.length - 1) return route.pathPoints.last;
    return route.pathPoints[idx].interpolate(route.pathPoints[idx + 1], t);
  }

  static List<LatLng> _generatePathPoints(List<BusStop> stops) {
    if (stops.length < 2) return stops.map((s) => s.position).toList();
    final points = <LatLng>[];
    for (var i = 0; i < stops.length - 1; i++) {
      final from = stops[i].position;
      final to = stops[i + 1].position;
      for (var t = 0.0; t < 1.0; t += 0.1) {
        points.add(from.interpolate(to, t));
      }
    }
    points.add(stops.last.position);
    return points;
  }

  static double _headingOnRoute(TransitRoute route, double progress) {
    if (route.pathPoints.length < 2) return 0;
    final scaledIndex = progress * (route.pathPoints.length - 1);
    final index = scaledIndex.floor().clamp(0, route.pathPoints.length - 2);
    final from = route.pathPoints[index];
    final to = route.pathPoints[index + 1];
    final deltaLat = to.latitude - from.latitude;
    final deltaLng = to.longitude - from.longitude;
    return atan2(deltaLng, deltaLat) * 180 / pi;
  }

  static String _demoSuggestedAction({
    required TransitRoute route,
    required double progress,
    required OccupancyLevel occupancy,
    required int estimatedDelay,
  }) {
    final nextStopIndex =
        ((progress * route.stops.length).floor() + 1).clamp(0, route.stops.length - 1);
    final nextStop = route.stops[nextStopIndex].name;
    if (estimatedDelay >= 4) {
      return 'Crowd building near $nextStop. Allow a few extra minutes.';
    }
    if (occupancy == OccupancyLevel.low) {
      return 'Low crowd service. Best option for a comfortable ride.';
    }
    if (progress >= 0.75) {
      return 'Approaching final sector via $nextStop.';
    }
    return 'Serving $nextStop next on ${route.shortName}.';
  }

  static List<DemandZone> demandZones = [
    DemandZone(
      center: LatLng(_centerLat, _centerLng),
      radius: 500,
      intensity: 0.9,
    ),
    DemandZone(
      center: LatLng(_centerLat + 0.01, _centerLng + 0.007),
      radius: 400,
      intensity: 0.7,
    ),
    DemandZone(
      center: LatLng(_centerLat + 0.025, _centerLng + 0.018),
      radius: 350,
      intensity: 0.5,
    ),
    DemandZone(
      center: LatLng(_centerLat + 0.035, _centerLng + 0.015),
      radius: 600,
      intensity: 0.8,
    ),
    DemandZone(
      center: LatLng(_centerLat + 0.02, _centerLng - 0.01),
      radius: 450,
      intensity: 0.6,
    ),
    DemandZone(
      center: LatLng(_centerLat + 0.05, _centerLng + 0.03),
      radius: 700,
      intensity: 0.95,
    ),
    DemandZone(
      center: LatLng(_centerLat - 0.01, _centerLng + 0.01),
      radius: 300,
      intensity: 0.3,
    ),
  ];

  static List<TransitAlert> sampleAlerts = [
    TransitAlert(
      id: 'alert_1',
      title: 'Route G1 Delayed',
      message:
          'Grand Avenue Express is running 8 min behind schedule due to heavy traffic at Main Hub.',
      type: AlertType.delay,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      routeId: 'route_1',
    ),
    TransitAlert(
      id: 'alert_2',
      title: 'A3 Route Change',
      message:
          'Airport Link temporarily rerouted via Highway Junction bypass. Expected to resume normal route by 6:00 PM.',
      type: AlertType.routeChange,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      routeId: 'route_3',
    ),
    TransitAlert(
      id: 'alert_3',
      title: 'New Express Service',
      message:
          'Tech Park Shuttle now runs every 10 minutes during peak hours (8–10 AM, 5–7 PM).',
      type: AlertType.serviceUpdate,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      routeId: 'route_2',
    ),
    TransitAlert(
      id: 'alert_4',
      title: 'CBD Route Optimized',
      message:
          'Central Business District route has been optimized. 3 minutes faster on average.',
      type: AlertType.serviceUpdate,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      routeId: 'route_5',
    ),
  ];

  static List<FavoriteRoute> sampleFavorites = [
    const FavoriteRoute(
      id: 'fav_1',
      name: 'Evening Commute',
      fromStop: 'West Terminal',
      toStop: 'East Terminal',
      routeShortName: 'G1',
      colorIndex: 0,
    ),
    const FavoriteRoute(
      id: 'fav_2',
      name: 'Office Shuttle',
      fromStop: 'Tech Hub Central',
      toStop: 'Cloud Campus',
      routeShortName: 'T2',
      colorIndex: 1,
    ),
    const FavoriteRoute(
      id: 'fav_3',
      name: 'Airport Run',
      fromStop: 'City Center',
      toStop: 'Terminal 1',
      routeShortName: 'A3',
      colorIndex: 2,
    ),
  ];
}

class _RouteTemplate {
  final String id;
  final String name;
  final String shortName;
  final int colorIndex;
  final List<String> stopNames;
  final List<(double, double)> stopOffsets;

  const _RouteTemplate({
    required this.id,
    required this.name,
    required this.shortName,
    required this.colorIndex,
    required this.stopNames,
    required this.stopOffsets,
  });
}
