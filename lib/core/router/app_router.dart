import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/route_planner/route_planner_screen.dart';
import '../../features/live_tracking/live_tracking_screen.dart';
import '../../features/route_details/route_details_screen.dart';
import '../../features/admin/admin_screen.dart';
import '../../features/alerts/alerts_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/comparison/comparison_screen.dart';
import '../../features/trip_playback/trip_playback_screen.dart';
import '../../features/driver/driver_home_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String routePlanner = '/route-planner';
  static const String liveTracking = '/live-tracking';
  static const String routeDetails = '/route-details';
  static const String admin = '/admin';
  static const String alerts = '/alerts';
  static const String favorites = '/favorites';
  static const String comparison = '/comparison';
  static const String tripPlayback = '/trip-playback';
  static const String driverHome = '/driver-home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);
      case auth:
        return _buildRoute(const AuthScreen(), settings);
      case home:
        return _buildRoute(const HomeScreen(), settings);
      case routePlanner:
        return _buildRoute(const RoutePlannerScreen(), settings);
      case liveTracking:
        final busId = settings.arguments as String? ?? '';
        return _buildRoute(LiveTrackingScreen(busId: busId), settings);
      case routeDetails:
        final routeId = settings.arguments as String? ?? '';
        return _buildRoute(RouteDetailsScreen(routeId: routeId), settings);
      case admin:
        return _buildRoute(const AdminScreen(), settings);
      case alerts:
        return _buildRoute(const AlertsScreen(), settings);
      case favorites:
        return _buildRoute(const FavoritesScreen(), settings);
      case comparison:
        return _buildRoute(const ComparisonScreen(), settings);
      case tripPlayback:
        final busId = settings.arguments as String? ?? '';
        return _buildRoute(TripPlaybackScreen(busId: busId), settings);
      case driverHome:
        return _buildRoute(const DriverHomeScreen(), settings);
      default:
        return _buildRoute(const HomeScreen(), settings);
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;
        final tween = Tween(begin: const Offset(0.0, 0.04), end: Offset.zero)
            .chain(CurveTween(curve: curve));
        final fadeTween = Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: curve));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
