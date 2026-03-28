import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models.dart';
import '../data/simulation_data.dart';
import '../services/backend_api_service.dart';
import '../services/road_routing_service.dart';
import 'auth_provider.dart';
import 'tracking_provider.dart';

class TransitState {
  static const Object _unset = Object();

  const TransitState({
    this.buses = const [],
    this.routes = const [],
    this.alerts = const [],
    this.favorites = const [],
    this.isSimulationRunning = false,
    this.showHeatmap = false,
    this.isLoadingNetwork = false,
    this.isRefreshingRemote = false,
    this.passengerAnchor = SimulationData.defaultAnchor,
    this.demandZones = const [],
    this.activeAssignment,
    this.lastError,
  });

  final List<Bus> buses;
  final List<TransitRoute> routes;
  final List<TransitAlert> alerts;
  final List<FavoriteRoute> favorites;
  final bool isSimulationRunning;
  final bool showHeatmap;
  final bool isLoadingNetwork;
  final bool isRefreshingRemote;
  final LatLng passengerAnchor;
  final List<DemandZone> demandZones;
  final BusAssignment? activeAssignment;
  final String? lastError;

  TransitState copyWith({
    List<Bus>? buses,
    List<TransitRoute>? routes,
    List<TransitAlert>? alerts,
    List<FavoriteRoute>? favorites,
    bool? isSimulationRunning,
    bool? showHeatmap,
    bool? isLoadingNetwork,
    bool? isRefreshingRemote,
    LatLng? passengerAnchor,
    List<DemandZone>? demandZones,
    Object? activeAssignment = _unset,
    Object? lastError = _unset,
  }) {
    return TransitState(
      buses: buses ?? this.buses,
      routes: routes ?? this.routes,
      alerts: alerts ?? this.alerts,
      favorites: favorites ?? this.favorites,
      isSimulationRunning: isSimulationRunning ?? this.isSimulationRunning,
      showHeatmap: showHeatmap ?? this.showHeatmap,
      isLoadingNetwork: isLoadingNetwork ?? this.isLoadingNetwork,
      isRefreshingRemote: isRefreshingRemote ?? this.isRefreshingRemote,
      passengerAnchor: passengerAnchor ?? this.passengerAnchor,
      demandZones: demandZones ?? this.demandZones,
      activeAssignment: identical(activeAssignment, _unset)
          ? this.activeAssignment
          : activeAssignment as BusAssignment?,
      lastError: identical(lastError, _unset)
          ? this.lastError
          : lastError as String?,
    );
  }
}

class TransitNotifier extends Notifier<TransitState> {
  final RoadRoutingService _routingService = const RoadRoutingService();
  Timer? _refreshTimer;
  LatLng? _lastNetworkAnchor;
  bool _isRefreshingNetwork = false;

  BackendApiService get _api => BackendApiService(
        authService: ref.read(authServiceProvider),
      );

  @override
  TransitState build() {
    ref.onDispose(() {
      _refreshTimer?.cancel();
    });

    ref.listen<AsyncValue<Object?>>(authStateProvider, (_, next) {
      next.whenData((user) {
        if (user == null) {
          _refreshTimer?.cancel();
          state = const TransitState(
            passengerAnchor: SimulationData.defaultAnchor,
            demandZones: [],
          );
          return;
        }
        unawaited(refreshRemoteData());
        _startAutoRefresh();
      });
    });

    ref.listen<TrackingState>(trackingProvider, (_, next) {
      _syncLivePositions(next.livePositions);
    });

    final initialRoutes = SimulationData.routes;
    return TransitState(
      buses: _buildDemoBuses(initialRoutes),
      routes: initialRoutes,
      alerts: SimulationData.sampleAlerts,
      favorites: SimulationData.sampleFavorites,
      isSimulationRunning: true,
      passengerAnchor: SimulationData.defaultAnchor,
      demandZones: SimulationData.demandZonesForAnchor(SimulationData.defaultAnchor),
    );
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(refreshRemoteData(silent: true));
    });
  }

  Future<void> refreshRemoteData({bool silent = false}) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    if (!silent) {
      state = state.copyWith(isRefreshingRemote: true, lastError: null);
    }

    try {
      final results = await Future.wait([
        _api.fetchRoutes(),
        _api.fetchBusesRaw(),
        _api.fetchActiveAssignments(),
        _api.fetchLivePositions(),
        _api.fetchAlerts(),
        _api.fetchMyAssignment().catchError((_) => null),
      ]);

      final routes = results[0] as List<TransitRoute>;
      final rawBuses = results[1] as Map<String, Map<String, dynamic>>;
      final assignments = results[2] as List<BusAssignment>;
      final livePositions = results[3] as List<LiveBusSnapshot>;
      final alerts = results[4] as List<TransitAlert>;
      final myAssignment = results[5] as BusAssignment?;

      final mergedBuses = _mergeTransitData(
        routes: routes,
        rawBuses: rawBuses,
        assignments: assignments,
        livePositions: livePositions,
      );

      state = state.copyWith(
        routes: routes,
        buses: mergedBuses,
        alerts: alerts,
        activeAssignment: myAssignment,
        isRefreshingRemote: false,
        isSimulationRunning: mergedBuses.any((bus) => bus.isDemo),
        lastError: null,
      );
    } catch (error) {
      final fallbackRoutes = state.routes.isNotEmpty ? state.routes : SimulationData.routes;
      final fallbackBuses = _buildDemoBuses(fallbackRoutes);
      state = state.copyWith(
        routes: fallbackRoutes,
        buses: fallbackBuses,
        alerts: state.alerts,
        isRefreshingRemote: false,
        isSimulationRunning: true,
        lastError: error.toString(),
      );
    }
  }

  List<Bus> _mergeTransitData({
    required List<TransitRoute> routes,
    required Map<String, Map<String, dynamic>> rawBuses,
    required List<BusAssignment> assignments,
    required List<LiveBusSnapshot> livePositions,
  }) {
    final routeById = {for (final route in routes) route.id: route};
    final assignmentByBusId = {for (final assignment in assignments) assignment.busId: assignment};
    final liveByBusId = {for (final snapshot in livePositions) snapshot.busId: snapshot};
    final allBusIds = <String>{
      ...rawBuses.keys.where((id) => id.isNotEmpty),
      ...assignmentByBusId.keys.where((id) => id.isNotEmpty),
      ...liveByBusId.keys.where((id) => id.isNotEmpty),
    };

    final buses = <Bus>[];
    for (final busId in allBusIds) {
      final busData = rawBuses[busId] ?? const <String, dynamic>{};
      final assignment = assignmentByBusId[busId];
      final liveSnapshot = liveByBusId[busId];
      final routeId =
          (busData['routeId'] ?? assignment?.routeId ?? liveSnapshot?.routeId)
              ?.toString() ??
          '';

      buses.add(
        Bus.fromBackend(
          id: busId,
          busData: busData,
          route: routeById[routeId],
          assignment: assignment,
          liveSnapshot: liveSnapshot,
        ),
      );
    }

    if (buses.isEmpty) {
      return _buildDemoBuses(routes);
    }

    final activeRouteIds = buses.map((bus) => bus.routeId).where((id) => id.isNotEmpty).toSet();
    final missingRoutes = routes.where((route) => !activeRouteIds.contains(route.id)).toList();
    return [...buses, ..._buildDemoBuses(missingRoutes)];
  }

  List<Bus> _buildDemoBuses(List<TransitRoute> routes) {
    final demos = SimulationData.initialBusesForRoutes(routes);
    return demos
        .map(
          (bus) => bus.copyWith(
            isDemo: true,
            routeName: routes.firstWhere((route) => route.id == bus.routeId).name,
            routeShortName: routes.firstWhere((route) => route.id == bus.routeId).shortName,
            suggestedAction: bus.suggestedAction ?? 'Demo bus shown until a live trip starts.',
          ),
        )
        .toList();
  }

  void _syncLivePositions(List<LiveBusPosition> positions) {
    if (state.buses.isEmpty || positions.isEmpty) return;
    final positionByBusId = {for (final position in positions) position.busId: position};
    state = state.copyWith(
      buses: state.buses.map((bus) {
        final live = positionByBusId[bus.id];
        if (live == null) return bus;
        final route = getRoute(bus.routeId);
        final position = LatLng(live.lat, live.lng);
        return bus.copyWith(
          position: position,
          speed: live.speed,
          heading: live.heading,
          isOnline: true,
          currentStopIndex: route == null ? bus.currentStopIndex : _estimateCurrentStopIndex(position, route),
          progress: route == null ? bus.progress : _estimateProgress(position, route),
          estimatedDelay: _estimateDelay(live.speed),
          suggestedAction: live.speed < 10 ? 'Potential delay detected on live service.' : null,
          lastUpdated: DateTime.tryParse(live.lastUpdated),
        );
      }).toList(),
    );
  }

  void toggleHeatmap() {
    state = state.copyWith(showHeatmap: !state.showHeatmap);
  }

  Future<void> ensureNetworkForPassenger(LatLng passengerPosition) async {
    final lastAnchor = _lastNetworkAnchor;
    if (_isRefreshingNetwork) return;
    if (lastAnchor != null && lastAnchor.distanceTo(passengerPosition) < 350) {
      state = state.copyWith(passengerAnchor: passengerPosition);
      return;
    }

    _isRefreshingNetwork = true;
    state = state.copyWith(
      isLoadingNetwork: true,
      passengerAnchor: passengerPosition,
      demandZones: SimulationData.demandZonesForAnchor(passengerPosition),
    );

    try {
      final currentRoutes = state.routes.isNotEmpty ? state.routes : SimulationData.routesNearPassenger(passengerPosition);
      final snappedPaths = <String, List<LatLng>>{};

      for (final route in currentRoutes) {
        try {
          final snappedPath = await _routingService.fetchRoutePath(
            route.stops.map((stop) => stop.position).toList(),
          );
          if (snappedPath.length >= 2) {
            snappedPaths[route.id] = snappedPath;
          }
        } catch (_) {}
      }

      final updatedRoutes = currentRoutes
          .map(
            (route) => TransitRoute(
              id: route.id,
              name: route.name,
              shortName: route.shortName,
              colorIndex: route.colorIndex,
              stops: route.stops,
              pathPoints: snappedPaths[route.id] ?? route.pathPoints,
              isActive: route.isActive,
            ),
          )
          .toList();

      final buses = state.buses.isEmpty ? _buildDemoBuses(updatedRoutes) : state.buses;
      state = state.copyWith(
        routes: updatedRoutes,
        buses: buses,
        passengerAnchor: passengerPosition,
        demandZones: SimulationData.demandZonesForAnchor(passengerPosition),
        isLoadingNetwork: false,
      );
      _lastNetworkAnchor = passengerPosition;
    } finally {
      _isRefreshingNetwork = false;
      state = state.copyWith(isLoadingNetwork: false);
    }
  }

  void addFavorite(FavoriteRoute favorite) {
    state = state.copyWith(favorites: [...state.favorites, favorite]);
  }

  void removeFavorite(String id) {
    state = state.copyWith(
      favorites: state.favorites.where((favorite) => favorite.id != id).toList(),
    );
  }

  void markAlertRead(String id) {
    state = state.copyWith(
      alerts: state.alerts
          .map((alert) => alert.id == id ? alert.copyWith(isRead: true) : alert)
          .toList(),
    );
  }

  Bus? getBus(String busId) {
    try {
      return state.buses.firstWhere((bus) => bus.id == busId);
    } catch (_) {
      return null;
    }
  }

  TransitRoute? getRoute(String routeId) {
    try {
      return state.routes.firstWhere((route) => route.id == routeId);
    } catch (_) {
      return null;
    }
  }

  List<Bus> getBusesOnRoute(String routeId) {
    return state.buses.where((bus) => bus.routeId == routeId).toList();
  }

  List<RouteSuggestion> getSuggestions(String from, String to) {
    final fromQuery = _normalizeQuery(from);
    final toQuery = _normalizeQuery(to);
    final includeAllRoutes = fromQuery.isEmpty && toQuery.isEmpty;
    final suggestions = <_RankedSuggestion>[];

    for (final route in state.routes) {
      final busesOnRoute = getBusesOnRoute(route.id);
      final fromMatch = _findBestStopMatch(route, fromQuery);
      final toMatch = _findBestStopMatch(route, toQuery);
      final routeMatches =
          route.name.toLowerCase().contains(fromQuery) ||
          route.name.toLowerCase().contains(toQuery) ||
          route.shortName.toLowerCase().contains(fromQuery) ||
          route.shortName.toLowerCase().contains(toQuery);

      final hasUsefulMatch =
          includeAllRoutes || routeMatches || fromMatch != null || toMatch != null;
      if (!hasUsefulMatch) {
        continue;
      }

      var score = 0;
      if (routeMatches) score += 35;
      if (fromMatch != null) score += fromMatch.score + 40;
      if (toMatch != null) score += toMatch.score + 40;

      var transfers = 1;
      if (fromMatch != null && toMatch != null) {
        if (fromMatch.index <= toMatch.index) {
          score += 90;
          transfers = 0;
        } else {
          score += 20;
          transfers = 1;
        }
      } else if (fromMatch != null || toMatch != null) {
        score += 15;
      } else if (includeAllRoutes) {
        score += 10;
      }

      score += busesOnRoute.length * 8;
      final avgDelay = busesOnRoute.isEmpty
          ? 2
          : (busesOnRoute.fold<int>(0, (sum, bus) => sum + bus.estimatedDelay) /
                  busesOnRoute.length)
              .round();
      final avgSpeed = busesOnRoute.isEmpty
          ? 22
          : busesOnRoute.fold<double>(0, (sum, bus) => sum + bus.speed) /
              busesOnRoute.length;
      final spanStops = fromMatch != null && toMatch != null
          ? (toMatch.index - fromMatch.index).abs().clamp(2, route.stops.length)
          : route.stops.length.clamp(3, 8);
      final eta =
          (spanStops * 3 + avgDelay + max(0, 28 - avgSpeed.round()) ~/ 6)
              .clamp(6, 38);
      final walkDistance = '${140 + max(0, 5 - busesOnRoute.length) * 55}m';

      suggestions.add(
        _RankedSuggestion(
          score: score,
          suggestion: RouteSuggestion(
            route: route,
            etaMinutes: eta,
            stopsCount: route.stops.length,
            activeBuses: busesOnRoute.length,
            transfers: transfers,
            walkDistance: walkDistance,
            fromStopName: fromMatch?.stop.name,
            toStopName: toMatch?.stop.name,
          ),
        ),
      );
    }

    suggestions.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      final etaCompare = a.suggestion.etaMinutes.compareTo(b.suggestion.etaMinutes);
      if (etaCompare != 0) return etaCompare;
      return b.suggestion.activeBuses.compareTo(a.suggestion.activeBuses);
    });

    final ranked = suggestions.map((entry) => entry.suggestion).take(5).toList();
    if (ranked.isEmpty && state.routes.isNotEmpty) {
      final fallback = state.routes.take(3).map((route) {
        final busesOnRoute = getBusesOnRoute(route.id);
        return RouteSuggestion(
          route: route,
          etaMinutes: 10 + route.stops.length,
          stopsCount: route.stops.length,
          activeBuses: busesOnRoute.length,
          transfers: 1,
          walkDistance: '260m',
        );
      }).toList();
      if (fallback.isNotEmpty) {
        fallback[0] = RouteSuggestion(
          route: fallback[0].route,
          etaMinutes: fallback[0].etaMinutes,
          stopsCount: fallback[0].stopsCount,
          activeBuses: fallback[0].activeBuses,
          transfers: fallback[0].transfers,
          walkDistance: fallback[0].walkDistance,
          isFastest: true,
          fromStopName: fallback[0].fromStopName,
          toStopName: fallback[0].toStopName,
        );
      }
      return fallback;
    }

    if (ranked.isNotEmpty) {
      ranked[0] = RouteSuggestion(
        route: ranked[0].route,
        etaMinutes: ranked[0].etaMinutes,
        stopsCount: ranked[0].stopsCount,
        activeBuses: ranked[0].activeBuses,
        transfers: ranked[0].transfers,
        walkDistance: ranked[0].walkDistance,
        isFastest: true,
        fromStopName: ranked[0].fromStopName,
        toStopName: ranked[0].toStopName,
      );
    }

    return ranked;
  }
}

final transitProvider = NotifierProvider<TransitNotifier, TransitState>(
  TransitNotifier.new,
);

final busProvider = Provider.family<Bus?, String>((ref, busId) {
  return ref
      .watch(transitProvider)
      .buses
      .cast<Bus?>()
      .firstWhere((bus) => bus?.id == busId, orElse: () => null);
});

final routeProvider = Provider.family<TransitRoute?, String>((ref, routeId) {
  return ref
      .watch(transitProvider)
      .routes
      .cast<TransitRoute?>()
      .firstWhere((route) => route?.id == routeId, orElse: () => null);
});

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

String _normalizeQuery(String value) => value.trim().toLowerCase();

_StopMatch? _findBestStopMatch(TransitRoute route, String query) {
  if (query.isEmpty) return null;
  _StopMatch? best;
  for (var index = 0; index < route.stops.length; index++) {
    final stop = route.stops[index];
    final name = stop.name.toLowerCase();
    final score = name == query
        ? 100
        : name.startsWith(query)
        ? 80
        : name.contains(query)
        ? 60
        : 0;
    if (score == 0) continue;
    if (best == null || score > best.score) {
      best = _StopMatch(stop: stop, index: index, score: score);
    }
  }
  return best;
}

class _StopMatch {
  const _StopMatch({
    required this.stop,
    required this.index,
    required this.score,
  });

  final BusStop stop;
  final int index;
  final int score;
}

class _RankedSuggestion {
  const _RankedSuggestion({
    required this.score,
    required this.suggestion,
  });

  final int score;
  final RouteSuggestion suggestion;
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

int _estimateDelay(double speed) {
  if (speed <= 0) return 6;
  if (speed < 12) return 5;
  if (speed < 20) return 3;
  if (speed < 28) return 1;
  return 0;
}
