import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/router/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0, 0.4, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _logoController.forward();

    Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.home);
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark design bg
      body: Stack(
        children: [
          // Main content
          Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, _) {
                return Opacity(
                  opacity: _logoOpacity.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Image
                      Transform.scale(
                        scale: _logoScale.value,
                        child: Image.asset(
                          'assets/logo.png',
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Column(
                          children: [
                            Text(
                              'VELOCITY',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'TRANSIT',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Bottom tagline
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (_, child) => Opacity(
                opacity: _logoOpacity.value,
                child: Text(
                  'Intelligent Urban Mobility',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


}

