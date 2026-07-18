import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../auth/auth_screen.dart';
import 'widgets/onboarding_illustration_transition.dart';
import 'widgets/onboarding_page_indicator.dart';
import 'widgets/onboarding_primary_button.dart';
import 'widgets/onboarding_text_transition.dart';

class _OnboardingPage {
  final String title;
  final String description;
  final String illustrationAsset;
  final String semanticLabel;

  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.illustrationAsset,
    required this.semanticLabel,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  static const _transitionDuration = Duration(milliseconds: 900);
  static const _reducedMotionDuration = Duration(milliseconds: 180);

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: 'Track Every Expense',
      description:
          'Speak, scan, or type — log expenses the way you naturally think',
      illustrationAsset: 'assets/images/onboarding/onboarding_capture.png',
      semanticLabel:
          'Expense entry methods including voice, camera, receipt, and keyboard',
    ),
    _OnboardingPage(
      title: 'Spend. We Handle the Rest.',
      description: 'Auto-sorted, auto-tagged, in any language you speak',
      illustrationAsset: 'assets/images/onboarding/onboarding_insights.png',
      semanticLabel: 'Expenses automatically organized into categories',
    ),
    _OnboardingPage(
      title: 'Your Money, Your Story',
      description:
          'Get insights that actually make sense written for you, not just charts',
      illustrationAsset: 'assets/images/onboarding/onboarding_categories.png',
      semanticLabel: 'Monthly financial insights and spending trends',
    ),
  ];

  late final AnimationController _transitionController;
  late final AnimationController _ctaController;

  int _currentPage = 0;
  int _fromPage = 0;
  int _toPage = 0;
  bool _isTransitioning = false;
  bool _imagesPrecached = false;
  double _horizontalDragDistance = 0;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: _transitionDuration,
    )..addStatusListener(_handleTransitionStatus);
    _ctaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 90),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imagesPrecached) return;
    _imagesPrecached = true;
    for (final page in _pages) {
      precacheImage(AssetImage(page.illustrationAsset), context);
    }
  }

  @override
  void dispose() {
    _transitionController
      ..removeStatusListener(_handleTransitionStatus)
      ..dispose();
    _ctaController.dispose();
    super.dispose();
  }

  void _handleTransitionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_isTransitioning || !mounted) {
      return;
    }
    setState(() {
      _currentPage = _toPage;
      _fromPage = _toPage;
      _isTransitioning = false;
    });
  }

  void _transitionTo(int targetPage) {
    if (_isTransitioning ||
        targetPage == _currentPage ||
        targetPage < 0 ||
        targetPage >= _pages.length) {
      return;
    }

    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    _transitionController.duration = reducedMotion
        ? _reducedMotionDuration
        : _transitionDuration;
    setState(() {
      _fromPage = _currentPage;
      _toPage = targetPage;
      _isTransitioning = true;
    });
    _transitionController.forward(from: 0);
  }

  void _onPrimaryPressed() {
    if (_isTransitioning) return;
    HapticFeedback.lightImpact();
    _ctaController.forward(from: 0).then((_) {
      if (mounted) _ctaController.reverse();
    });

    if (_currentPage == _pages.length - 1) {
      _navigateToAuth();
    } else {
      _transitionTo(_currentPage + 1);
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _horizontalDragDistance = 0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isTransitioning) return;
    _horizontalDragDistance += details.delta.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isTransitioning) return;
    final velocity = details.primaryVelocity ?? 0;
    final shouldMoveForward = velocity < -150 || _horizontalDragDistance < -60;
    final shouldMoveBackward = velocity > 150 || _horizontalDragDistance > 60;
    _horizontalDragDistance = 0;

    if (shouldMoveForward) {
      _transitionTo(_currentPage + 1);
    } else if (shouldMoveBackward) {
      _transitionTo(_currentPage - 1);
    }
  }

  void _onSkip() {
    if (_isTransitioning) return;
    HapticFeedback.lightImpact();
    _navigateToAuth();
  }

  void _navigateToAuth() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AuthScreen(),
        transitionDuration: const Duration(milliseconds: 1400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return Stack(
            children: [
              AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final revealT = (animation.value / 0.4).clamp(0.0, 1.0);
                  return CustomPaint(
                    painter: _CircularRevealPainter(
                      fraction: revealT,
                      center: Offset(
                        MediaQuery.sizeOf(context).width / 2,
                        MediaQuery.sizeOf(context).height - 100,
                      ),
                      color: AppColors.primary,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
              AnimatedBuilder(
                animation: animation,
                builder: (context, _) {
                  final springCurve = CurvedAnimation(
                    parent: animation,
                    curve: const Interval(0.4, 0.9, curve: Curves.easeOutQuart),
                  );
                  return Transform.translate(
                    offset: Offset(
                      0,
                      (1 - springCurve.value) *
                          MediaQuery.sizeOf(context).height,
                    ),
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

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final fromPage = _pages[_fromPage];
    final toPage = _pages[_toPage];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final illustrationRatio = availableHeight < 700
                ? 0.37
                : availableHeight > 880
                ? 0.46
                : 0.43;
            final illustrationHeight = (availableHeight * illustrationRatio)
                .clamp(220.0, 430.0);
            final compact = availableHeight < 700;

            return GestureDetector(
              key: const ValueKey('onboarding_gesture_surface'),
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: illustrationHeight,
                      child: OnboardingIllustrationTransition(
                        animation: _transitionController,
                        fromIndex: _fromPage,
                        toIndex: _toPage,
                        fromAsset: fromPage.illustrationAsset,
                        toAsset: toPage.illustrationAsset,
                        fromSemanticLabel: fromPage.semanticLabel,
                        toSemanticLabel: toPage.semanticLabel,
                        transitioning: _isTransitioning,
                        reducedMotion: reducedMotion,
                      ),
                    ),
                    SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: compact ? 12 : 24),
                        child: OnboardingTextTransition(
                          animation: _transitionController,
                          fromTitle: fromPage.title,
                          fromDescription: fromPage.description,
                          toTitle: toPage.title,
                          toDescription: toPage.description,
                          transitioning: _isTransitioning,
                          reducedMotion: reducedMotion,
                          compact: compact,
                        ),
                      ),
                    ),
                    OnboardingPageIndicator(
                      animation: _transitionController,
                      pageCount: _pages.length,
                      fromPage: _fromPage,
                      toPage: _toPage,
                      transitioning: _isTransitioning,
                    ),
                    SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
                    OnboardingPrimaryButton(
                      label: _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Continue',
                      enabled: !_isTransitioning,
                      pressAnimation: _ctaController,
                      onPressed: _onPrimaryPressed,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 48,
                      child: IgnorePointer(
                        ignoring:
                            _currentPage == _pages.length - 1 ||
                            _isTransitioning,
                        child: AnimatedOpacity(
                          opacity: _currentPage < _pages.length - 1 ? 1 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: TextButton(
                            onPressed: _currentPage < _pages.length - 1
                                ? _onSkip
                                : null,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(64, 48),
                              foregroundColor: AppColors.textPrimary.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            child: Text(
                              'Skip',
                              style: AppTypography.label.copyWith(
                                color: AppColors.textPrimary.withValues(
                                  alpha: 0.6,
                                ),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CircularRevealPainter extends CustomPainter {
  final double fraction;
  final Offset center;
  final Color color;

  const _CircularRevealPainter({
    required this.fraction,
    required this.center,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fraction <= 0) return;
    final paint = Paint()..color = color;
    final maxRadius = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    canvas.drawCircle(center, maxRadius * fraction, paint);
  }

  @override
  bool shouldRepaint(covariant _CircularRevealPainter oldDelegate) {
    return oldDelegate.fraction != fraction ||
        oldDelegate.center != center ||
        oldDelegate.color != color;
  }
}
