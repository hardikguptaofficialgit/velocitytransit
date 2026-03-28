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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 84,
                height: 84,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.primary,
                  size: 42,
                ),
              ),
              Text(
                'Enable location for live transit',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We use your location to show nearby buses, accurate ETAs, and live route progress right after login.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              if (locationState.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    locationState.errorMessage!,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              const Spacer(),
              FilledButton(
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    locationState.isDeniedForever ? 'Open Settings' : 'Allow Location',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  if (locationState.isDeniedForever) {
                    await Geolocator.openAppSettings();
                  } else if (!locationState.serviceEnabled) {
                    await Geolocator.openLocationSettings();
                  } else {
                    _goToRoleSelection();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    locationState.permissionGranted ? 'Continue' : 'Continue for now',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can change this later from system settings.',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
