import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/doodle_icons.dart';
import '../../core/data/models.dart';
import '../../core/providers/transit_provider.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RoutesTab(routes: state.routes),
          _FleetTab(buses: state.buses, routes: state.routes),
          _MonitorTab(buses: state.buses, routes: state.routes),
        ],
      ),
    );
  }
}

// â”€â”€ Routes Management Tab â”€â”€
class _RoutesTab extends StatelessWidget {
  final List<TransitRoute> routes;

  const _RoutesTab({required this.routes});

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
              final color = AppColors.busLineColors[
                  route.colorIndex % AppColors.busLineColors.length];

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
                              '${route.stops.length} stops Â· ${route.shortName}',
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
                            child: Icon(Icons.edit_outlined,
                                size: 16, color: AppColors.textSecondary),
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

// â”€â”€ Fleet Management Tab â”€â”€
class _FleetTab extends StatelessWidget {
  final List<Bus> buses;
  final List<TransitRoute> routes;

  const _FleetTab({required this.buses, required this.routes});

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
              final route = routes.firstWhere((r) => r.id == bus.routeId);

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
                      // Progress
                      SizedBox(
                        width: 50,
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
                                  route.colorIndex %
                                      AppColors.busLineColors.length],
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

// â”€â”€ Live Monitor Tab â”€â”€
class _MonitorTab extends StatelessWidget {
  final List<Bus> buses;
  final List<TransitRoute> routes;

  const _MonitorTab({required this.buses, required this.routes});

  @override
  Widget build(BuildContext context) {
    final activeBuses = buses.where((b) => b.isActive).length;
    final avgSpeed =
        buses.isEmpty ? 0 : buses.fold<double>(0, (s, b) => s + b.speed) / buses.length;
    final highOcc =
        buses.where((b) => b.occupancy == OccupancyLevel.high).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats row
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
                  value: '$highOcc',
                  color: AppColors.error,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Routes summary
          _StatCard(
            label: 'Total Routes',
            value: '${routes.length}',
            color: AppColors.accent,
          ),

          const SizedBox(height: 16),

          // Fleet map miniature
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
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.velocitytransit.app',
                        ),
                        PolylineLayer(
                          polylines: routes.where((r) => r.pathPoints.length >= 2).map((route) {
                            return Polyline(
                              points: route.pathPoints,
                              color: AppColors.busLineColors[route.colorIndex % AppColors.busLineColors.length].withValues(alpha: 0.3),
                              strokeWidth: 2.0,
                            );
                          }).toList(),
                        ),
                        MarkerLayer(
                          markers: buses.map((bus) {
                            final route = routes.firstWhere((r) => r.id == bus.routeId);
                            final color = AppColors.busLineColors[route.colorIndex % AppColors.busLineColors.length];
                            return Marker(
                              point: bus.position,
                              width: 12,
                              height: 12,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.backgroundCard, width: 2),
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

          // Simulation control
          VtCard(
            child: Row(
              children: [
                DoodleIcons.play(size: 24, color: AppColors.primary),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offline Simulation',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Running in demo mode',
                        style: TextStyle(
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

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
