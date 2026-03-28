import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';
import '../data/simulation_data.dart';

/// Simulation engine that continuously moves buses along routes
class SimulationEngine {
  final Random _rng = Random();
  Timer? _timer;
  List<Bus> _buses = [];
  final List<TransitRoute> _routes = SimulationData.routes;

  List<Bus> get buses => List.unmodifiable(_buses);
  List<TransitRoute> get routes => _routes;

  void start(void Function(List<Bus>) onUpdate) {
    _buses = SimulationData.initialBuses();
    onUpdate(_buses);

    _timer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      _tick();
      onUpdate(_buses);
    });
  }

  void stop() {
    _timer?.cancel();
  }

  void _tick() {
    _buses = _buses.map((bus) {
      final route = _routes.firstWhere((r) => r.id == bus.routeId);
      if (route.pathPoints.isEmpty) return bus;

      // Advance progress
      final speedFactor = 0.002 + _rng.nextDouble() * 0.003;
      var newProgress = bus.progress + speedFactor;
      if (newProgress >= 1.0) newProgress = 0.0;

      // Calculate position
      final pathLen = route.pathPoints.length - 1;
      final idx = (newProgress * pathLen).floor().clamp(0, pathLen - 1);
      final t = (newProgress * pathLen) - idx;
      final newPos = route.pathPoints[idx].interpolate(
        route.pathPoints[(idx + 1).clamp(0, pathLen)],
        t.clamp(0.0, 1.0),
      );

      // Calculate heading
      final nextIdx = (idx + 1).clamp(0, pathLen);
      final dx = route.pathPoints[nextIdx].longitude - route.pathPoints[idx].longitude;
      final dy = route.pathPoints[nextIdx].latitude - route.pathPoints[idx].latitude;
      final heading = atan2(dx, dy) * 180 / pi;

      // Update current stop index
      final stopProgress = newProgress * (route.stops.length - 1);
      final currentStopIdx = stopProgress.floor().clamp(0, route.stops.length - 1);

      // Randomly fluctuate occupancy
      var occupancy = bus.occupancy;
      if (_rng.nextDouble() < 0.05) {
        occupancy = OccupancyLevel.values[_rng.nextInt(3)];
      }

      final speed = 15 + _rng.nextDouble() * 35;

      // AI Layer: Simulated Delay & Suggestion Logic
      var delay = bus.estimatedDelay;
      String? suggestion;
      
      // If occupancy is high, suggest increasing frequency or speeding up
      if (occupancy == OccupancyLevel.high) {
        suggestion = "High demand: Suggested increase in fleet speed";
        delay += _rng.nextInt(2);
      } else if (speed < 20) {
        // Low speed indicates traffic
        suggestion = "Traffic detected: Rerouting Bus 402 if possible";
        delay += 1 + _rng.nextInt(3);
      } else {
        delay = (delay - 1).clamp(0, 15);
      }

      return bus.copyWith(
        position: newPos,
        heading: heading,
        progress: newProgress,
        currentStopIndex: currentStopIdx,
        speed: speed,
        occupancy: occupancy,
        estimatedDelay: delay,
        suggestedAction: suggestion,
      );
    }).toList();
  }
}

/// State class for the transit system
class TransitState {
  final List<Bus> buses;
  final List<TransitRoute> routes;
  final List<TransitAlert> alerts;
  final List<FavoriteRoute> favorites;
  final bool isSimulationRunning;
  final bool showHeatmap;

  const TransitState({
    this.buses = const [],
    this.routes = const [],
    this.alerts = const [],
    this.favorites = const [],
    this.isSimulationRunning = false,
    this.showHeatmap = false,
  });

  TransitState copyWith({
    List<Bus>? buses,
    List<TransitRoute>? routes,
    List<TransitAlert>? alerts,
    List<FavoriteRoute>? favorites,
    bool? isSimulationRunning,
    bool? showHeatmap,
  }) {
    return TransitState(
      buses: buses ?? this.buses,
      routes: routes ?? this.routes,
      alerts: alerts ?? this.alerts,
      favorites: favorites ?? this.favorites,
      isSimulationRunning: isSimulationRunning ?? this.isSimulationRunning,
      showHeatmap: showHeatmap ?? this.showHeatmap,
    );
  }
}

/// Riverpod Notifier for all transit data (Riverpod v3 API)
/// Observes app lifecycle to pause simulation when backgrounded.
class TransitNotifier extends Notifier<TransitState>
    with WidgetsBindingObserver {
  final SimulationEngine _engine = SimulationEngine();

  @override
  TransitState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      _engine.stop();
      WidgetsBinding.instance.removeObserver(this);
    });

    // Initialize with simulation data
    final initialState = TransitState(
      routes: SimulationData.routes,
      alerts: SimulationData.sampleAlerts,
      favorites: SimulationData.sampleFavorites,
    );

    // Start simulation after build
    Future.microtask(() => startSimulation());

    return initialState;
  }

  /// Pause simulation when app is backgrounded to save battery
  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.paused ||
        appState == AppLifecycleState.inactive) {
      _engine.stop();
      state = state.copyWith(isSimulationRunning: false);
    } else if (appState == AppLifecycleState.resumed) {
      startSimulation();
    }
  }

  void startSimulation() {
    _engine.start((buses) {
      state = state.copyWith(
        buses: buses,
        isSimulationRunning: true,
      );
    });
  }

  void stopSimulation() {
    _engine.stop();
    state = state.copyWith(isSimulationRunning: false);
  }

  void toggleHeatmap() {
    state = state.copyWith(showHeatmap: !state.showHeatmap);
  }

  void addFavorite(FavoriteRoute fav) {
    state = state.copyWith(favorites: [...state.favorites, fav]);
  }

  void removeFavorite(String id) {
    state = state.copyWith(
      favorites: state.favorites.where((f) => f.id != id).toList(),
    );
  }

  void markAlertRead(String id) {
    state = state.copyWith(
      alerts: state.alerts.map((a) {
        if (a.id == id) return a.copyWith(isRead: true);
        return a;
      }).toList(),
    );
  }

  Bus? getBus(String busId) {
    try {
      return state.buses.firstWhere((b) => b.id == busId);
    } catch (_) {
      return null;
    }
  }

  TransitRoute? getRoute(String routeId) {
    try {
      return state.routes.firstWhere((r) => r.id == routeId);
    } catch (_) {
      return null;
    }
  }

  List<Bus> getBusesOnRoute(String routeId) {
    return state.buses.where((b) => b.routeId == routeId).toList();
  }

  List<RouteSuggestion> getSuggestions(String from, String to) {
    final rng = Random();
    return state.routes.map((route) {
      return RouteSuggestion(
        route: route,
        etaMinutes: 8 + rng.nextInt(25),
        stopsCount: route.stops.length,
        transfers: rng.nextInt(2),
        walkDistance: '${100 + rng.nextInt(400)}m',
        isFastest: route.id == 'route_1',
      );
    }).toList()
      ..sort((a, b) => a.etaMinutes.compareTo(b.etaMinutes));
  }
}

/// Providers
final transitProvider =
    NotifierProvider<TransitNotifier, TransitState>(TransitNotifier.new);

final busProvider = Provider.family<Bus?, String>((ref, busId) {
  return ref.watch(transitProvider).buses.cast<Bus?>().firstWhere(
        (b) => b?.id == busId,
        orElse: () => null,
      );
});

final routeProvider = Provider.family<TransitRoute?, String>((ref, routeId) {
  return ref.watch(transitProvider).routes.cast<TransitRoute?>().firstWhere(
        (r) => r?.id == routeId,
        orElse: () => null,
      );
});
