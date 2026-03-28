import 'package:flutter_test/flutter_test.dart';
import 'package:velocity_transit/core/data/models.dart';
import 'package:velocity_transit/core/providers/tracking_provider.dart';
import 'package:velocity_transit/core/providers/transit_provider.dart';

void main() {
  test('TrackingState.copyWith can clear activeAssignment and preserve lastError', () {
    const initial = TrackingState(
      activeAssignment: DriverAssignment(
        busId: 'bus-1',
        busNumber: 'VT-101',
        driverId: 'driver-1',
        driverName: 'Asha',
        routeId: 'route-1',
      ),
      lastError: 'old error',
    );

    final clearedAssignment = initial.copyWith(activeAssignment: null);

    expect(clearedAssignment.activeAssignment, isNull);
    expect(clearedAssignment.lastError, 'old error');
  });

  test('TransitState.copyWith can clear activeAssignment and preserve lastError', () {
    const initial = TransitState(
      activeAssignment: BusAssignment(
        id: 'assignment-1',
        busId: 'bus-1',
        driverId: 'driver-1',
        busNumber: 'VT-101',
        driverName: 'Asha',
        routeId: 'route-1',
        isActive: true,
      ),
      lastError: 'old error',
    );

    final clearedAssignment = initial.copyWith(activeAssignment: null);

    expect(clearedAssignment.activeAssignment, isNull);
    expect(clearedAssignment.lastError, 'old error');
  });
}
