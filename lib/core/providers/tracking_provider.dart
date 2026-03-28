import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';
import 'auth_provider.dart';

class LiveBusPosition {
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

  final String busId;
  final String busNumber;
  final String? routeId;
  final double lat;
  final double lng;
  final double speed;
  final double heading;
  final String lastUpdated;

  factory LiveBusPosition.fromMap(Map<String, dynamic> map) {
    return LiveBusPosition(
      busId: map['busId']?.toString() ?? '',
      busNumber: map['busNumber']?.toString() ?? '',
      routeId: map['routeId']?.toString(),
      lat: (map['lat'] ?? 0).toDouble(),
      lng: (map['lng'] ?? 0).toDouble(),
      speed: (map['speed'] ?? 0).toDouble(),
      heading: (map['heading'] ?? 0).toDouble(),
      lastUpdated: map['lastUpdated']?.toString() ?? '',
    );
  }
}

class DriverAssignment {
  const DriverAssignment({
    required this.busId,
    required this.busNumber,
    required this.driverId,
    required this.driverName,
    this.routeId,
  });

  final String busId;
  final String busNumber;
  final String driverId;
  final String driverName;
  final String? routeId;

  factory DriverAssignment.fromMap(Map<String, dynamic> map) {
    return DriverAssignment(
      busId: map['busId']?.toString() ?? '',
      busNumber: map['busNumber']?.toString() ?? '',
      driverId: map['driverId']?.toString() ?? '',
      driverName: map['driverName']?.toString() ?? '',
      routeId: map['routeId']?.toString(),
    );
  }
}

class TrackingState {
  static const Object _unset = Object();

  const TrackingState({
    this.livePositions = const [],
    this.isConnected = false,
    this.isDriverTracking = false,
    this.activeAssignment,
    this.lastError,
  });

  final List<LiveBusPosition> livePositions;
  final bool isConnected;
  final bool isDriverTracking;
  final DriverAssignment? activeAssignment;
  final String? lastError;

  TrackingState copyWith({
    List<LiveBusPosition>? livePositions,
    bool? isConnected,
    bool? isDriverTracking,
    Object? activeAssignment = _unset,
    Object? lastError = _unset,
  }) {
    return TrackingState(
      livePositions: livePositions ?? this.livePositions,
      isConnected: isConnected ?? this.isConnected,
      isDriverTracking: isDriverTracking ?? this.isDriverTracking,
      activeAssignment: identical(activeAssignment, _unset)
          ? this.activeAssignment
          : activeAssignment as DriverAssignment?,
      lastError: identical(lastError, _unset)
          ? this.lastError
          : lastError as String?,
    );
  }
}

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

  Future<void> connectAsPassenger() async {
    final token = await AuthService().getIdToken();
    if (token == null) return;

    _socket?.disconnect();
    _socket = io.io(
      AppConfig.backendBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      state = state.copyWith(isConnected: true, lastError: null);
      _socket!.emit('get:live');
    });

    _socket!.onDisconnect((_) {
      state = state.copyWith(isConnected: false);
    });

    _socket!.on('live:positions', (data) {
      if (data is List) {
        final positions = data
            .map((item) => LiveBusPosition.fromMap(Map<String, dynamic>.from(item)))
            .toList();
        state = state.copyWith(livePositions: positions);
      }
    });

    _socket!.on('bus:position', (data) {
      if (data is Map) {
        final nextPosition = LiveBusPosition.fromMap(
          Map<String, dynamic>.from(data),
        );
        final updated = [...state.livePositions];
        final existingIndex = updated.indexWhere(
          (position) => position.busId == nextPosition.busId,
        );
        if (existingIndex == -1) {
          updated.add(nextPosition);
        } else {
          updated[existingIndex] = nextPosition;
        }
        state = state.copyWith(livePositions: updated);
      }
    });

    _socket!.on('bus:offline', (data) {
      if (data is Map) {
        final busId = data['busId']?.toString();
        state = state.copyWith(
          livePositions: state.livePositions
              .where((position) => position.busId != busId)
              .toList(),
        );
      }
    });

    _socket!.connect();
  }

  Future<void> connectAsDriver() async {
    final token = await AuthService().getIdToken();
    if (token == null) return;

    _socket?.disconnect();
    _locationSub?.cancel();
    _socket = io.io(
      AppConfig.backendBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      state = state.copyWith(isConnected: true, lastError: null);
      _socket!.emit('driver:start');
    });

    _socket!.on('driver:assignment', (data) {
      if (data is Map) {
        state = state.copyWith(
          isDriverTracking: true,
          activeAssignment: DriverAssignment.fromMap(
            Map<String, dynamic>.from(data),
          ),
          lastError: null,
        );
      }
      _startSendingLocation();
    });

    _socket!.on('error', (data) {
      final message = data is Map ? data['message']?.toString() : data?.toString();
      state = state.copyWith(
        isDriverTracking: false,
        activeAssignment: null,
        lastError: message ?? 'Tracking unavailable',
      );
    });

    _socket!.onDisconnect((_) {
      _locationSub?.cancel();
      state = state.copyWith(
        isConnected: false,
        isDriverTracking: false,
        activeAssignment: null,
      );
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _locationSub?.cancel();
    state = const TrackingState();
  }

  void _startSendingLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        isDriverTracking: false,
        lastError: 'Location permission is required for driver tracking.',
      );
      return;
    }

    await _locationSub?.cancel();
    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      _socket?.emit('driver:location', {
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed * 3.6,
        'heading': position.heading,
      });
    });
  }
}

final trackingProvider = NotifierProvider<TrackingNotifier, TrackingState>(
  TrackingNotifier.new,
);
