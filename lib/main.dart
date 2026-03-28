import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_config.dart';
import 'core/data/models.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/transit_provider.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupError;
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(options: AppConfig.webFirebaseOptions);
    } else {
      await Firebase.initializeApp();
    }
  } catch (error) {
    startupError = error.toString();
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.backgroundLight,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    ProviderScope(
      child: VelocityTransitApp(startupError: startupError),
    ),
  );
}

class VelocityTransitApp extends ConsumerStatefulWidget {
  const VelocityTransitApp({super.key, this.startupError});

  final String? startupError;

  @override
  ConsumerState<VelocityTransitApp> createState() => _VelocityTransitAppState();
}

class _VelocityTransitAppState extends ConsumerState<VelocityTransitApp> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(authStateProvider, (_, next) async {
      final user = next.asData?.value;
      if (user == null) {
        ref.read(selectedRoleProvider.notifier).setRole(null);
        return;
      }

      var role = ref.read(selectedRoleProvider) ?? AppRoleChoice.passenger;
      try {
        final profile = await ref.read(authServiceProvider).fetchCurrentProfile();
        role = profile.isDriver
            ? AppRoleChoice.driver
            : AppRoleChoice.passenger;
        ref.read(selectedRoleProvider.notifier).setRole(role);
      } catch (_) {}

      await NotificationService.instance.initialize(
        authService: ref.read(authServiceProvider),
        role: role,
      );
      await ref.read(transitProvider.notifier).refreshRemoteData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.startupError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                  const SizedBox(height: 16),
                  const Text(
                    'App startup failed',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.startupError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Velocity Transit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
