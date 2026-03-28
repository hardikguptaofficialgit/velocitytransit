import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/tracking_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  bool _isTripStarted = false;
  int _currentStopIndex = 0;

  final List<String> _stops = [
    'KIIT University',
    'Patia Square',
    'Infocity',
    'Jayadev Vihar',
    'Master Canteen',
  ];

  @override
  void initState() {
    super.initState();
    // Connect as driver when screen loads
    Future.microtask(() {
      ref.read(trackingProvider.notifier).connectAsDriver();
    });
  }

  @override
  void dispose() {
    ref.read(trackingProvider.notifier).disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(trackingProvider);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.backgroundDarkTitle,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(tracking, user),
            const SizedBox(height: 24),
            _buildStatusCard(tracking),
            const SizedBox(height: 24),
            _buildNextStopGuidance(tracking),
            const Spacer(),
            if (_isTripStarted) _buildQuickActionTray(),
            const SizedBox(height: 24),
            _buildMainControl(tracking),
            const SizedBox(height: 16),
            _buildSignOutButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(TrackingState tracking, User? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DRIVER MODE',
                style: GoogleFonts.spaceGrotesk(
                  color: const Color(0xFF10B981),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.displayName ?? 'Driver',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: tracking.isConnected
                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: tracking.isConnected
                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                    : Colors.red.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  tracking.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: tracking.isConnected
                      ? const Color(0xFF10B981)
                      : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  tracking.isConnected ? 'LIVE' : 'OFFLINE',
                  style: GoogleFonts.spaceGrotesk(
                    color: tracking.isConnected
                        ? const Color(0xFF10B981)
                        : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(TrackingState tracking) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            'STATUS',
            tracking.isDriverTracking ? 'TRACKING' : 'STANDBY',
            tracking.isDriverTracking
                ? const Color(0xFF10B981)
                : AppColors.textTertiary,
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          _buildStat(
            'CONNECTION',
            tracking.isConnected ? 'ONLINE' : 'OFFLINE',
            tracking.isConnected ? AppColors.info : AppColors.error,
          ),
          Container(width: 1, height: 40, color: AppColors.border),
          _buildStat(
            'STOP',
            '${_currentStopIndex + 1}/${_stops.length}',
            AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildNextStopGuidance(TrackingState tracking) {
    if (!_isTripStarted) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: tracking.isDriverTracking
                ? const Color(0xFF10B981).withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: tracking.isDriverTracking
                  ? const Color(0xFF10B981).withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                tracking.isDriverTracking
                    ? Icons.gps_fixed
                    : Icons.departure_board,
                size: 48,
                color: tracking.isDriverTracking
                    ? const Color(0xFF10B981)
                    : AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                tracking.isDriverTracking
                    ? 'GPS Active — Ready to Drive'
                    : 'Awaiting Assignment',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tracking.isDriverTracking
                    ? 'Your location is being broadcast to passengers.\nStart your trip when ready.'
                    : 'An admin must assign a bus to you\nbefore tracking can begin.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT STOP',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.textTertiary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stops[_currentStopIndex],
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stop ${_currentStopIndex + 1} of ${_stops.length}',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTray() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildActionBtn(Icons.record_voice_over, 'Announce'),
          const SizedBox(width: 16),
          _buildActionBtn(Icons.report_problem, 'Delay'),
          const SizedBox(width: 16),
          _buildActionBtn(Icons.groups, 'Load Full'),
        ],
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label) {
    return Expanded(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainControl(TrackingState tracking) {
    final canStart = tracking.isDriverTracking;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: canStart
            ? () {
                if (!_isTripStarted) {
                  setState(() => _isTripStarted = true);
                } else {
                  if (_currentStopIndex < _stops.length - 1) {
                    setState(() => _currentStopIndex++);
                  } else {
                    setState(() {
                      _isTripStarted = false;
                      _currentStopIndex = 0;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Trip completed successfully!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                }
              }
            : null,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: canStart
                ? (_isTripStarted
                    ? const Color(0xFF06B6D4)
                    : const Color(0xFF10B981))
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
            boxShadow: canStart
                ? [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 32,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              canStart
                  ? (_isTripStarted
                      ? (_currentStopIndex == _stops.length - 1
                          ? 'COMPLETE TRIP'
                          : 'ARRIVED AT STOP')
                      : 'START TRIP')
                  : 'WAITING FOR ASSIGNMENT',
              style: GoogleFonts.spaceGrotesk(
                color: canStart ? Colors.white : AppColors.textTertiary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextButton(
        onPressed: () async {
          ref.read(trackingProvider.notifier).disconnect();
          await AuthService().signOut();
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRouter.auth);
          }
        },
        child: Text(
          'Sign Out',
          style: GoogleFonts.spaceGrotesk(
            color: AppColors.textTertiary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
