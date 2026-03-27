import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/doodle_icons.dart';
import '../../core/data/models.dart';
import '../../core/providers/transit_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/shared_widgets.dart';

class RoutePlannerScreen extends ConsumerStatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  ConsumerState<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends ConsumerState<RoutePlannerScreen>
    with SingleTickerProviderStateMixin {
  final _fromController = TextEditingController(text: 'Marine Drive');
  final _toController = TextEditingController(text: 'Tech Park East');
  List<RouteSuggestion> _suggestions = [];
  bool _hasSearched = false;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // Auto-search on init
    Future.delayed(const Duration(milliseconds: 300), _search);
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _search() {
    final notifier = ref.read(transitProvider.notifier);
    setState(() {
      _suggestions = notifier.getSuggestions(
        _fromController.text,
        _toController.text,
      );
      _hasSearched = true;
    });
    _animController.forward(from: 0);
  }

  void _swapLocations() {
    final temp = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = temp;
    _search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Route Planner'),
        leading: IconButton(
          icon: DoodleIcons.close(size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // â”€â”€ Input Section â”€â”€
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.backgroundCard,
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                // Route dots
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 36,
                      color: AppColors.borderLight,
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Input fields
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: _fromController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'From',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _toController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'To',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Swap button
                GestureDetector(
                  onTap: _swapLocations,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: DoodleIcons.swap(
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // â”€â”€ Suggestions â”€â”€
          if (_hasSearched) ...[
            const SectionHeader(title: 'Smart Route Suggestions'),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400 + index * 100),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RouteCard(
                        suggestion: _suggestions[index],
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRouter.routeDetails,
                            arguments: _suggestions[index].route.id,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DoodleIcons.route(
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Enter source and destination',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final RouteSuggestion suggestion;
  final VoidCallback onTap;

  const _RouteCard({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final route = suggestion.route;

    return VtCard(
      onTap: onTap,
      borderColor: suggestion.isFastest ? AppColors.primary.withValues(alpha: 0.4) : null,
      child: Column(
        children: [
          Row(
            children: [
              RouteBadge(text: route.shortName, colorIndex: route.colorIndex),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            route.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (suggestion.isFastest)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'FASTEST',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${suggestion.stopsCount} stops Â· ${suggestion.transfers} transfer${suggestion.transfers != 1 ? 's' : ''} Â· Walk ${suggestion.walkDistance}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              EtaDisplay(minutes: suggestion.etaMinutes),
            ],
          ),

          const SizedBox(height: 14),

          // Mini route preview
          _MiniRoutePreview(route: route),
        ],
      ),
    );
  }
}

/// Visual mini route preview
class _MiniRoutePreview extends StatelessWidget {
  final TransitRoute route;

  const _MiniRoutePreview({required this.route});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.busLineColors[route.colorIndex % AppColors.busLineColors.length];

    return SizedBox(
      height: 32,
      child: Row(
        children: [
          for (var i = 0; i < route.stops.length; i++) ...[
            // Stop dot
            Container(
              width: i == 0 || i == route.stops.length - 1 ? 10 : 6,
              height: i == 0 || i == route.stops.length - 1 ? 10 : 6,
              decoration: BoxDecoration(
                color: i == 0 || i == route.stops.length - 1
                    ? color
                    : color.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
            // Connector
            if (i < route.stops.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  color: color.withValues(alpha: 0.3),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
