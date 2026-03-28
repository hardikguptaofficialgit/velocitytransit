import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'core/config/app_config.dart';
import 'core/data/models.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/transit_provider.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/driver/driver_home_screen.dart';

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
  runApp(
    ProviderScope(
      child: VelocityDriverApp(startupError: startupError),
    ),
  );
}

class VelocityDriverApp extends ConsumerStatefulWidget {
  const VelocityDriverApp({super.key, this.startupError});

  final String? startupError;

  @override
  ConsumerState<VelocityDriverApp> createState() => _VelocityDriverAppState();
}

class _VelocityDriverAppState extends ConsumerState<VelocityDriverApp> {
  @override
  void initState() {
    super.initState();
    ref.read(selectedRoleProvider.notifier).setRole(AppRoleChoice.driver);
    ref.listenManual(authStateProvider, (_, next) async {
      final user = next.asData?.value;
      if (user == null) return;
      await NotificationService.instance.initialize(
        authService: ref.read(authServiceProvider),
        role: AppRoleChoice.driver,
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
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                widget.startupError!,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Velocity Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DriverHomeScreen(),
    );
  }
}
