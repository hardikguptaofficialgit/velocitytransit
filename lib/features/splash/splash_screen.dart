import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/router/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Let the GIF play nicely for approx 4 seconds
    Timer(const Duration(milliseconds: 4000), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.permissions);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions to make the logo size responsive and larger
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF010102),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Increased height using screen proportion (e.g., 50% of screen height)
            Image.asset(
                  'assets/logoanimation.gif',
                  height: screenHeight * 0.5,
                  width: screenWidth * 0.85,
                  fit: BoxFit.contain,
                )
                .animate()
                .fadeIn(duration: 1000.ms, curve: Curves.easeOutCubic)
                .scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.0, 1.0),
                  duration: 1000.ms,
                  curve: Curves
                      .easeOutBack, // Gives a slight, premium "pop" effect
                ),

            // OPTIONAL: A subtle, modern loading indicator below the GIF.
            // Uncomment the lines below if you want to add it.
            /*
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.white24, // Subtle color to not distract from the GIF
              strokeWidth: 2.5,
            ).animate().fadeIn(delay: 1500.ms, duration: 800.ms),
            */
          ],
        ),
      ),
    );
  }
}
