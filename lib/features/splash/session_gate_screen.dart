import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../driver/driver_home_screen.dart';
import '../home/home_screen.dart';
import 'role_selection_screen.dart';

class SessionGateScreen extends ConsumerWidget {
  const SessionGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const _GateScaffold(child: CircularProgressIndicator()),
      error: (error, _) => _GateScaffold(
        child: _StatusCard(
          title: 'Session unavailable',
          message: error.toString(),
          actionLabel: 'Retry',
          onPressed: () {
            ref.invalidate(authStateProvider);
            ref.invalidate(userProfileProvider);
          },
        ),
      ),
      data: (user) {
        if (user == null) {
          return const RoleSelectionScreen();
        }

        final profile = ref.watch(userProfileProvider);
        return profile.when(
          loading: () => const _GateScaffold(child: CircularProgressIndicator()),
          error: (error, _) => _GateScaffold(
            child: _StatusCard(
              title: 'Profile sync failed',
              message: error.toString(),
              actionLabel: 'Sign out',
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                ref.invalidate(userProfileProvider);
              },
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return const RoleSelectionScreen();
            }

            if (!profile.isActive) {
              return _GateScaffold(
                child: _StatusCard(
                  title: 'Account disabled',
                  message:
                      'This account is currently inactive. Contact your administrator for access.',
                  actionLabel: 'Sign out',
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    ref.invalidate(userProfileProvider);
                  },
                ),
              );
            }

            if (profile.isDriver) {
              return const DriverHomeScreen();
            }

            return const HomeScreen();
          },
        );
      },
    );
  }
}

class _GateScaffold extends StatelessWidget {
  const _GateScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Center(child: child),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
