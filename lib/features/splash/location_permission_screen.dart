import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/passenger_location_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';

class LocationPermissionScreen extends ConsumerStatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  ConsumerState<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState
    extends ConsumerState<LocationPermissionScreen>
    with WidgetsBindingObserver {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(passengerLocationProvider.notifier).checkStatus();
    });
    ref.listenManual<PassengerLocationState>(passengerLocationProvider, (_, next) {
      if (next.permissionGranted && next.serviceEnabled) {
        _goToRoleSelection();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(passengerLocationProvider.notifier).checkStatus();
    }
  }

  void _goToRoleSelection() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    Navigator.pushReplacementNamed(context, AppRouter.sessionGate);
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(passengerLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              
              // Custom Location "Pulse" Graphic
              Center(child: _buildLocationGraphic()),
              
              const SizedBox(height: 48),
              
              // Text Content
              Text(
                'Enable location\nfor live transit',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'We use your location to show nearby buses, accurate ETAs, and live route progress right after you log in.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  height: 1.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Error Banner
              if (locationState.errorMessage != null)
                _buildErrorBanner(locationState.errorMessage!),

              const Spacer(flex: 3),
              
              // Action Buttons
              _buildPrimaryAction(locationState),
              const SizedBox(height: 16),
              _buildSecondaryAction(locationState),
              
              const SizedBox(height: 24),
              
              // Footer Text
              Text(
                'You can change this anytime in settings.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Creates a visual "radar pulse" effect behind the location icon
  Widget _buildLocationGraphic() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.05),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryMuted,
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/google_g_logo.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  /// Beautiful error banner matching the auth screen style
  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.error,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The main Call To Action button
  Widget _buildPrimaryAction(PassengerLocationState locationState) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: locationState.isLoading
            ? null
            : () async {
                if (locationState.isDeniedForever) {
                  await Geolocator.openAppSettings();
                  return;
                }
                await ref
                    .read(passengerLocationProvider.notifier)
                    .requestPermission();
              },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: locationState.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                locationState.isDeniedForever
                    ? 'Open Settings'
                    : 'Allow Location Access',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  /// The secondary skip/continue button
  Widget _buildSecondaryAction(PassengerLocationState locationState) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: () async {
          if (locationState.isDeniedForever) {
            await Geolocator.openAppSettings();
          } else if (!locationState.serviceEnabled) {
            await Geolocator.openLocationSettings();
          } else {
            _goToRoleSelection();
          }
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.transparent,
        ),
        child: Text(
          locationState.permissionGranted ? 'Continue' : 'Maybe Later',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
