import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/driver/driver_home_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: VelocityDriverApp(),
    ),
  );
}

class VelocityDriverApp extends StatelessWidget {
  const VelocityDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velocity Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DriverHomeScreen(),
    );
  }
}
