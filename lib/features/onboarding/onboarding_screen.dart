import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as Math;
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import 'illustrations/onboarding_illustration_1.dart';
import 'illustrations/onboarding_illustration_2.dart';
import 'illustrations/onboarding_illustration_3.dart';
import '../auth/auth_screen.dart';

/// Onboarding data model for each page.
class _OnboardingPage {
  final String title;
  final String subtitle;
  final Widget illustration;
  final bool isFinal;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.illustration,
    this.isFinal = false,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;

  // Animation controllers for text entrance effects
  late AnimationController _textAnimController;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: 'Track Every Rupee',
      subtitle: 'Speak, scan, or type — log expenses\nthe way you naturally think',
      illustration: OnboardingIllustration1(),
    ),
    _OnboardingPage(
      title: 'Spend. We\nHandle the Rest.',
      subtitle: 'Auto-sorted, auto-tagged, in any\nlanguage you speak',
      illustration: OnboardingIllustration2(),
    ),
    _OnboardingPage(
      title: 'Your Money,\nYour Story',
      subtitle: 'Get insights that actually make\nsense — written for you, not just charts',
      illustration: OnboardingIllustration3(),
      isFinal: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _textAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _textFadeAnimation = CurvedAnimation(
      parent: _textAnimController,
      curve: Curves.easeOut,
    );

    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textAnimController,
      curve: Curves.easeOutCubic,
    ));

    // Play initial animation
    _textAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textAnimController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    // Replay text entrance animation on page change
    _textAnimController.reset();
    _textAnimController.forward();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateToAuth();
    }
  }

  void _navigateToAuth() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthScreen(),
        transitionDuration: const Duration(milliseconds: 1400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return Stack(
            children: [
              // ── Phase 1: Radial Expansion (0.0 to 0.4) ──
              AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  double revealT = (animation.value / 0.4).clamp(0.0, 1.0);
                  return CustomPaint(
                    painter: _CircularRevealPainter(
                      fraction: revealT,
                      center: Offset(
                        MediaQuery.of(context).size.width / 2, 
                        MediaQuery.of(context).size.height - 100, 
                      ),
                      color: AppColors.primary,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),

              // ── Phase 2: Rising Sheet (0.4 to 1.0) ──
              AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final springCurve = CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0.4, 0.9, curve: Curves.easeOutQuart),
                  );

                  return Transform.translate(
                    offset: Offset(0.0, (1.0 - springCurve.value) * MediaQuery.of(context).size.height),
                    child: child,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _onSkip() {
    HapticFeedback.lightImpact();
    _navigateToAuth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                0,
                AppSpacing.screenHorizontal,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  _buildPageIndicators(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildContinueButton(),
                  const SizedBox(height: AppSpacing.md),
                  _buildSkipButton(),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: Center(
              child: page.illustration,
            ),
          ),
          Expanded(
            flex: 3,
            child: FadeTransition(
              opacity: _textFadeAnimation,
              child: SlideTransition(
                position: _textSlideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: AppTypography.h1,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      page.subtitle,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.65),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.dotActive : AppColors.dotInactive,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
        );
      }),
    );
  }

  Widget _buildContinueButton() {
    final isFinal = _pages[_currentPage].isFinal;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Text(
          isFinal ? 'Get Started' : 'Continue',
          style: AppTypography.label,
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return AnimatedOpacity(
      opacity: _currentPage < _pages.length - 1 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: _currentPage < _pages.length - 1 ? _onSkip : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            'Skip',
            style: AppTypography.label.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.6),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularRevealPainter extends CustomPainter {
  final double fraction;
  final Offset center;
  final Color color;

  _CircularRevealPainter({
    required this.fraction,
    required this.center,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fraction <= 0) return;

    final paint = Paint()..color = color;
    double maxRadius = Math.sqrt(size.width * size.width + size.height * size.height);
    canvas.drawCircle(center, maxRadius * fraction, paint);
  }

  @override
  bool shouldRepaint(covariant _CircularRevealPainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}
