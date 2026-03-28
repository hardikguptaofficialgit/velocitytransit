import 'package:latlong2/latlong.dart';

export 'package:latlong2/latlong.dart' hide Path;

extension LatLngExtension on LatLng {
  LatLng interpolate(LatLng other, double t) {
    return LatLng(
      latitude + (other.latitude - latitude) * t,
      longitude + (other.longitude - longitude) * t,
    );
  }

  double distanceTo(LatLng other) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, this, other).toDouble();
  }
}

enum OccupancyLevel { low, medium, high }

enum AlertType { delay, routeChange, serviceUpdate, emergency, tripStarted, upcomingStop, tripCompleted }

enum AppRoleChoice { passenger, driver }

class BusStop {
  const BusStop({
    required this.id,
    required this.name,
    required this.position,
    this.isActive = true,
    this.etaMinutes,
  });

  final String id;
  final String name;
  final LatLng position;
  final bool isActive;
  final int? etaMinutes;

  factory BusStop.fromMap(Map<String, dynamic> map) {
    final lat = (map['lat'] ?? map['latitude'] ?? 0).toDouble();
    final lng = (map['lng'] ?? map['longitude'] ?? 0).toDouble();
    return BusStop(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      position: LatLng(lat, lng),
      isActive: map['isActive'] != false,
      etaMinutes: (map['etaMinutes'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lat': position.latitude,
      'lng': position.longitude,
      'isActive': isActive,
      if (etaMinutes != null) 'etaMinutes': etaMinutes,
    };
  }
}

class TransitRoute {
  const TransitRoute({
    required this.id,
    required this.name,
    required this.shortName,
    required this.colorIndex,
    required this.stops,
    required this.pathPoints,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String shortName;
  final int colorIndex;
  final List<BusStop> stops;
  final List<LatLng> pathPoints;
  final bool isActive;

  double get totalDistance {
    if (pathPoints.length < 2) return 0;
    double total = 0;
    for (var i = 0; i < pathPoints.length - 1; i++) {
      total += pathPoints[i].distanceTo(pathPoints[i + 1]);
    }
    return total;
  }

  factory TransitRoute.fromMap(String id, Map<String, dynamic> map) {
    final stops = (map['stops'] as List<dynamic>? ?? const [])
        .map((stop) => BusStop.fromMap(Map<String, dynamic>.from(stop)))
        .toList();
    final pathPoints = (map['pathPoints'] as List<dynamic>? ?? const [])
        .map((point) => LatLng(
              (point['lat'] ?? point['latitude'] ?? 0).toDouble(),
              (point['lng'] ?? point['longitude'] ?? 0).toDouble(),
            ))
        .toList();

    return TransitRoute(
      id: id,
      name: map['name']?.toString() ?? '',
      shortName: map['shortName']?.toString() ?? '',
      colorIndex: (map['colorIndex'] as num?)?.toInt() ?? 0,
      stops: stops,
      pathPoints: pathPoints,
      isActive: map['isActive'] != false,
    );
  }
}

class BusAssignment {
  const BusAssignment({
    required this.id,
    required this.busId,
    required this.driverId,
    required this.busNumber,
    required this.driverName,
    required this.isActive,
    this.routeId,
    this.startedAt,
    this.endedAt,
  });

  final String id;
  final String busId;
  final String driverId;
  final String busNumber;
  final String driverName;
  final String? routeId;
  final bool isActive;
  final DateTime? startedAt;
  final DateTime? endedAt;

  factory BusAssignment.fromMap(String id, Map<String, dynamic> map) {
    return BusAssignment(
      id: id,
      busId: map['busId']?.toString() ?? '',
      driverId: map['driverId']?.toString() ?? '',
      busNumber: map['busNumber']?.toString() ?? '',
      driverName: map['driverName']?.toString() ?? '',
      routeId: map['routeId']?.toString(),
      isActive: map['isActive'] == true,
      startedAt: _tryParseDateTime(map['startedAt']),
      endedAt: _tryParseDateTime(map['endedAt']),
    );
  }
}

class Bus {
  const Bus({
    required this.id,
    required this.number,
    required this.routeId,
    required this.position,
    this.routeName,
    this.routeShortName,
    this.driverId,
    this.driverName,
    this.heading = 0,
    this.speed = 30,
    this.capacity = 40,
    this.occupancy = OccupancyLevel.low,
    this.currentStopIndex = 0,
    this.progress = 0,
    this.isActive = true,
    this.isOnline = false,
    this.isDemo = false,
    this.estimatedDelay = 0,
    this.status = 'active',
    this.suggestedAction,
    this.lastUpdated,
  });

  final String id;
  final String number;
  final String routeId;
  final String? routeName;
  final String? routeShortName;
  final String? driverId;
  final String? driverName;
  final LatLng position;
  final double heading;
  final double speed;
  final int capacity;
  final OccupancyLevel occupancy;
  final int currentStopIndex;
  final double progress;
  final bool isActive;
  final bool isOnline;
  final bool isDemo;
  final int estimatedDelay;
  final String status;
  final String? suggestedAction;
  final DateTime? lastUpdated;

  factory Bus.fromBackend({
    required String id,
    required Map<String, dynamic> busData,
    TransitRoute? route,
    BusAssignment? assignment,
    LiveBusSnapshot? liveSnapshot,
    bool isDemo = false,
  }) {
    final position = liveSnapshot?.position ?? route?.stops.first.position ?? const LatLng(0, 0);
    final progress = route == null ? 0.0 : _estimateProgress(position, route);
    final currentStopIndex = route == null ? 0 : _estimateCurrentStopIndex(position, route);
    return Bus(
      id: id,
      number: busData['busNumber']?.toString() ?? assignment?.busNumber ?? id,
      routeId: (busData['routeId'] ?? assignment?.routeId)?.toString() ?? '',
      routeName: route?.name,
      routeShortName: route?.shortName,
      driverId: assignment?.driverId ?? liveSnapshot?.driverId,
      driverName: assignment?.driverName,
      position: position,
      heading: liveSnapshot?.heading ?? 0,
      speed: liveSnapshot?.speed ?? 0,
      capacity: (busData['capacity'] as num?)?.toInt() ?? 40,
      occupancy: _occupancyFromDelay(liveSnapshot?.speed ?? 0),
      currentStopIndex: currentStopIndex,
      progress: progress,
      isActive: busData['status']?.toString() != 'inactive',
      isOnline: liveSnapshot?.isOnline == true,
      isDemo: isDemo,
      estimatedDelay: _estimateDelay(liveSnapshot?.speed ?? 0),
      status: busData['status']?.toString() ?? 'active',
      suggestedAction: liveSnapshot == null ? null : _suggestAction(liveSnapshot.speed),
      lastUpdated: liveSnapshot?.lastUpdated,
    );
  }

  Bus copyWith({
    LatLng? position,
    double? heading,
    double? speed,
    int? capacity,
    OccupancyLevel? occupancy,
    int? currentStopIndex,
    double? progress,
    bool? isActive,
    bool? isOnline,
    bool? isDemo,
    int? estimatedDelay,
    String? status,
    String? suggestedAction,
    String? routeName,
    String? routeShortName,
    String? driverId,
    String? driverName,
    DateTime? lastUpdated,
  }) {
    return Bus(
      id: id,
      number: number,
      routeId: routeId,
      position: position ?? this.position,
      routeName: routeName ?? this.routeName,
      routeShortName: routeShortName ?? this.routeShortName,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      capacity: capacity ?? this.capacity,
      occupancy: occupancy ?? this.occupancy,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      progress: progress ?? this.progress,
      isActive: isActive ?? this.isActive,
      isOnline: isOnline ?? this.isOnline,
      isDemo: isDemo ?? this.isDemo,
      estimatedDelay: estimatedDelay ?? this.estimatedDelay,
      status: status ?? this.status,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class LiveBusSnapshot {
  const LiveBusSnapshot({
    required this.busId,
    required this.busNumber,
    required this.position,
    required this.speed,
    required this.heading,
    required this.isOnline,
    required this.lastUpdated,
    this.routeId,
    this.driverId,
  });

  final String busId;
  final String busNumber;
  final String? routeId;
  final String? driverId;
  final LatLng position;
  final double speed;
  final double heading;
  final bool isOnline;
  final DateTime? lastUpdated;

  factory LiveBusSnapshot.fromMap(Map<String, dynamic> map) {
    return LiveBusSnapshot(
      busId: map['busId']?.toString() ?? '',
      busNumber: map['busNumber']?.toString() ?? '',
      routeId: map['routeId']?.toString(),
      driverId: map['driverId']?.toString(),
      position: LatLng(
        (map['lat'] ?? 0).toDouble(),
        (map['lng'] ?? 0).toDouble(),
      ),
      speed: (map['speed'] ?? 0).toDouble(),
      heading: (map['heading'] ?? 0).toDouble(),
      isOnline: map['isOnline'] == true,
      lastUpdated: _tryParseDateTime(map['lastUpdated']),
    );
  }
}

class RouteSuggestion {
  const RouteSuggestion({
    required this.route,
    required this.etaMinutes,
    required this.stopsCount,
    this.transfers = 0,
    this.walkDistance = '200m',
    this.isFastest = false,
  });

  final TransitRoute route;
  final int etaMinutes;
  final int stopsCount;
  final int transfers;
  final String walkDistance;
  final bool isFastest;
}

class TransitAlert {
  const TransitAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.routeId,
    this.busId,
    this.etaMinutes,
    this.nextStop,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final AlertType type;
  final DateTime timestamp;
  final String? routeId;
  final String? busId;
  final int? etaMinutes;
  final String? nextStop;
  final bool isRead;

  factory TransitAlert.fromMap(String id, Map<String, dynamic> map) {
    return TransitAlert(
      id: id,
      title: map['title']?.toString() ?? '',
      message: map['body']?.toString() ?? map['message']?.toString() ?? '',
      type: _alertTypeFromString(map['type']?.toString()),
      timestamp: _tryParseDateTime(map['timestamp']) ?? DateTime.now(),
      routeId: map['routeId']?.toString(),
      busId: map['busId']?.toString(),
      etaMinutes: (map['etaMinutes'] as num?)?.toInt(),
      nextStop: map['nextStop']?.toString(),
      isRead: map['isRead'] == true,
    );
  }

  TransitAlert copyWith({bool? isRead}) {
    return TransitAlert(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      routeId: routeId,
      busId: busId,
      etaMinutes: etaMinutes,
      nextStop: nextStop,
      isRead: isRead ?? this.isRead,
    );
  }
}

class FavoriteRoute {
  const FavoriteRoute({
    required this.id,
    required this.name,
    required this.fromStop,
    required this.toStop,
    required this.routeShortName,
    required this.colorIndex,
  });

  final String id;
  final String name;
  final String fromStop;
  final String toStop;
  final String routeShortName;
  final int colorIndex;
}

class DemandZone {
  const DemandZone({
    required this.center,
    required this.radius,
    required this.intensity,
  });

  final LatLng center;
  final double radius;
  final double intensity;
}

class TransitProfileStats {
  const TransitProfileStats({
    this.totalTrips = 0,
    this.totalDistanceKm = 0,
    this.activeAlerts = 0,
  });

  final int totalTrips;
  final double totalDistanceKm;
  final int activeAlerts;
}

AlertType _alertTypeFromString(String? value) {
  switch (value) {
    case 'delay':
      return AlertType.delay;
    case 'route_change':
    case 'routeChange':
      return AlertType.routeChange;
    case 'trip_started':
      return AlertType.tripStarted;
    case 'upcoming_stop':
      return AlertType.upcomingStop;
    case 'trip_completed':
      return AlertType.tripCompleted;
    case 'emergency':
      return AlertType.emergency;
    case 'service_update':
    case 'serviceUpdate':
    default:
      return AlertType.serviceUpdate;
  }
}

DateTime? _tryParseDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}

double _estimateProgress(LatLng position, TransitRoute route) {
  if (route.pathPoints.isEmpty) return 0;
  var bestIndex = 0;
  var bestDistance = double.infinity;
  for (var i = 0; i < route.pathPoints.length; i++) {
    final distance = position.distanceTo(route.pathPoints[i]);
    if (distance < bestDistance) {
      bestDistance = distance;
      bestIndex = i;
    }
  }
  if (route.pathPoints.length == 1) return 0;
  return bestIndex / (route.pathPoints.length - 1);
}

int _estimateCurrentStopIndex(LatLng position, TransitRoute route) {
  if (route.stops.isEmpty) return 0;
  var bestIndex = 0;
  var bestDistance = double.infinity;
  for (var i = 0; i < route.stops.length; i++) {
    final distance = position.distanceTo(route.stops[i].position);
    if (distance < bestDistance) {
      bestDistance = distance;
      bestIndex = i;
    }
  }
  return bestIndex;
}

OccupancyLevel _occupancyFromDelay(double speed) {
  if (speed < 12) return OccupancyLevel.high;
  if (speed < 24) return OccupancyLevel.medium;
  return OccupancyLevel.low;
}

int _estimateDelay(double speed) {
  if (speed <= 0) return 6;
  if (speed < 12) return 5;
  if (speed < 20) return 3;
  if (speed < 28) return 1;
  return 0;
}

String? _suggestAction(double speed) {
  if (speed < 10) {
    return 'Heavy congestion detected. Expect delay updates.';
  }
  if (speed < 18) {
    return 'Bus is moving slower than expected.';
  }
  return null;
}
