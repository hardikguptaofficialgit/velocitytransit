import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:geolocator/geolocator.dart';
import 'auth_provider.dart';

/// Backend URL — change to your deployed URL in production
const String backendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://10.0.2.2:4000', // Android Emulator → localhost
);

/// Live bus position from Socket.io
class LiveBusPosition {
  final String busId;
  final String busNumber;
  final String? routeId;
  final double lat;
  final double lng;
  final double speed;
  final double heading;
  final String lastUpdated;

  LiveBusPosition({
    required this.busId,
    required this.busNumber,
    this.routeId,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.heading,
    required this.lastUpdated,
  });

  factory LiveBusPosition.fromMap(Map<String, dynamic> map) {
    return LiveBusPosition(
      busId: map['busId'] ?? '',
      busNumber: map['busNumber'] ?? '',
      routeId: map['routeId'],
      lat: (map['lat'] ?? 0).toDouble(),
      lng: (map['lng'] ?? 0).toDouble(),
      speed: (map['speed'] ?? 0).toDouble(),
      heading: (map['heading'] ?? 0).toDouble(),
      lastUpdated: map['lastUpdated'] ?? '',
    );
  }
}

/// Socket tracking state
class TrackingState {
  final List<LiveBusPosition> livePositions;
  final bool isConnected;
  final bool isDriverTracking;

  const TrackingState({
    this.livePositions = const [],
    this.isConnected = false,
    this.isDriverTracking = false,
  });

  TrackingState copyWith({
    List<LiveBusPosition>? livePositions,
    bool? isConnected,
    bool? isDriverTracking,
  }) {
    return TrackingState(
      livePositions: livePositions ?? this.livePositions,
      isConnected: isConnected ?? this.isConnected,
      isDriverTracking: isDriverTracking ?? this.isDriverTracking,
    );
  }
}

/// Socket.io service for real-time bus tracking
class TrackingNotifier extends Notifier<TrackingState> {
  io.Socket? _socket;
  StreamSubscription<Position>? _locationSub;

  @override
  TrackingState build() {
    ref.onDispose(() {
      _socket?.disconnect();
      _locationSub?.cancel();
    });
    return const TrackingState();
  }

  /// Connect as passenger — receive bus positions
  Future<void> connectAsPassenger() async {
    final authService = AuthService();
    final token = await authService.getIdToken();
    if (token == null) return;

    _socket = io.io(
      backendUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      state = state.copyWith(isConnected: true);
      _socket!.emit('get:live');
    });

    _socket!.onDisconnect((_) {
      state = state.copyWith(isConnected: false);
    });

    _socket!.on('live:positions', (data) {
      if (data is List) {
        final positions = data
            .map((d) => LiveBusPosition.fromMap(Map<String, dynamic>.from(d)))
            .toList();
        state = state.copyWith(livePositions: positions);
      }
    });

    _socket!.on('bus:position', (data) {
      if (data is Map) {
        final pos = LiveBusPosition.fromMap(Map<String, dynamic>.from(data));
        final updated = [...state.livePositions];
        final idx = updated.indexWhere((p) => p.busId == pos.busId);
        if (idx >= 0) {
          updated[idx] = pos;
        } else {
          updated.add(pos);
        }
        state = state.copyWith(livePositions: updated);
      }
    });

    _socket!.on('bus:offline', (data) {
      if (data is Map) {
        final busId = data['busId'];
        state = state.copyWith(
          livePositions: state.livePositions
              .where((p) => p.busId != busId)
              .toList(),
        );
      }
    });

    _socket!.connect();
  }

  /// Connect as driver — send GPS coordinates
  Future<void> connectAsDriver() async {
    final authService = AuthService();
    final token = await authService.getIdToken();
    if (token == null) return;

    _socket = io.io(
      backendUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      state = state.copyWith(isConnected: true);
      _socket!.emit('driver:start');
    });

    _socket!.on('driver:assignment', (data) {
      state = state.copyWith(isDriverTracking: true);
      _startSendingLocation();
    });

    _socket!.on('error', (data) {
      // No active assignment
      state = state.copyWith(isDriverTracking: false);
    });

    _socket!.onDisconnect((_) {
      state = state.copyWith(isConnected: false, isDriverTracking: false);
      _locationSub?.cancel();
    });

    _socket!.connect();
  }

  /// Start sending GPS location every 3 seconds
  void _startSendingLocation() async {
    // Request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // minimum 5 meters movement
      ),
    ).listen((position) {
      _socket?.emit('driver:location', {
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed * 3.6, // m/s → km/h
        'heading': position.heading,
      });
    });
  }

  /// Disconnect
  void disconnect() {
    _socket?.disconnect();
    _locationSub?.cancel();
    state = const TrackingState();
  }
}

final trackingProvider = NotifierProvider<TrackingNotifier, TrackingState>(
  TrackingNotifier.new,
);
