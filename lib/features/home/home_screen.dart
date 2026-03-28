import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/models.dart';
import '../../core/providers/search_provider.dart';
import '../../core/providers/tracking_provider.dart';
import '../../core/providers/transit_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';
import '../../core/widgets/shared_widgets.dart';
import 'widgets/bus_card.dart';
import 'widgets/map_view.dart';
import 'widgets/quick_actions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const double _sheetMinSize = 0.12;
  static const double _sheetMidSize = 0.32;
  static const double _sheetMaxSize = 0.7;
  int _currentNavIndex = 0;
  _BusFilter _selectedBusFilter = _BusFilter.all;
  bool _isSearching = false;
  bool _hideAlert = false;
  final TextEditingController _searchControllerTxt = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingProvider.notifier).connectAsPassenger();
      ref.read(transitProvider.notifier).refreshRemoteData();
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _searchControllerTxt.dispose();
    super.dispose();
  }

  Future<void> _toggleNearbyBusesSheet() async {
    if (!_sheetController.isAttached) return;
    final size = _sheetController.size;
    final target = size < 0.24 ? _sheetMidSize : _sheetMinSize;
    await _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _expandNearbyBusesSheet() async {
    if (!_sheetController.isAttached) return;
    await _sheetController.animateTo(
      _sheetMaxSize,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  List<Bus> _filteredBuses(List<Bus> buses) {
    switch (_selectedBusFilter) {
      case _BusFilter.all:
        return buses;
      case _BusFilter.lowCrowd:
        return buses.where((bus) => bus.occupancy == OccupancyLevel.low).toList();
      case _BusFilter.fastest:
        final sorted = [...buses]..sort((a, b) => b.speed.compareTo(a.speed));
        return sorted;
      case _BusFilter.onTime:
        return buses.where((bus) => bus.estimatedDelay <= 2).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitProvider);
    final trackingState = ref.watch(trackingProvider);
    final visibleBuses = _filteredBuses(state.buses);
    final routeById = {for (final route in state.routes) route.id: route};
    final unreadAlerts = state.alerts.where((a) => !a.isRead).toList();
    final hasUnreadAlert = !_hideAlert && unreadAlerts.isNotEmpty;
    final visibleMessage = state.lastError ?? (hasUnreadAlert ? unreadAlerts.first.message : null);
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          const Positioned.fill(child: SimulatedMapView()),
          Positioned(
            top: topInset + 14,
            left: 16,
            right: 16,
            child: _buildTopBar(),
          ),
          if (state.buses.isNotEmpty && !_isSearching)
            Positioned(
              top: topInset + 76,
              left: 16,
              child: _buildSmartSuggestion(),
            ),
          if (!_isSearching)
            Positioned(
              top: topInset + 118,
              left: 16,
              child: _buildNetworkStatus(state, trackingState),
            ),
          if (!_isSearching)
            Positioned(
              top: topInset + 164,
              right: 16,
              child: QuickActionsColumn(
                showHeatmap: state.showHeatmap,
                onToggleHeatmap: () =>
                    ref.read(transitProvider.notifier).toggleHeatmap(),
                onOpenFavorites: () =>
                    Navigator.pushNamed(context, AppRouter.favorites),
              ),
            ),
          if (!_isSearching)
            Positioned(
              left: 16,
              bottom: MediaQuery.of(context).size.height * 0.34,
              child: _buildSheetLiftButton(),
            ),
          if (visibleMessage != null && !_isSearching)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).size.height * 0.35,
              child: _buildNotificationCard(
                visibleMessage,
                isError: state.lastError != null,
              ),
            ),
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: _sheetMidSize,
            minChildSize: _sheetMinSize,
            maxChildSize: _sheetMaxSize,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.backgroundSheet,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                    left: BorderSide(color: AppColors.border, width: 1),
                    right: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleNearbyBusesSheet,
                      onDoubleTap: _expandNearbyBusesSheet,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SheetHandle(),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      const Text(
                                        'Nearby Buses',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      PulsingDot(color: AppColors.primary, size: 6),
                                      Text(
                                        '${visibleBuses.length} visible',
                                        style: const TextStyle(
                                          color: AppColors.textTertiary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRouter.routePlanner,
                              ),
                              child: const Text('Plan Route'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildFilterChip(_BusFilter.all, 'All'),
                          _buildFilterChip(_BusFilter.lowCrowd, 'Low Crowd'),
                          _buildFilterChip(_BusFilter.fastest, 'Fastest'),
                          _buildFilterChip(_BusFilter.onTime, 'On Time'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 90,
                        ),
                        itemCount: visibleBuses.length,
                        itemBuilder: (context, index) {
                          final bus = visibleBuses[index];
                          final route = routeById[bus.routeId];
                          if (route == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: NearbyBusCard(
                              bus: bus,
                              route: route,
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRouter.liveTracking,
                                arguments: bus.id,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.94, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: AppShapes.star,
            onTap: () => Navigator.pushNamed(context, AppRouter.copilot),
            child: Container(
              width: 58,
              height: 58,
              decoration: ShapeDecoration(
                color: const Color(0xFFD8E0F3),
                shape: AppShapes.star,
                shadows: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF213A63),
                size: 20,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            color: AppColors.backgroundCard.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(child: _buildNavItem(Icons.map_rounded, Icons.map_outlined, 'Map', 0)),
              Expanded(
                child: _buildNavItem(Icons.route_rounded, Icons.route_outlined, 'Routes', 1),
              ),
              const SizedBox(width: 78),
              Expanded(
                child: _buildNavItem(
                  Icons.compare_arrows_rounded,
                  Icons.compare_arrows_outlined,
                  'Compare',
                  3,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  Icons.favorite_rounded,
                  Icons.favorite_border_rounded,
                  'Favorites',
                  4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildSearchBarBody()),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRouter.profile),
          child: Container(
            width: 48,
            height: 48,
            decoration: ShapeDecoration(
              color: AppColors.backgroundCard,
              shape: AppShapes.hex,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSheetLiftButton() {
    return AnimatedBuilder(
      animation: _sheetController,
      builder: (context, _) {
        final isCollapsed =
            !_sheetController.isAttached || _sheetController.size < 0.24;
        return GestureDetector(
          onTap: isCollapsed ? _toggleNearbyBusesSheet : _expandNearbyBusesSheet,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 10,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCollapsed
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.unfold_less_rounded,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  isCollapsed ? 'Nearby' : 'Pull Up',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(_BusFilter filter, String label) {
    final isSelected = _selectedBusFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() => _selectedBusFilter = filter);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryMuted : AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.24)
                  : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkStatus(TransitState state, TrackingState trackingState) {
    final connectionLabel = trackingState.isConnected
        ? 'Backend live feed connected'
        : state.isLoadingNetwork
        ? 'Refreshing network'
        : 'Connecting live feed';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: trackingState.isConnected
                  ? AppColors.success
                  : state.isLoadingNetwork
                  ? AppColors.warning
                  : AppColors.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            connectionLabel,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData active,
    IconData inactive,
    String label,
    int idx,
  ) {
    final isSelected = _currentNavIndex == idx;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        setState(() => _currentNavIndex = idx);
        switch (idx) {
          case 0:
            break;
          case 1:
            Navigator.pushNamed(context, AppRouter.routePlanner);
            break;
          case 3:
            Navigator.pushNamed(context, AppRouter.comparison);
            break;
          case 4:
            Navigator.pushNamed(context, AppRouter.favorites);
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 12 : 0,
              vertical: isSelected ? 8 : 0,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryMuted : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: isSelected
                  ? Border.all(color: AppColors.primary.withValues(alpha: 0.16))
                  : null,
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 220),
              scale: isSelected ? 1.04 : 1,
              child: Icon(
                isSelected ? active : inactive,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 2),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: isSelected ? 1 : 0.72,
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
                fontSize: isSelected ? 10.5 : 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarBody() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchControllerTxt,
                    autofocus: _isSearching,
                    onTap: () => setState(() => _isSearching = true),
                    onChanged: (val) =>
                        ref.read(searchProvider.notifier).search(val),
                    decoration: const InputDecoration(
                      hintText: 'Search stops or destinations',
                      hintStyle: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_isSearching)
                  GestureDetector(
                    onTap: () {
                      _searchControllerTxt.clear();
                      setState(() => _isSearching = false);
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (_isSearching) ...[
            const Divider(height: 1),
            ref
                .watch(searchProvider)
                .when(
                  data: (results) {
                    if (results.isEmpty &&
                        _searchControllerTxt.text.length >= 3) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No nearby places found.',
                          style: TextStyle(color: AppColors.textTertiary),
                        ),
                      );
                    }
                    return Column(
                      children: results
                          .map(
                            (res) => _buildSuggestionItem(
                              res.title,
                              res.subtitle,
                              Icons.location_on_outlined,
                            ),
                          )
                          .toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (e, _) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Search is unavailable right now.',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String title, String subtitle, IconData icon) {
    return InkWell(
      onTap: () {
        setState(() => _isSearching = false);
        Navigator.pushNamed(
          context,
          AppRouter.routePlanner,
          arguments: {
            'from': 'Current Location',
            'to': title,
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.backgroundElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(String message, {bool isError = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isError
                ? AppColors.error.withValues(alpha: 0.22)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isError
                    ? AppColors.error.withValues(alpha: 0.10)
                    : AppColors.accentMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isError ? Icons.wifi_off_rounded : Icons.notifications_none_rounded,
                size: 16,
                color: isError ? AppColors.error : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
              onPressed: () => setState(() => _hideAlert = true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartSuggestion() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-12 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alt_route_rounded, size: 15, color: AppColors.primary),
            SizedBox(width: 6),
            Text(
              'Faster route, save 2 min',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _BusFilter { all, lowCrowd, fastest, onTime }
