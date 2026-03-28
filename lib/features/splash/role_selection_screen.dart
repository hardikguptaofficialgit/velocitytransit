import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/models.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shapes.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).asData?.value;
    final profile = ref.watch(userProfileProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 36),
              Text(
                'Choose your role',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),
              const SizedBox(height: 12),
              Text(
                authUser == null
                    ? 'Select how you want to sign in today.'
                    : 'Signed in as ${profile?.name ?? authUser.email ?? 'your account'}. Pick the experience you want to continue with.',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _RoleCard(
                title: 'Passenger',
                description: 'Login to track buses, view ETAs, and receive trip updates.',
                icon: Icons.person_search_rounded,
                color: AppColors.primary,
                shape: AppShapes.splash,
                onTap: () => _handleRoleTap(
                  context,
                  ref,
                  role: AppRoleChoice.passenger,
                  isAuthenticated: authUser != null,
                  canEnter: true,
                ),
              ).animate().fadeIn(delay: 160.ms, duration: 420.ms).slideX(begin: -0.2, end: 0),
              const SizedBox(height: 24),
              _RoleCard(
                title: 'Driver',
                description: authUser == null
                    ? 'Login with your assigned driver account to start live trips.'
                    : profile?.isDriver == true
                        ? 'Open driver cockpit, send GPS updates, and manage active trips.'
                        : 'This account is not enabled as a driver yet. Use a driver account or ask an admin to assign one.',
                icon: Icons.directions_bus_rounded,
                color: profile?.isDriver == true || authUser == null
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
                shape: AppShapes.hex,
                onTap: () => _handleRoleTap(
                  context,
                  ref,
                  role: AppRoleChoice.driver,
                  isAuthenticated: authUser != null,
                  canEnter: authUser == null || profile?.isDriver == true,
                ),
              ).animate().fadeIn(delay: 240.ms, duration: 420.ms).slideX(begin: 0.2, end: 0),
              const SizedBox(height: 24),
              if (authUser != null)
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    ref.invalidate(userProfileProvider);
                    ref.read(selectedRoleProvider.notifier).setRole(null);
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, AppRouter.auth);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRoleTap(
    BuildContext context,
    WidgetRef ref, {
    required AppRoleChoice role,
    required bool isAuthenticated,
    required bool canEnter,
  }) {
    ref.read(selectedRoleProvider.notifier).setRole(role);

    if (!canEnter) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver access is not enabled for this account yet.'),
        ),
      );
      return;
    }

    if (!isAuthenticated) {
      Navigator.pushNamed(context, AppRouter.auth, arguments: role);
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      role == AppRoleChoice.driver ? AppRouter.driverHome : AppRouter.home,
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.shape,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final ShapeBorder shape;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _isHovered ? widget.color : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: _isHovered ? widget.color : AppColors.border,
            width: 2,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: ShapeDecoration(
                color: _isHovered
                    ? Colors.white.withValues(alpha: 0.2)
                    : widget.color.withValues(alpha: 0.1),
                shape: widget.shape,
              ),
              child: Icon(
                widget.icon,
                size: 48,
                color: _isHovered ? Colors.white : widget.color,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: GoogleFonts.spaceGrotesk(
                color: _isHovered ? Colors.white : AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              widget.description,
              style: GoogleFonts.spaceGrotesk(
                color: _isHovered
                    ? Colors.white.withValues(alpha: 0.92)
                    : AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
