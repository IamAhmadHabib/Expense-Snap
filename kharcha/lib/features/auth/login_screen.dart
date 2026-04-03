import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Animation<double> _stagger(double start, double end) {
    return CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _slide(double start, double end) {
    return Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOutQuart),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              
              // ─── Header ────────────────────────────
              FadeTransition(
                opacity: _stagger(0.0, 0.3),
                child: SlideTransition(
                  position: _slide(0.0, 0.3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome Back', style: AppTypography.h1.copyWith(letterSpacing: -1.5)),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Log in to your account',
                        style: AppTypography.body.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxl),

              // ─── Email Field ───────────────────────
              FadeTransition(
                opacity: _stagger(0.1, 0.4),
                child: SlideTransition(
                  position: _slide(0.1, 0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Email Address'),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'name@example.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // ─── Password Field ────────────────────
              FadeTransition(
                opacity: _stagger(0.2, 0.5),
                child: SlideTransition(
                  position: _slide(0.2, 0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Password'),
                      _buildTextField(
                        controller: _passwordController,
                        hintText: '••••••••',
                        isPassword: true,
                        isPasswordVisible: _isPasswordVisible,
                        onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        prefixIcon: Icons.lock_outline_rounded,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'Forgot Password?',
                            style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ─── Login Button ──────────────────────
              FadeTransition(
                opacity: _stagger(0.3, 0.6),
                child: SlideTransition(
                  position: _slide(0.3, 0.6),
                  child: _buildLoginButton(),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ─── Social Divider ────────────────────
              FadeTransition(
                opacity: _stagger(0.4, 0.7),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.primary.withValues(alpha: 0.1))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text('or log in with', style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                    ),
                    Expanded(child: Divider(color: AppColors.primary.withValues(alpha: 0.1))),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ─── Social Logins (With Labels & Correct Styling) ─
              FadeTransition(
                opacity: _stagger(0.5, 0.8),
                child: SlideTransition(
                  position: _slide(0.5, 0.8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          logo: Image.asset('assets/images/google_logo.png', width: 24),
                          label: 'Google',
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildSocialButton(
                          icon: Icons.apple_rounded,
                          label: 'Apple',
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.textPrimary.withValues(alpha: 0.8),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    required IconData prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.3), // Warm off-white tint
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl), // Match main rounded style
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        keyboardType: keyboardType,
        style: AppTypography.body.copyWith(fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.body.copyWith(
            color: AppColors.textTertiary,
            fontSize: 16,
          ),
          prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.05)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            borderSide: const BorderSide(color: Colors.black, width: 1.5), // High-contrast black focus
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Center(
            child: Text(
              'Log In',
              style: AppTypography.label,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    IconData? icon,
    Widget? logo,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl), // Match main button rounding
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)), // Refined warm stroke
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              logo ?? Icon(icon, size: 26, color: AppColors.textPrimary), // Upscaled apple to match google footprint
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
