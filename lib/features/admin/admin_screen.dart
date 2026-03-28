import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/transit_provider.dart';
import '../../core/services/backend_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/doodle_icons.dart';
import '../../core/widgets/shared_widgets.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Control Center'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Routes'),
            Tab(text: 'Fleet'),
            Tab(text: 'Monitor'),
            Tab(text: 'Notify'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RoutesTab(routes: state.routes),
          _FleetTab(buses: state.buses, routes: state.routes),
          _MonitorTab(buses: state.buses, routes: state.routes),
          _NotificationsTab(buses: state.buses, routes: state.routes),
        ],
      ),
    );
  }
}

class _RoutesTab extends StatelessWidget {
  const _RoutesTab({required this.routes});

  final List<TransitRoute> routes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showSnackbar(context, 'Route drawing mode activated'),
                  icon: DoodleIcons.route(size: 18, color: AppColors.textOnPrimary),
                  label: const Text('Draw Route'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _showSnackbar(context, 'Add stop mode activated'),
                icon: DoodleIcons.pin(size: 18, color: AppColors.primary),
                label: const Text('Add Stop'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              final color = AppColors
                  .busLineColors[route.colorIndex % AppColors.busLineColors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: VtCard(
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${route.stops.length} stops · ${route.shortName}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RouteBadge(
                        text: route.shortName,
                        colorIndex: route.colorIndex,
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showSnackbar(context, 'Editing ${route.name}'),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FleetTab extends StatelessWidget {
  const _FleetTab({
    required this.buses,
    required this.routes,
  });

  final List<Bus> buses;
  final List<TransitRoute> routes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showSnackbar(context, 'Assign bus dialog'),
              icon: DoodleIcons.bus(size: 18, color: AppColors.textOnPrimary),
              label: const Text('Assign Bus to Route'),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: buses.length,
            itemBuilder: (context, index) {
              final bus = buses[index];
              final route = routes.cast<TransitRoute?>().firstWhere(
                    (item) => item?.id == bus.routeId,
                    orElse: () => null,
                  );
              if (route == null) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: VtCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      DoodleIcons.bus(
                        size: 24,
                        color: AppColors.busLineColors[
                            route.colorIndex % AppColors.busLineColors.length],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  bus.number,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                RouteBadge(
                                  text: route.shortName,
                                  colorIndex: route.colorIndex,
                                  fontSize: 10,
                                ),
                                if (bus.isDemo) ...[
                                  const SizedBox(width: 8),
                                  _MiniStatusChip(
                                    label: 'Demo',
                                    color: AppColors.info,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                SpeedIndicator(speed: bus.speed),
                                const SizedBox(width: 12),
                                OccupancyBadge(
                                  level: bus.occupancy,
                                  compact: false,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 58,
                        child: Column(
                          children: [
                            Text(
                              '${(bus.progress * 100).round()}%',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ProgressBar(
                              progress: bus.progress,
                              color: AppColors.busLineColors[
                                  route.colorIndex % AppColors.busLineColors.length],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonitorTab extends StatelessWidget {
  const _MonitorTab({
    required this.buses,
    required this.routes,
  });

  final List<Bus> buses;
  final List<TransitRoute> routes;

  @override
  Widget build(BuildContext context) {
    final activeBuses = buses.where((bus) => bus.isActive).length;
    final avgSpeed = buses.isEmpty
        ? 0
        : buses.fold<double>(0, (sum, bus) => sum + bus.speed) / buses.length;
    final highOccupancy = buses
        .where((bus) => bus.occupancy == OccupancyLevel.high)
        .length;
    final demoBuses = buses.where((bus) => bus.isDemo).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Active Buses',
                  value: '$activeBuses',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Avg Speed',
                  value: '${avgSpeed.round()} km/h',
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'High Load',
                  value: '$highOccupancy',
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Routes',
                  value: '${routes.length}',
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  label: 'Demo Fleet',
                  value: '$demoBuses',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          VtCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LIVE FLEET MAP',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: const LatLng(20.2961, 85.8245),
                        initialZoom: 11.5,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.velocitytransit.app',
                        ),
                        PolylineLayer(
                          polylines: routes
                              .where((route) => route.pathPoints.length >= 2)
                              .map((route) {
                            return Polyline(
                              points: route.pathPoints,
                              color: AppColors.busLineColors[
                                      route.colorIndex %
                                          AppColors.busLineColors.length]
                                  .withValues(alpha: 0.3),
                              strokeWidth: 2,
                            );
                          }).toList(),
                        ),
                        MarkerLayer(
                          markers: buses.map((bus) {
                            final route = routes.cast<TransitRoute?>().firstWhere(
                                  (item) => item?.id == bus.routeId,
                                  orElse: () => null,
                                );
                            final color = route == null
                                ? AppColors.primary
                                : AppColors.busLineColors[
                                    route.colorIndex %
                                        AppColors.busLineColors.length];
                            return Marker(
                              point: bus.position,
                              width: 12,
                              height: 12,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.backgroundCard,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          VtCard(
            child: Row(
              children: [
                DoodleIcons.play(size: 24, color: AppColors.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Passenger Experience',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        demoBuses > 0
                            ? 'Live trips merge with the demo fleet automatically.'
                            : 'Fleet is currently driven by live data only.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PulsingDot(color: AppColors.primary, size: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsTab extends ConsumerStatefulWidget {
  const _NotificationsTab({
    required this.buses,
    required this.routes,
  });

  final List<Bus> buses;
  final List<TransitRoute> routes;

  @override
  ConsumerState<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends ConsumerState<_NotificationsTab> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  String _audience = 'all';
  String _type = 'service_update';
  String? _selectedRouteId;
  String? _selectedBusId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'Service Update');
    _bodyController = TextEditingController(
      text: 'Transit services are running smoothly across the network.',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      _showSnackbar(context, 'Title and message are required');
      return;
    }

    setState(() => _isSending = true);
    try {
      await BackendApiService(
        authService: ref.read(authServiceProvider),
      ).sendAdminNotification(
        title: title,
        body: body,
        audience: _audience,
        type: _type,
        routeId: _selectedRouteId,
        busId: _selectedBusId,
      );
      await ref.read(transitProvider.notifier).refreshRemoteData();
      if (!mounted) return;
      _showSnackbar(context, 'Notification sent to $_audience users');
    } catch (error) {
      if (!mounted) return;
      _showSnackbar(context, 'Send failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeItems = widget.routes;
    final busItems = _selectedRouteId == null
        ? widget.buses
        : widget.buses.where((bus) => bus.routeId == _selectedRouteId).toList();

    if (_selectedBusId != null && busItems.every((bus) => bus.id != _selectedBusId)) {
      _selectedBusId = null;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        VtCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SEND APP NOTIFICATION',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This sends a push notification and stores the alert in the app history.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _audience,
                decoration: const InputDecoration(
                  labelText: 'Audience',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All users')),
                  DropdownMenuItem(value: 'passenger', child: Text('Passengers')),
                  DropdownMenuItem(value: 'driver', child: Text('Drivers')),
                  DropdownMenuItem(value: 'admin', child: Text('Admins')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _audience = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Notification type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'service_update', child: Text('Service Update')),
                  DropdownMenuItem(value: 'delay', child: Text('Delay')),
                  DropdownMenuItem(value: 'route_change', child: Text('Route Change')),
                  DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _type = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: ValueKey('route-$_selectedRouteId'),
                initialValue: _selectedRouteId,
                decoration: const InputDecoration(
                  labelText: 'Route (optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All routes'),
                  ),
                  ...routeItems.map(
                    (route) => DropdownMenuItem<String?>(
                      value: route.id,
                      child: Text('${route.shortName} · ${route.name}'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRouteId = value;
                    _selectedBusId = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: ValueKey('bus-${_selectedRouteId ?? 'all'}-$_selectedBusId'),
                initialValue: _selectedBusId,
                decoration: const InputDecoration(
                  labelText: 'Bus (optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Any bus'),
                  ),
                  ...busItems.map(
                    (bus) => DropdownMenuItem<String?>(
                      value: bus.id,
                      child: Text(
                        '${bus.number}${bus.routeShortName != null ? ' · ${bus.routeShortName}' : ''}',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedBusId = value);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendNotification,
                  icon: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSending ? 'Sending...' : 'Send Notification'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        VtCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BEST PRACTICES',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Use service updates for routine messages, route change for detours, delay for time-sensitive slowdowns, and emergency only for urgent network issues.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStatusChip extends StatelessWidget {
  const _MiniStatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return VtCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

void _showSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
