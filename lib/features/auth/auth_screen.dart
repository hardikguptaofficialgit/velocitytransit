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
  bool _showEmailForm = false;
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
    final roleIcon = _isDriverLogin
        ? Icons.directions_bus_rounded
        : Icons.person_pin_circle_rounded;
    final roleAccent = _isDriverLogin ? AppColors.textPrimary : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/mobileauthbg.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(roleIcon, roleAccent, roleLabel),
                        const SizedBox(height: 32),
                        if (_error != null) _buildErrorBanner(),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _showEmailForm
                              ? _buildEmailForm(roleAccent)
                              : _buildAuthOptions(roleAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(IconData icon, Color accent, String roleLabel) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: accent, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isLogin
                    ? 'Log in to your $roleLabel account'
                    : 'Sign up as a $roleLabel',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthOptions(Color roleAccent) {
    return Column(
      key: const ValueKey('options'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _handleGoogleAuth,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            icon: Image.asset(
              'assets/google_g_logo.png',
              width: 24,
              height: 24,
            ),
            label: Text(
              'Continue with Google',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _showEmailForm = true;
                _error = null;
              });
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.email_outlined, color: AppColors.textPrimary, size: 24),
            label: Text(
              'Continue with Email',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildBottomActions(roleAccent),
      ],
    );
  }

  Widget _buildEmailForm(Color roleAccent) {
    return Column(
      key: const ValueKey('email_form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _loading
                  ? null
                  : () {
                      setState(() {
                        _showEmailForm = false;
                        _error = null;
                      });
                    },
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              _isLogin ? 'Sign in with Email' : 'Register with Email',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (!_isLogin) ...[
          _buildTextField(
            controller: _nameController,
            hint: 'Full Name',
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
        ],
        _buildTextField(
          controller: _emailController,
          hint: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          hint: 'Password',
          icon: Icons.lock_outline_rounded,
          obscure: true,
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: _loading ? null : _handleEmailAuth,
            style: FilledButton.styleFrom(
              backgroundColor: roleAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    _isLogin ? 'Log In' : 'Create Account',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        _buildBottomActions(roleAccent),
      ],
    );
  }

  Widget _buildBottomActions(Color roleAccent) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isLogin ? "Don't have an account?" : 'Already have an account?',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _loading
                  ? null
                  : () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _error = null;
                      });
                    },
              child: Text(
                _isLogin ? 'Sign Up' : 'Log In',
                style: GoogleFonts.spaceGrotesk(
                  color: roleAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        InkWell(
          onTap: _loading
              ? null
              : () => Navigator.pushReplacementNamed(
                    context,
                    AppRouter.roleSelection,
                  ),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, color: AppColors.textTertiary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Change role',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
          fontSize: 15,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.textTertiary,
          size: 22,
        ),
        filled: true,
        fillColor: AppColors.backgroundLight.withValues(alpha: 0.5),
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
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }
}
