import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models.dart';
import '../../core/providers/transit_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/doodle_icons.dart';
import '../../core/widgets/shared_widgets.dart';

class RoutePlannerScreen extends ConsumerStatefulWidget {
  final String? initialFrom;
  final String? initialTo;

  const RoutePlannerScreen({super.key, this.initialFrom, this.initialTo});

  @override
  ConsumerState<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends ConsumerState<RoutePlannerScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late final AnimationController _animController;
  List<RouteSuggestion> _suggestions = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _fromController = TextEditingController(
      text: widget.initialFrom?.trim().isNotEmpty == true
          ? widget.initialFrom
          : 'Main Hub',
    );
    _toController = TextEditingController(
      text: widget.initialTo?.trim().isNotEmpty == true
          ? widget.initialTo
          : 'Tech Park East',
    );
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(const Duration(milliseconds: 250), _search);
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
    final currentFrom = _fromController.text;
    _fromController.text = _toController.text;
    _toController.text = currentFrom;
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.backgroundCard,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _search,
                          child: const Text('Find Best Route'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
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
          if (_hasSearched) ...[
            const SectionHeader(title: 'Smart Route Suggestions'),
            Expanded(
              child: _suggestions.isEmpty
                  ? const _NoRoutesFound()
                  : ListView.builder(
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
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.alt_route_rounded,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    SizedBox(height: 16),
                    Text(
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
  const _RouteCard({
    required this.suggestion,
    required this.onTap,
  });

  final RouteSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final route = suggestion.route;

    return VtCard(
      onTap: onTap,
      borderColor:
          suggestion.isFastest ? AppColors.primary.withValues(alpha: 0.4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      '${suggestion.stopsCount} stops · ${suggestion.activeBuses} active bus${suggestion.activeBuses == 1 ? '' : 'es'} · ${suggestion.transfers} transfer${suggestion.transfers != 1 ? 's' : ''}',
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (suggestion.fromStopName != null)
                _RouteInfoPill(label: 'Board', value: suggestion.fromStopName!),
              if (suggestion.toStopName != null)
                _RouteInfoPill(label: 'Drop', value: suggestion.toStopName!),
              _RouteInfoPill(label: 'Walk', value: suggestion.walkDistance),
            ],
          ),
          const SizedBox(height: 14),
          _MiniRoutePreview(route: route),
        ],
      ),
    );
  }
}

class _RouteInfoPill extends StatelessWidget {
  const _RouteInfoPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniRoutePreview extends StatelessWidget {
  const _MiniRoutePreview({required this.route});

  final TransitRoute route;

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.busLineColors[route.colorIndex % AppColors.busLineColors.length];

    return SizedBox(
      height: 32,
      child: Row(
        children: [
          for (var i = 0; i < route.stops.length; i++) ...[
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

class _NoRoutesFound extends StatelessWidget {
  const _NoRoutesFound();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.route_rounded,
              size: 56,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: 14),
            Text(
              'No strong route match found for that trip.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try stop names like Main Hub, City Center, or Terminal 1.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
