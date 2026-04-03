import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'login_screen.dart';
import '../onboarding/personalization_flow.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    // Play the entrance animation immediately
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Animation<double> _getStaggerAnim(double start, double end) {
    return CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _getSlideAnim(double start, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: Interval(start, end, curve: Curves.easeOutQuart),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // ─── Staggered Animation Intervals (700ms - 1000ms range) ───
    final logoFade = _getStaggerAnim(0.0, 0.3); // Map to the last 30% of global t
    final logoSlide = _getSlideAnim(0.0, 0.3);

    final titleFade = _getStaggerAnim(0.1, 0.4);
    final titleSlide = _getSlideAnim(0.1, 0.4);

    final buttonsFade = _getStaggerAnim(0.2, 0.6);
    final buttonsSlide = _getSlideAnim(0.2, 0.6);

    final footerFade = _getStaggerAnim(0.4, 0.8);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
          child: Column(
            children: [
              const Spacer(flex: 2),
              
              // ─── App Logo & Branding (Staggered) ─────
              FadeTransition(
                opacity: logoFade,
                child: SlideTransition(
                  position: logoSlide,
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.account_balance_wallet_rounded,
                              color: AppColors.textOnPrimary,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              
              FadeTransition(
                opacity: titleFade,
                child: SlideTransition(
                  position: titleSlide,
                  child: Column(
                    children: [
                      Text(
                        'Kharcha',
                        style: AppTypography.h1.copyWith(letterSpacing: -2.0),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Quiet luxury for your finances.',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // ─── Social Logins (Staggered) ─────────
              FadeTransition(
                opacity: buttonsFade,
                child: SlideTransition(
                  position: buttonsSlide,
                  child: Column(
                    children: [
                      _buildSocialButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PersonalizationFlow()),
                          );
                        },
                        logo: Image.asset('assets/images/google_logo.png', width: 24),
                        label: 'Continue with Google',
                        customBgColor: Colors.black,
                        customTextColor: Colors.white,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildSocialButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PersonalizationFlow()),
                          );
                        },
                        icon: Icons.apple_rounded,
                        label: 'Continue with Apple',
                        customBgColor: Colors.black,
                        customTextColor: Colors.white,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildSocialButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PersonalizationFlow()),
                          );
                        },
                        icon: Icons.email_outlined,
                        label: 'Continue with Email',
                        isOutlined: true,
                        isSmall: true,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // ─── Bottom Toggle (Staggered Footer) ──
              FadeTransition(
                opacity: footerFade,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTypography.bodySmall,
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: Text(
                          'Log in',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    IconData? icon,
    Widget? logo,
    required String label,
    Color? customBgColor,
    Color? customTextColor,
    bool isOutlined = false,
    bool isSmall = false,
  }) {
    final backgroundColor = customBgColor ?? (isOutlined ? Colors.transparent : AppColors.surface);
    final foregroundColor = customTextColor ?? AppColors.textPrimary;

    return Container(
      width: double.infinity,
      height: isSmall ? 52 : 58,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: isOutlined 
          ? Border.all(color: Colors.black, width: 1.5)
          : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact(); // Consistent haptics
            onPressed(); // Execute the passed navigation
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          splashColor: foregroundColor.withValues(alpha: 0.1),
          highlightColor: foregroundColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (logo != null) logo else if (icon != null) Icon(icon, color: foregroundColor, size: isSmall ? 20 : 24),
                const SizedBox(width: AppSpacing.md),
                Text(
                  label,
                  style: isSmall 
                    ? AppTypography.label.copyWith(color: foregroundColor, fontSize: 14)
                    : AppTypography.label.copyWith(color: foregroundColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
