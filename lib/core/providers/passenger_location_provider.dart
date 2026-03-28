import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/models.dart';

class PassengerLocationState {
  const PassengerLocationState({
    this.position,
    this.permissionGranted = false,
    this.serviceEnabled = false,
    this.isLoading = false,
    this.hasPrompted = false,
    this.errorMessage,
    this.permission,
  });

  final LatLng? position;
  final bool permissionGranted;
  final bool serviceEnabled;
  final bool isLoading;
  final bool hasPrompted;
  final String? errorMessage;
  final LocationPermission? permission;

  bool get isDeniedForever => permission == LocationPermission.deniedForever;
  bool get needsPrompt => !permissionGranted || !serviceEnabled;

  PassengerLocationState copyWith({
    LatLng? position,
    bool? permissionGranted,
    bool? serviceEnabled,
    bool? isLoading,
    bool? hasPrompted,
    String? errorMessage,
    LocationPermission? permission,
  }) {
    return PassengerLocationState(
      position: position ?? this.position,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      serviceEnabled: serviceEnabled ?? this.serviceEnabled,
      isLoading: isLoading ?? this.isLoading,
      hasPrompted: hasPrompted ?? this.hasPrompted,
      errorMessage: errorMessage,
      permission: permission ?? this.permission,
    );
  }
}

class PassengerLocationNotifier extends Notifier<PassengerLocationState> {
  StreamSubscription<Position>? _positionSubscription;
  bool _isStartingTracking = false;
  bool _isTrackingStreamActive = false;

  @override
  PassengerLocationState build() {
    ref.onDispose(() {
      _positionSubscription?.cancel();
    });
    Future.microtask(checkStatus);
    return const PassengerLocationState(isLoading: true);
  }

  Future<void> checkStatus() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();
    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    state = state.copyWith(
      isLoading: false,
      serviceEnabled: serviceEnabled,
      permissionGranted: granted,
      permission: permission,
      errorMessage: serviceEnabled ? null : 'Turn on location services to see nearby transit.',
    );

    if (granted && serviceEnabled) {
      await _startTracking();
    }
  }

  Future<void> requestPermission() async {
    state = state.copyWith(isLoading: true, hasPrompted: true, errorMessage: null);
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = state.copyWith(
        isLoading: false,
        serviceEnabled: false,
        errorMessage: 'Location services are off. Enable them to continue.',
      );
      return;
    }

    final currentPermission = await Geolocator.checkPermission();
    final permission = currentPermission == LocationPermission.always ||
            currentPermission == LocationPermission.whileInUse
        ? currentPermission
        : await Geolocator.requestPermission();
    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    state = state.copyWith(
      isLoading: false,
      serviceEnabled: true,
      permissionGranted: granted,
      permission: permission,
      errorMessage: granted
          ? null
          : permission == LocationPermission.deniedForever
              ? 'Location access is permanently denied. Open settings to enable it.'
              : 'Location permission is required for live nearby transit.',
    );

    if (granted) {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    if (_isStartingTracking) return;
    if (_isTrackingStreamActive && state.position != null) return;

    _isStartingTracking = true;
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        state = state.copyWith(
          position: LatLng(lastKnown.latitude, lastKnown.longitude),
        );
      }

      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      state = state.copyWith(
        position: LatLng(current.latitude, current.longitude),
        permissionGranted: true,
        serviceEnabled: true,
        errorMessage: null,
      );

      await _positionSubscription?.cancel();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 20,
        ),
      ).listen((position) {
        state = state.copyWith(
          position: LatLng(position.latitude, position.longitude),
          permissionGranted: true,
          serviceEnabled: true,
          errorMessage: null,
        );
      });
      _isTrackingStreamActive = true;
    } catch (_) {
      _isTrackingStreamActive = false;
      state = state.copyWith(
        errorMessage: 'Unable to fetch the current location right now.',
      );
    } finally {
      _isStartingTracking = false;
    }
  }
}

final passengerLocationProvider =
    NotifierProvider<PassengerLocationNotifier, PassengerLocationState>(
      PassengerLocationNotifier.new,
    );
