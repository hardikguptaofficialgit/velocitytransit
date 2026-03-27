import 'dart:math';
import '../data/models.dart';

/// Predefined simulation data for offline demo mode
class SimulationData {
  SimulationData._();

  // ── City center: simulated coordinates (Bhubaneswar-inspired) ──
  static const _centerLat = 20.2961;
  static const _centerLng = 85.8245;

  static final List<TransitRoute> routes = [
    TransitRoute(
      id: 'route_1',
      name: 'Marine Drive Express',
      shortName: 'M1',
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
    BusStop(id: 's1_1', name: 'Marine Drive', position: LatLng(_centerLat, _centerLng)),
    BusStop(id: 's1_2', name: 'Churchgate', position: LatLng(_centerLat + 0.005, _centerLng + 0.003)),
    BusStop(id: 's1_3', name: 'Flora Fountain', position: LatLng(_centerLat + 0.01, _centerLng + 0.007)),
    BusStop(id: 's1_4', name: 'CST Junction', position: LatLng(_centerLat + 0.014, _centerLng + 0.012)),
    BusStop(id: 's1_5', name: 'Masjid Bunder', position: LatLng(_centerLat + 0.018, _centerLng + 0.016)),
    BusStop(id: 's1_6', name: 'Byculla', position: LatLng(_centerLat + 0.025, _centerLng + 0.018)),
    BusStop(id: 's1_7', name: 'Dadar Terminal', position: LatLng(_centerLat + 0.035, _centerLng + 0.015)),
  ];

  static final List<BusStop> _route2Stops = [
    BusStop(id: 's2_1', name: 'Tech Hub Central', position: LatLng(_centerLat + 0.02, _centerLng - 0.01)),
    BusStop(id: 's2_2', name: 'Innovation Park', position: LatLng(_centerLat + 0.025, _centerLng - 0.005)),
    BusStop(id: 's2_3', name: 'Startup Alley', position: LatLng(_centerLat + 0.03, _centerLng)),
    BusStop(id: 's2_4', name: 'Data Center', position: LatLng(_centerLat + 0.032, _centerLng + 0.008)),
    BusStop(id: 's2_5', name: 'Cloud Campus', position: LatLng(_centerLat + 0.028, _centerLng + 0.015)),
    BusStop(id: 's2_6', name: 'Tech Park East', position: LatLng(_centerLat + 0.022, _centerLng + 0.022)),
  ];

  static final List<BusStop> _route3Stops = [
    BusStop(id: 's3_1', name: 'Terminal 1', position: LatLng(_centerLat + 0.05, _centerLng + 0.03)),
    BusStop(id: 's3_2', name: 'Cargo Area', position: LatLng(_centerLat + 0.042, _centerLng + 0.025)),
    BusStop(id: 's3_3', name: 'Airport Metro', position: LatLng(_centerLat + 0.035, _centerLng + 0.02)),
    BusStop(id: 's3_4', name: 'Highway Junction', position: LatLng(_centerLat + 0.025, _centerLng + 0.015)),
    BusStop(id: 's3_5', name: 'City Center', position: LatLng(_centerLat + 0.01, _centerLng + 0.005)),
    BusStop(id: 's3_6', name: 'South Terminal', position: LatLng(_centerLat - 0.005, _centerLng)),
  ];

  static final List<BusStop> _route4Stops = [
    BusStop(id: 's4_1', name: 'University Gate', position: LatLng(_centerLat - 0.01, _centerLng + 0.01)),
    BusStop(id: 's4_2', name: 'Library Point', position: LatLng(_centerLat - 0.005, _centerLng + 0.015)),
    BusStop(id: 's4_3', name: 'Sports Complex', position: LatLng(_centerLat, _centerLng + 0.02)),
    BusStop(id: 's4_4', name: 'Hostel Area', position: LatLng(_centerLat + 0.005, _centerLng + 0.015)),
    BusStop(id: 's4_5', name: 'Research Block', position: LatLng(_centerLat + 0.005, _centerLng + 0.01)),
    BusStop(id: 's4_6', name: 'Main Gate', position: LatLng(_centerLat - 0.01, _centerLng + 0.01)),
  ];

  static final List<BusStop> _route5Stops = [
    BusStop(id: 's5_1', name: 'CBD North', position: LatLng(_centerLat + 0.008, _centerLng - 0.005)),
    BusStop(id: 's5_2', name: 'Financial Tower', position: LatLng(_centerLat + 0.012, _centerLng)),
    BusStop(id: 's5_3', name: 'Stock Exchange', position: LatLng(_centerLat + 0.015, _centerLng + 0.005)),
    BusStop(id: 's5_4', name: 'Trade Center', position: LatLng(_centerLat + 0.012, _centerLng + 0.012)),
    BusStop(id: 's5_5', name: 'Business Bay', position: LatLng(_centerLat + 0.008, _centerLng + 0.018)),
    BusStop(id: 's5_6', name: 'CBD South', position: LatLng(_centerLat + 0.003, _centerLng + 0.015)),
  ];

  static List<Bus> initialBuses() {
    final rng = Random(42);
    final occupancies = OccupancyLevel.values;
    final buses = <Bus>[];

    for (var route in routes) {
      final busCount = 2 + rng.nextInt(2);
      for (var i = 0; i < busCount; i++) {
        final progress = i / busCount;
        final pos = _positionOnRoute(route, progress);
        buses.add(Bus(
          id: '${route.id}_bus_$i',
          number: '${route.shortName}-${100 + i}',
          routeId: route.id,
          position: pos,
          speed: 20 + rng.nextDouble() * 25,
          occupancy: occupancies[rng.nextInt(3)],
          currentStopIndex: (progress * route.stops.length).floor(),
          progress: progress,
        ));
      }
    }
    return buses;
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

  static List<DemandZone> demandZones = [
    DemandZone(center: LatLng(_centerLat, _centerLng), radius: 500, intensity: 0.9),
    DemandZone(center: LatLng(_centerLat + 0.01, _centerLng + 0.007), radius: 400, intensity: 0.7),
    DemandZone(center: LatLng(_centerLat + 0.025, _centerLng + 0.018), radius: 350, intensity: 0.5),
    DemandZone(center: LatLng(_centerLat + 0.035, _centerLng + 0.015), radius: 600, intensity: 0.8),
    DemandZone(center: LatLng(_centerLat + 0.02, _centerLng - 0.01), radius: 450, intensity: 0.6),
    DemandZone(center: LatLng(_centerLat + 0.05, _centerLng + 0.03), radius: 700, intensity: 0.95),
    DemandZone(center: LatLng(_centerLat - 0.01, _centerLng + 0.01), radius: 300, intensity: 0.3),
  ];

  static List<TransitAlert> sampleAlerts = [
    TransitAlert(
      id: 'alert_1',
      title: 'Route M1 Delayed',
      message: 'Marine Drive Express is running 8 min behind schedule due to heavy traffic near Churchgate.',
      type: AlertType.delay,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      routeId: 'route_1',
    ),
    TransitAlert(
      id: 'alert_2',
      title: 'A3 Route Change',
      message: 'Airport Link temporarily rerouted via Highway Junction bypass. Expected to resume normal route by 6:00 PM.',
      type: AlertType.routeChange,
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      routeId: 'route_3',
    ),
    TransitAlert(
      id: 'alert_3',
      title: 'New Express Service',
      message: 'Tech Park Shuttle now runs every 10 minutes during peak hours (8–10 AM, 5–7 PM).',
      type: AlertType.serviceUpdate,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      routeId: 'route_2',
    ),
    TransitAlert(
      id: 'alert_4',
      title: 'CBD Route Optimized',
      message: 'Central Business District route has been optimized. 3 minutes faster on average.',
      type: AlertType.serviceUpdate,
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      routeId: 'route_5',
    ),
  ];

  static List<FavoriteRoute> sampleFavorites = [
    const FavoriteRoute(
      id: 'fav_1',
      name: 'Morning Commute',
      fromStop: 'Marine Drive',
      toStop: 'Dadar Terminal',
      routeShortName: 'M1',
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
