import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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
  await Firebase.initializeApp(options: AppConfig.firebaseOptions);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.backgroundLight,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ProviderScope(child: VelocityTransitApp()));
}

class VelocityTransitApp extends ConsumerStatefulWidget {
  const VelocityTransitApp({super.key});

  @override
  ConsumerState<VelocityTransitApp> createState() => _VelocityTransitAppState();
}

class _VelocityTransitAppState extends ConsumerState<VelocityTransitApp> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(authStateProvider, (_, next) async {
      final user = next.asData?.value;
      if (user == null) return;

      final role = ref.read(selectedRoleProvider) ?? AppRoleChoice.passenger;
      await NotificationService.instance.initialize(
        authService: ref.read(authServiceProvider),
        role: role,
      );
      await ref.read(transitProvider.notifier).refreshRemoteData();
    });
  }

  @override
  Widget build(BuildContext context) {
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
