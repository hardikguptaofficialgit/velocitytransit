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
    const d = Distance();
    return d.as(LengthUnit.Meter, this, other).toDouble();
  }
}


enum OccupancyLevel { low, medium, high }

/// A single bus stop
class BusStop {
  final String id;
  final String name;
  final LatLng position;
  final bool isActive;

  const BusStop({
    required this.id,
    required this.name,
    required this.position,
    this.isActive = true,
  });
}

/// A transit route
class TransitRoute {
  final String id;
  final String name;
  final String shortName;
  final int colorIndex;
  final List<BusStop> stops;
  final List<LatLng> pathPoints;

  const TransitRoute({
    required this.id,
    required this.name,
    required this.shortName,
    required this.colorIndex,
    required this.stops,
    required this.pathPoints,
  });

  double get totalDistance {
    double total = 0;
    for (var i = 0; i < pathPoints.length - 1; i++) {
      total += pathPoints[i].distanceTo(pathPoints[i + 1]);
    }
    return total;
  }
}

/// A bus vehicle
class Bus {
  final String id;
  final String number;
  final String routeId;
  final LatLng position;
  final double heading;
  final double speed; // km/h
  final OccupancyLevel occupancy;
  final int currentStopIndex;
  final double progress; // 0.0 to 1.0 along route
  final bool isActive;
  final int estimatedDelay; // minutes
  final String? suggestedAction; // AI suggested intervention

  const Bus({
    required this.id,
    required this.number,
    required this.routeId,
    required this.position,
    this.heading = 0,
    this.speed = 30,
    this.occupancy = OccupancyLevel.low,
    this.currentStopIndex = 0,
    this.progress = 0,
    this.isActive = true,
    this.estimatedDelay = 0,
    this.suggestedAction,
  });

  Bus copyWith({
    LatLng? position,
    double? heading,
    double? speed,
    OccupancyLevel? occupancy,
    int? currentStopIndex,
    double? progress,
    bool? isActive,
    int? estimatedDelay,
    String? suggestedAction,
  }) {
    return Bus(
      id: id,
      number: number,
      routeId: routeId,
      position: position ?? this.position,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      occupancy: occupancy ?? this.occupancy,
      currentStopIndex: currentStopIndex ?? this.currentStopIndex,
      progress: progress ?? this.progress,
      isActive: isActive ?? this.isActive,
      estimatedDelay: estimatedDelay ?? this.estimatedDelay,
      suggestedAction: suggestedAction ?? this.suggestedAction,
    );
  }
}

/// Route suggestion for planner
class RouteSuggestion {
  final TransitRoute route;
  final int etaMinutes;
  final int stopsCount;
  final int transfers;
  final String walkDistance;
  final bool isFastest;

  const RouteSuggestion({
    required this.route,
    required this.etaMinutes,
    required this.stopsCount,
    this.transfers = 0,
    this.walkDistance = '200m',
    this.isFastest = false,
  });
}

/// Alert notification
class TransitAlert {
  final String id;
  final String title;
  final String message;
  final AlertType type;
  final DateTime timestamp;
  final String? routeId;
  final bool isRead;

  const TransitAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.routeId,
    this.isRead = false,
  });
}

enum AlertType { delay, routeChange, serviceUpdate, emergency }

/// Favorite route
class FavoriteRoute {
  final String id;
  final String name;
  final String fromStop;
  final String toStop;
  final String routeShortName;
  final int colorIndex;

  const FavoriteRoute({
    required this.id,
    required this.name,
    required this.fromStop,
    required this.toStop,
    required this.routeShortName,
    required this.colorIndex,
  });
}

/// Demand data for heatmap
class DemandZone {
  final LatLng center;
  final double radius;
  final double intensity; // 0..1

  const DemandZone({
    required this.center,
    required this.radius,
    required this.intensity,
  });
}
