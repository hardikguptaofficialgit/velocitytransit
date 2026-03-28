import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/doodle_icons.dart';
import '../../core/providers/transit_provider.dart';
import '../../core/widgets/shared_widgets.dart';

class ComparisonScreen extends ConsumerStatefulWidget {
  const ComparisonScreen({super.key});

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  final Set<String> _selectedBusIds = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitProvider);
    final routes = state.routes;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Compare Buses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Selected comparison bar
          if (_selectedBusIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.backgroundCard,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COMPARING ${_selectedBusIds.length} BUSES',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Comparison visualization
                  ..._buildComparison(state),
                ],
              ),
            ),

          // Route-grouped bus list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: routes.length,
              itemBuilder: (context, routeIndex) {
                final route = routes[routeIndex];
                final busesOnRoute =
                    state.buses.where((b) => b.routeId == route.id).toList()
                      ..sort((a, b) {
                        if (a.isDemo != b.isDemo) {
                          return a.isDemo ? 1 : -1;
                        }
                        return a.estimatedDelay.compareTo(b.estimatedDelay);
                      });

                if (busesOnRoute.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 8),
                      child: Row(
                        children: [
                          RouteBadge(
                            text: route.shortName,
                            colorIndex: route.colorIndex,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            route.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...busesOnRoute.map((bus) {
                      final isSelected = _selectedBusIds.contains(bus.id);
                      final eta =
                          3 + Random(bus.id.hashCode).nextInt(20);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedBusIds.remove(bus.id);
                              } else if (_selectedBusIds.length < 3) {
                                _selectedBusIds.add(bus.id);
                              }
                            });
                          },
                          child: VtCard(
                            borderColor: isSelected
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : null,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Selection indicator
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.backgroundElevated,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.borderLight,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Center(
                                          child: Icon(
                                            Icons.check,
                                            size: 14,
                                            color: AppColors.textOnPrimary,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),

                                DoodleIcons.bus(
                                  size: 20,
                                  color: AppColors.busLineColors[
                                      route.colorIndex %
                                          AppColors.busLineColors.length],
                                ),
                                const SizedBox(width: 10),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bus.number,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                       Row(
                                         children: [
                                           Container(
                                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                             decoration: BoxDecoration(
                                               color: bus.isDemo
                                                   ? AppColors.primaryMuted
                                                   : Colors.green.withValues(alpha: 0.12),
                                               borderRadius: BorderRadius.circular(999),
                                             ),
                                             child: Text(
                                               bus.isDemo ? 'Demo' : 'Live',
                                               style: TextStyle(
                                                 color: bus.isDemo
                                                     ? AppColors.primary
                                                     : Colors.green.shade700,
                                                 fontSize: 10,
                                                 fontWeight: FontWeight.w700,
                                               ),
                                             ),
                                           ),
                                           const SizedBox(width: 6),
                                           OccupancyBadge(
                                             level: bus.occupancy,
                                             compact: true,
                                           ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${bus.speed.round()} km/h',
                                            style: const TextStyle(
                                              color: AppColors.textTertiary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                EtaDisplay(minutes: eta),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildComparison(TransitState state) {
    final selectedBuses = state.buses
        .where((b) => _selectedBusIds.contains(b.id))
        .toList();

    if (selectedBuses.isEmpty) return [];

    // Sort by ETA (simulated)
    selectedBuses.sort((a, b) {
      final etaA = 3 + Random(a.id.hashCode).nextInt(20);
      final etaB = 3 + Random(b.id.hashCode).nextInt(20);
      return etaA.compareTo(etaB);
    });

    return [
      ...selectedBuses.asMap().entries.map((entry) {
        final idx = entry.key;
        final bus = entry.value;
        final route = state.routes.cast<TransitRoute?>().firstWhere(
              (r) => r?.id == bus.routeId,
              orElse: () => null,
            );
        final eta = 3 + Random(bus.id.hashCode).nextInt(20);
        final isFastest = idx == 0;

        if (route == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Position badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isFastest
                      ? AppColors.primary
                      : AppColors.backgroundElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#${idx + 1}',
                    style: TextStyle(
                      color: isFastest
                          ? AppColors.textOnPrimary
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              RouteBadge(
                text: route.shortName,
                colorIndex: route.colorIndex,
                fontSize: 10,
              ),
              const SizedBox(width: 8),
              Text(
                bus.number,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isFastest)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'FASTEST',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                    ),
                  ),
              if (bus.isDemo) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'DEMO',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 10),
              EtaDisplay(minutes: eta),
            ],
          ),
        );
      }),
      // Visual bar comparison
      const SizedBox(height: 4),
      ...selectedBuses.asMap().entries.map((entry) {
        final bus = entry.value;
        final route = state.routes.cast<TransitRoute?>().firstWhere(
              (r) => r?.id == bus.routeId,
              orElse: () => null,
            );

        if (route == null) {
          return const SizedBox.shrink();
        }

        final color = AppColors.busLineColors[
            route.colorIndex % AppColors.busLineColors.length];
        final eta = 3 + Random(bus.id.hashCode).nextInt(20);
        // Normalize ETA to width fraction
        final maxEta =
            selectedBuses.fold<int>(0, (m, b) {
              final e = 3 + Random(b.id.hashCode).nextInt(20);
              return e > m ? e : m;
            });
        final fraction = eta / maxEta;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  bus.number.split('-').last,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: ProgressBar(
                  progress: fraction,
                  color: color,
                  height: 6,
                ),
              ),
            ],
          ),
        );
      }),
    ];
  }
}
