import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/models.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.role = AppRoleChoice.passenger,
  });

  final AppRoleChoice role;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  bool get _isDriverLogin => widget.role == AppRoleChoice.driver;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    try {
      _setLoadingState(true);
      if (_isLogin) {
        await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );
      }

      final profile = await _authService.fetchCurrentProfile();
      await _completeAuth(profile);
    } catch (error) {
      _setError(_readableMessage(error));
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> _handleGoogleAuth() async {
    try {
      _setLoadingState(true);
      final user = await _authService.signInWithGoogle();
      if (user == null) {
        throw Exception('Google sign-in was cancelled.');
      }
      final profile = await _authService.fetchCurrentProfile();
      await _completeAuth(profile);
    } catch (error) {
      _setError(_readableMessage(error));
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> _completeAuth(AppUserProfile profile) async {
    if (_isDriverLogin && !profile.isDriver) {
      await _authService.signOut();
      throw Exception('This account is not enabled as a driver yet.');
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      _isDriverLogin ? AppRouter.driverHome : AppRouter.home,
      (route) => false,
    );
  }

  void _setLoadingState(bool value) {
    if (!mounted) return;
    setState(() {
      _loading = value;
      if (value) _error = null;
    });
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  String _readableMessage(Object error) {
    final message = error.toString();
    return message.contains('invalid-credential')
        ? 'Invalid email or password.'
        : message.contains('email-already-in-use')
            ? 'This email is already registered.'
            : message.contains('weak-password')
                ? 'Password must be at least 6 characters.'
                : message.contains('network-request-failed')
                    ? 'Network issue detected. Please try again.'
                    : message.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = _isDriverLogin ? 'Driver' : 'Passenger';
    final roleIcon =
        _isDriverLogin ? Icons.directions_bus_rounded : Icons.person_pin_circle_rounded;
    final roleAccent = _isDriverLogin ? AppColors.textPrimary : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -60,
            child: _AmbientBlob(
              size: 240,
              color: AppColors.primaryMuted,
            ),
          ),
          Positioned(
            left: -70,
            bottom: 120,
            child: _AmbientBlob(
              size: 180,
              color: AppColors.accentMuted,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: roleAccent.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                roleIcon,
                                color: roleAccent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isLogin ? '$roleLabel Login' : '$roleLabel Sign Up',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isDriverLogin
                                        ? 'Use your assigned account to manage live trips and updates.'
                                        : 'Access nearby buses, ETAs, alerts, and trip updates.',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSheet,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.route_rounded,
                                color: roleAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _isDriverLogin
                                      ? 'Driver access is enabled only for accounts assigned by an admin.'
                                      : 'New accounts can sign up with email or continue with Google.',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: AppColors.error,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: AppColors.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        if (!_isLogin) ...[
                          _buildTextField(
                            controller: _nameController,
                            hint: 'Full Name',
                            icon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 12),
                        ],
                        _buildTextField(
                          controller: _emailController,
                          hint: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: _passwordController,
                          hint: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: true,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 54,
                          child: FilledButton(
                            onPressed: _loading ? null : _handleEmailAuth,
                            style: FilledButton.styleFrom(
                              backgroundColor: roleAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Continue with Email' : 'Create Account',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppColors.textTertiary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : _handleGoogleAuth,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'G',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            label: Text(
                              'Continue with Google',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          children: [
                            Text(
                              _isLogin
                                  ? "Don't have an account?"
                                  : 'Already have an account?',
                              style: GoogleFonts.spaceGrotesk(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => setState(() {
                                      _isLogin = !_isLogin;
                                      _error = null;
                                    }),
                              child: Text(
                                _isLogin ? 'Create one' : 'Sign in',
                                style: GoogleFonts.spaceGrotesk(
                                  color: roleAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _loading
                              ? null
                              : () => Navigator.pushReplacementNamed(
                                    context,
                                    AppRouter.roleSelection,
                                  ),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back to role selection'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.spaceGrotesk(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.spaceGrotesk(
          color: AppColors.textTertiary,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.textTertiary,
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _AmbientBlob extends StatelessWidget {
  const _AmbientBlob({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}
