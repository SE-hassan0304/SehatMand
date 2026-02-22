// lib/features/auth/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../providers/auth_provider.dart';
import '../providers/firebase_auth_stream_provider.dart';
import '../widgets/login_form.dart';
import '../widgets/signup_form.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showLogin = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Navigate to home when Firebase confirms sign-in
    ref.listen<AsyncValue<dynamic>>(firebaseAuthStreamProvider, (_, next) {
      next.whenData((user) {
        if (user != null && mounted) {
          context.go(AppRoutes.home);
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBrandHeader()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.15, end: 0, duration: 600.ms),
                  const SizedBox(height: 40),
                  _buildAuthCard(authState)
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 500.ms)
                      .slideY(
                          begin: 0.1, end: 0, delay: 300.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite, color: AppColors.white, size: 36),
        ),
        const SizedBox(height: 16),
        Text(AppStrings.appName,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            )),
        const SizedBox(height: 4),
        Text(AppStrings.tagline,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.charcoal.withOpacity(0.65),
            )),
      ],
    );
  }

  Widget _buildAuthCard(AuthState authState) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTabSwitcher(),
          if (authState.error != null) _buildErrorBanner(authState.error!),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) {
              final offset =
                  _showLogin ? const Offset(-1, 0) : const Offset(1, 0);
              return SlideTransition(
                position: Tween<Offset>(begin: offset, end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeInOut)),
                child: child,
              );
            },
            child: _showLogin
                ? LoginForm(
                    key: const ValueKey('login'),
                    onSwitchToSignup: _switchToSignup)
                : SignupForm(
                    key: const ValueKey('signup'),
                    onSwitchToLogin: _switchToLogin),
          ),
          _buildGoogleSignIn(authState),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
            color: AppColors.grey, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          _buildTab(AppStrings.login, _showLogin, _switchToLogin),
          _buildTab(AppStrings.signup, !_showLogin, _switchToSignup),
        ]),
      ),
    );
  }

  Widget _buildTab(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.white : AppColors.greyText,
                )),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(error,
                  style:
                      GoogleFonts.inter(fontSize: 13, color: AppColors.error))),
          GestureDetector(
            onTap: () => ref.read(authProvider.notifier).clearError(),
            child: const Icon(Icons.close, color: AppColors.error, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignIn(AuthState authState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.greyText)),
            ),
            const Expanded(child: Divider()),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: authState.isLoading
                  ? null
                  : () => ref.read(authProvider.notifier).signInWithGoogle(),
              icon: const SizedBox(
                width: 20,
                height: 20,
                child: Text('G',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4285F4),
                    ),
                    textAlign: TextAlign.center),
              ),
              label: Text(AppStrings.signInWithGoogle,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.charcoal,
                  )),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.greyMid),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _switchToLogin() {
    setState(() => _showLogin = true);
    ref.read(authProvider.notifier).clearError();
  }

  void _switchToSignup() {
    setState(() => _showLogin = false);
    ref.read(authProvider.notifier).clearError();
  }
}
