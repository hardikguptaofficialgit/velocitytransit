import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/tracking_provider.dart';
import '../../core/providers/transit_provider.dart';
import '../../core/services/backend_api_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  bool _tripStarted = false;
  int _currentStopIndex = 0;
  final bool _alertsMuted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(trackingProvider.notifier).connectAsDriver();
      await ref.read(transitProvider.notifier).refreshRemoteData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider);
    final transitState = ref.watch(transitProvider);
    final transitNotifier = ref.read(transitProvider.notifier);
    final assignment = trackingState.activeAssignment ??
        (transitState.activeAssignment == null
            ? null
            : DriverAssignment(
                busId: transitState.activeAssignment!.busId,
                busNumber: transitState.activeAssignment!.busNumber,
                driverId: transitState.activeAssignment!.driverId,
                driverName: transitState.activeAssignment!.driverName,
                routeId: transitState.activeAssignment!.routeId,
              ));
    final route = assignment?.routeId == null
        ? null
        : transitState.routes
            .where((item) => item.id == assignment!.routeId)
            .cast<dynamic>()
            .firstOrNull;
    final stops = route?.stops?.cast<dynamic>() ?? const [];
    final currentStopName = stops.isEmpty
        ? 'Waiting for route'
        : stops[_currentStopIndex.clamp(0, stops.length - 1)].name.toString();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: ShapeDecoration(
                      color: AppColors.primary,
                      shape: AppShapes.star,
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DRIVER COCKPIT',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.primaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                          ),
                        ),
                        Text(
                          assignment == null
                              ? 'Waiting for active assignment'
                              : '${assignment.busNumber} • ${route?.name ?? assignment.routeId ?? 'Assigned route'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusChip(
                    trackingState.isDriverTracking ? 'LIVE' : 'STANDBY',
                    trackingState.isDriverTracking
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildHeroCard(
                assignment: assignment,
                routeName: route?.name?.toString(),
                trackingState: trackingState,
                currentStopName: currentStopName,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      'Bus',
                      assignment?.busNumber ?? '--',
                      Icons.confirmation_number_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      'Driver',
                      assignment?.driverName.isNotEmpty == true
                          ? assignment!.driverName
                          : 'Assigned',
                      Icons.badge_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      'Speed',
                      trackingState.isDriverTracking
                          ? '${(transitNotifier.getBus(assignment?.busId ?? '')?.speed ?? 0).round()} km/h'
                          : '--',
                      Icons.speed_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      'Alerts',
                      _alertsMuted ? 'Muted' : 'Active',
                      _alertsMuted ? Icons.notifications_off_rounded : Icons.notifications_active_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Route Stops',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: assignment == null || stops.isEmpty
                    ? Center(
                        child: Text(
                          trackingState.lastError ??
                              'Ask an admin to assign this driver account to a live bus.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: stops.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final stop = stops[index];
                          final isActive = index == _currentStopIndex;
                          final isPast = index < _currentStopIndex;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primary.withValues(alpha: 0.18)
                                  : const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isActive
                                    ? AppColors.primary
                                    : Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isPast
                                      ? AppColors.success
                                      : isActive
                                          ? AppColors.primary
                                          : Colors.white12,
                                  child: Icon(
                                    isPast ? Icons.check_rounded : Icons.place_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    stop.name.toString(),
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isActive)
                                  const Text(
                                    'NEXT',
                                    style: TextStyle(
                                      color: AppColors.primaryLight,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: assignment == null ? null : () => _handleTripAction(assignment, route, stops),
                style: FilledButton.styleFrom(
                  backgroundColor: assignment == null
                      ? Colors.white12
                      : _tripStarted
                          ? const Color(0xFF334155)
                          : AppColors.primary,
                  minimumSize: const Size.fromHeight(58),
                ),
                child: Text(
                  assignment == null
                      ? 'Waiting for Assignment'
                      : !_tripStarted
                          ? 'Start Trip'
                          : _currentStopIndex >= stops.length - 1
                              ? 'Complete Trip'
                              : 'Confirm Next Stop',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard({
    required DriverAssignment? assignment,
    required String? routeName,
    required TrackingState trackingState,
    required String currentStopName,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            assignment == null ? 'No active assignment' : routeName ?? assignment.routeId ?? 'Assigned route',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            assignment == null
                ? trackingState.lastError ??
                    'You will appear on the live map as soon as an admin assigns you a bus and you start a trip.'
                : !_tripStarted
                    ? 'Ready to start ${assignment.busNumber} and begin live GPS updates.'
                    : 'Current target: $currentStopName',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 22),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleTripAction(
    DriverAssignment assignment,
    dynamic route,
    List<dynamic> stops,
  ) async {
    final routeName = route?.name?.toString() ?? assignment.routeId ?? 'Assigned route';

    if (!_tripStarted) {
      setState(() => _tripStarted = true);
      await BackendApiService().sendTripEvent(
        type: 'trip_started',
        busId: assignment.busId,
        busNumber: assignment.busNumber,
        routeId: assignment.routeId ?? '',
        routeName: routeName,
        nextStop: stops.isNotEmpty ? stops.first.name.toString() : null,
      );
      await NotificationService.instance.showOrUpdateTripNotification(
        busId: assignment.busId,
        title: 'Trip Started',
        body: '$routeName • Next stop: ${stops.isNotEmpty ? stops.first.name : 'In progress'}',
        payload: {'busId': assignment.busId, 'routeId': assignment.routeId ?? ''},
      );
      return;
    }

    if (_currentStopIndex < stops.length - 1) {
      setState(() => _currentStopIndex++);
      final nextStop = stops[_currentStopIndex].name.toString();
      await BackendApiService().sendTripEvent(
        type: 'upcoming_stop',
        busId: assignment.busId,
        busNumber: assignment.busNumber,
        routeId: assignment.routeId ?? '',
        routeName: routeName,
        nextStop: nextStop,
        etaMinutes: 2,
      );
      if (!_alertsMuted) {
        await NotificationService.instance.showOrUpdateTripNotification(
          busId: assignment.busId,
          title: 'Upcoming Stop',
          body: '$routeName • Next stop: $nextStop • ETA 2 min',
          payload: {'busId': assignment.busId, 'routeId': assignment.routeId ?? ''},
        );
      }
      return;
    }

    setState(() {
      _tripStarted = false;
      _currentStopIndex = 0;
    });
    await BackendApiService().sendTripEvent(
      type: 'trip_completed',
      busId: assignment.busId,
      busNumber: assignment.busNumber,
      routeId: assignment.routeId ?? '',
      routeName: routeName,
    );
    await NotificationService.instance.cancelTripNotification(assignment.busId);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
