import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/data/models.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/splash/location_permission_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/splash/session_gate_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/route_planner/route_planner_screen.dart';
import '../../features/live_tracking/live_tracking_screen.dart';
import '../../features/route_details/route_details_screen.dart';
import '../../features/alerts/alerts_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/comparison/comparison_screen.dart';
import '../../features/trip_playback/trip_playback_screen.dart';
import '../../features/splash/role_selection_screen.dart';
import '../../features/driver/driver_home_screen.dart';
import '../../features/copilot/copilot_screen.dart';
import '../../features/profile/profile_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static const String splash = '/';
  static const String permissions = '/permissions';
  static const String sessionGate = '/session';
  static const String auth = '/auth';
  static const String roleSelection = '/role-selection';
  static const String driverHome = '/driver-home';
  static const String home = '/home';
  static const String routePlanner = '/route-planner';
  static const String liveTracking = '/live-tracking';
  static const String routeDetails = '/route-details';
  static const String alerts = '/alerts';
  static const String favorites = '/favorites';
  static const String comparison = '/comparison';
  static const String tripPlayback = '/trip-playback';
  static const String copilot = '/copilot';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    if (settings.name == roleSelection) {
      return _buildSpecialTransition(const RoleSelectionScreen(), settings);
    }

    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case permissions:
        return _buildRoute(const LocationPermissionScreen(), settings);
      case sessionGate:
        return _buildRoute(const SessionGateScreen(), settings);
      case auth:
        final role = settings.arguments as AppRoleChoice? ?? AppRoleChoice.passenger;
        return _buildRoute(AuthScreen(role: role), settings);
      case roleSelection:
        return _buildRoute(const RoleSelectionScreen(), settings);
      case driverHome:
        return _buildRoute(const DriverHomeScreen(), settings);
      case home:
        return _buildRoute(const HomeScreen(), settings);
      case routePlanner:
        final args = settings.arguments as Map<String, String>? ?? const {};
        return _buildRoute(
          RoutePlannerScreen(
            initialFrom: args['from'],
            initialTo: args['to'],
          ),
          settings,
        );
      case liveTracking:
        final busId = settings.arguments as String? ?? '';
        return _buildRoute(LiveTrackingScreen(busId: busId), settings);
      case routeDetails:
        final routeId = settings.arguments as String? ?? '';
        return _buildRoute(RouteDetailsScreen(routeId: routeId), settings);
      case alerts:
        return _buildRoute(const AlertsScreen(), settings);
      case favorites:
        return _buildRoute(const FavoritesScreen(), settings);
      case comparison:
        return _buildRoute(const ComparisonScreen(), settings);
      case tripPlayback:
        final busId = settings.arguments as String? ?? '';
        return _buildRoute(TripPlaybackScreen(busId: busId), settings);
      case copilot:
        return _buildRoute(const CopilotScreen(), settings);
      case profile:
        return _buildRoute(const ProfileScreen(), settings);
      default:
        return _buildRoute(const HomeScreen(), settings);
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Modern "Tide" Slide - Dual-phase fluid movement
        final slideTween = TweenSequence<Offset>([
          TweenSequenceItem(
            tween: Tween<Offset>(begin: const Offset(0.0, 0.15), end: const Offset(0.0, -0.01))
                .chain(CurveTween(curve: Curves.easeOutCubic)),
            weight: 70,
          ),
          TweenSequenceItem(
            tween: Tween<Offset>(begin: const Offset(0.0, -0.01), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeInCubic)),
            weight: 30,
          ),
        ]).animate(animation);

        final scaleTween = Tween<double>(
          begin: 0.96,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: scaleTween,
            child: SlideTransition(
              position: slideTween,
              child: child,
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 700), // Slower, more premium feel
    );
  }

  /// Special Circle Reveal transition for Splash to RoleSelection
  static PageRouteBuilder _buildSpecialTransition(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return Stack(
          children: [
            // Previous screen (Splash) stays behind until transition finishes
            secondaryAnimation.value < 1.0 
              ? const SplashScreen() 
              : const SizedBox(),
            
            // New screen expands as a circular "tide" from the center
            AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final double progress = animation.value;
                return ClipPath(
                  clipper: _CircularRevealClipper(progress),
                  child: child,
                );
              },
            ),
          ],
        );
      },
      transitionDuration: const Duration(milliseconds: 1200), // Heavy cinematic duration
    );
  }
}

class _CircularRevealClipper extends CustomClipper<Path> {
  final double progress;
  _CircularRevealClipper(this.progress);

  @override
  Path getClip(Size size) {
    final center = size.center(Offset.zero);
    final double diagonal = sqrt(size.width * size.width + size.height * size.height);
    final double radius = diagonal * Curves.easeInOutCubic.transform(progress);
    
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(_CircularRevealClipper oldClipper) => progress != oldClipper.progress;
}
