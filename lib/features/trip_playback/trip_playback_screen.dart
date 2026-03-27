import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/doodle_icons.dart';
import '../../core/data/models.dart';
import '../../core/providers/transit_provider.dart';
import '../../core/widgets/shared_widgets.dart';

class TripPlaybackScreen extends ConsumerStatefulWidget {
  final String busId;

  const TripPlaybackScreen({super.key, required this.busId});

  @override
  ConsumerState<TripPlaybackScreen> createState() => _TripPlaybackScreenState();
}

class _TripPlaybackScreenState extends ConsumerState<TripPlaybackScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _playbackController;
  bool _isPlaying = true;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _playbackController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _playbackController.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _playbackController.repeat();
      } else {
        _playbackController.stop();
      }
    });
  }

  void _setSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
      _playbackController.duration =
          Duration(seconds: (15 / speed).round());
      if (_isPlaying) {
        _playbackController.repeat();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitProvider);
    final bus = state.buses.cast<Bus?>().firstWhere(
          (b) => b?.id == widget.busId,
          orElse: () => null,
        );

    if (bus == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(title: const Text('Playback')),
        body: const Center(
          child: Text('Bus not found', style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final route = state.routes.firstWhere((r) => r.id == bus.routeId);
    final color = AppColors.busLineColors[
        route.colorIndex % AppColors.busLineColors.length];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Trip Playback â€” ${bus.number}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Map playback area
          Expanded(
            flex: 3,
            child: AnimatedBuilder(
              animation: _playbackController,
              builder: (context, _) {
                final progress = _playbackController.value;
                final pathIdx =
                    (progress * (route.pathPoints.length - 1)).floor().clamp(0, route.pathPoints.length - 2);
                final t = (progress * (route.pathPoints.length - 1)) - pathIdx;
                final busPos = route.pathPoints[pathIdx].interpolate(
                  route.pathPoints[pathIdx + 1],
                  t.clamp(0.0, 1.0),
                );
                
                final pointsPassed = route.pathPoints.sublist(0, pathIdx + 1);
                pointsPassed.add(busPos);

                return FlutterMap(
                  options: MapOptions(
                    initialCenter: route.stops.first.position,
                    initialZoom: 13.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.velocitytransit.app',
                    ),
                    PolylineLayer(
                      polylines: [
                         Polyline(
                          points: route.pathPoints,
                          color: color.withValues(alpha: 0.2),
                          strokeWidth: 4.0,
                        ),
                        Polyline(
                          points: pointsPassed,
                          color: color,
                          strokeWidth: 5.0,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        ...route.stops.map(
                          (stop) {
                            final stopProgress = route.stops.indexOf(stop) / (route.stops.length - 1);
                            final isPast = progress >= stopProgress;
                            return Marker(
                              point: stop.position,
                              width: isPast ? 10 : 14,
                              height: isPast ? 10 : 14,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundCard,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: color.withValues(alpha: isPast ? 0.4 : 1.0),
                                    width: isPast ? 2 : 3,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Marker(
                          point: busPos,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: DoodleIcons.bus(size: 20, color: AppColors.backgroundCard),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          // Playback controls
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.backgroundSheet,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              children: [
                const SheetHandle(),

                // Route info
                Row(
                  children: [
                    RouteBadge(
                      text: route.shortName,
                      colorIndex: route.colorIndex,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Bus ${bus.number} Â· ${route.stops.length} stops',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Scrubbable timeline
                AnimatedBuilder(
                  animation: _playbackController,
                  builder: (context, _) {
                    final progress = _playbackController.value;
                    final currentStopIdx =
                        (progress * (route.stops.length - 1)).round();
                    final currentStop = route.stops[
                        currentStopIdx.clamp(0, route.stops.length - 1)];

                    return Column(
                      children: [
                        // Current stop label
                        Row(
                          children: [
                            DoodleIcons.pin(
                              size: 14,
                              color: color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              currentStop.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${(progress * 100).round()}%',
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Slider
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: color,
                            inactiveTrackColor: AppColors.backgroundElevated,
                            thumbColor: color,
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                            ),
                            overlayColor: color.withValues(alpha: 0.1),
                          ),
                          child: Slider(
                            value: progress,
                            onChanged: (v) {
                              _playbackController.value = v;
                              if (_isPlaying) {
                                _playbackController.stop();
                                setState(() => _isPlaying = false);
                              }
                            },
                          ),
                        ),

                        // Stop markers
                        Row(
                          children: List.generate(route.stops.length, (i) {
                            final stopProgress =
                                i / (route.stops.length - 1);
                            final isPast = progress >= stopProgress;

                            return Expanded(
                              child: Center(
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isPast
                                        ? color
                                        : AppColors.borderLight,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Speed selector
                    _SpeedButton(
                      label: '0.5x',
                      isSelected: _playbackSpeed == 0.5,
                      onTap: () => _setSpeed(0.5),
                    ),
                    const SizedBox(width: 8),
                    _SpeedButton(
                      label: '1x',
                      isSelected: _playbackSpeed == 1.0,
                      onTap: () => _setSpeed(1.0),
                    ),
                    const SizedBox(width: 8),
                    _SpeedButton(
                      label: '2x',
                      isSelected: _playbackSpeed == 2.0,
                      onTap: () => _setSpeed(2.0),
                    ),

                    const SizedBox(width: 24),

                    // Play/Pause
                    GestureDetector(
                      onTap: _togglePlayback,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppColors.textOnPrimary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Reset
                    GestureDetector(
                      onTap: () {
                        _playbackController.value = 0;
                        if (!_isPlaying) {
                          setState(() => _isPlaying = true);
                          _playbackController.repeat();
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.replay,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpeedButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryMuted
              : AppColors.backgroundElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// AnimatedBuilder helper
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}

