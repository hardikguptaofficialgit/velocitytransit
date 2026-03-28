import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/doodle_icons.dart';
import '../../core/providers/transit_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/widgets/shared_widgets.dart';
import '../../core/providers/search_provider.dart';
import 'widgets/map_view.dart';
import 'widgets/bus_card.dart';
import 'widgets/quick_actions.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchControllerTxt = TextEditingController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void dispose() {
    _searchControllerTxt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transitProvider);

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // ── Fullscreen Map ──
          const Positioned.fill(child: SimulatedMapView()),



          // ── Top: Search bar ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                if (state.alerts.any((a) => !a.isRead))
                   _buildDelayBanner(state.alerts.firstWhere((a) => !a.isRead).message),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      if (_isSearching)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                    ],
                  ),
                  child: _buildSearchBarBody(),
                ),
              ],
            ),
          ),

          // ── Quick actions (floating) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 76,
            right: 16,
            child: QuickActionsColumn(
              showHeatmap: state.showHeatmap,
              onToggleHeatmap: () =>
                  ref.read(transitProvider.notifier).toggleHeatmap(),
              onOpenAlerts: () =>
                  Navigator.pushNamed(context, AppRouter.alerts),
              onOpenFavorites: () =>
                  Navigator.pushNamed(context, AppRouter.favorites),
              alertCount:
                  state.alerts.where((a) => !a.isRead).length,
            ),
          ),

          // ── Smart route suggestion banner ──
          if (state.buses.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 76,
              left: 16,
              child: _buildSmartSuggestion(),
            ),

          // ── Bottom Sheet: Nearby buses ──
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.32,
            minChildSize: 0.12,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.backgroundSheet,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(
                    top: BorderSide(color: AppColors.border, width: 1),
                    left: BorderSide(color: AppColors.border, width: 1),
                    right: BorderSide(color: AppColors.border, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    const SheetHandle(),
                    // Quick ETA preview row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
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
                          const SizedBox(width: 8),
                          PulsingDot(color: AppColors.primary, size: 6),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                                context, AppRouter.routePlanner),
                            child: const Text('Plan Route'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Bus list
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: state.buses.length,
                        itemBuilder: (context, index) {
                          final bus = state.buses[index];
                          final route = state.routes.firstWhere(
                            (r) => r.id == bus.routeId,
                          );
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
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
              currentIndex: _currentNavIndex,
              onTap: (idx) {
                if (idx == 2) {
                  // AI Nav Item
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.backgroundLight),
                          const SizedBox(width: 8),
                          const Text('AI Copilot activated (Coming Soon)'),
                        ],
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
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
                    // Profile / Sign out
                    _showProfileSheet();
                    break;
                }
              },
              items: [
                BottomNavigationBarItem(
                  icon: DoodleIcons.map(
                    size: 24,
                    color: _currentNavIndex == 0 ? AppColors.primary : AppColors.textTertiary,
                  ),
                  label: 'Map',
                ),
                BottomNavigationBarItem(
                  icon: DoodleIcons.route(
                    size: 24,
                    color: _currentNavIndex == 1 ? AppColors.primary : AppColors.textTertiary,
                  ),
                  label: 'Routes',
                ),
                // AI Copilot Button
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                      color: Colors.white,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                  label: 'AI Copilot',
                ),
                BottomNavigationBarItem(
                  icon: DoodleIcons.compare(
                    size: 24,
                    color: _currentNavIndex == 3 ? AppColors.primary : AppColors.textTertiary,
                  ),
                  label: 'Compare',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    Icons.person_outline_rounded,
                    size: 24,
                    color: _currentNavIndex == 4 ? AppColors.primary : AppColors.textTertiary,
                  ),
                  label: 'Profile',
                ),
              ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBarBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isSearching = !_isSearching;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: Colors.transparent, // Ensure gesture detector captures touches
            child: Row(
              children: [
                DoodleIcons.search(
                  size: 20,
                  color: _isSearching ? AppColors.primary : AppColors.textTertiary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _searchControllerTxt,
                    autofocus: _isSearching,
                    onChanged: (val) => ref.read(searchProvider.notifier).search(val),
                    decoration: InputDecoration(
                      hintText: _isSearching ? 'Search Bhubaneswar...' : 'Where are you going?',
                      hintStyle: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_isSearching)
                  GestureDetector(
                    onTap: () => setState(() => _isSearching = false),
                    child: DoodleIcons.close(size: 16, color: AppColors.textSecondary),
                  )
                else
                  DoodleIcons.compass(size: 20, color: AppColors.primary),
              ],
            ),
          ),
        ),
        if (_isSearching) ...[
          const Divider(height: 1),
          ref.watch(searchProvider).when(
            data: (results) {
              if (results.isEmpty && _searchControllerTxt.text.length >= 3) {
                 return const Padding(
                   padding: EdgeInsets.all(20),
                   child: Text('No locations found in Bhubaneswar area', style: TextStyle(color: AppColors.textTertiary)),
                 );
              }
              return Column(
                children: results.map((res) => _buildSuggestionItem(res.title, res.subtitle, Icons.location_on)).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Error connecting to search engine', style: TextStyle(color: AppColors.error)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildSuggestionItem(String title, String subtitle, IconData icon) {
    return InkWell(
      onTap: () {
        setState(() => _isSearching = false);
        Navigator.pushNamed(context, AppRouter.routePlanner);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
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
            const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.border),
          ],
        ),
      ),
    );
  }

  Widget _buildDelayBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, size: 14, color: AppColors.error),
            onPressed: () {
              // In real app, mark as read
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSmartSuggestion() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DoodleIcons.route(size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            const Text(
              'Faster route in 2 min',
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

  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundSheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              const SizedBox(height: 16),
              const Icon(Icons.account_circle_rounded,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text(
                'Passenger Mode',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await AuthService().signOut();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, AppRouter.auth);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
