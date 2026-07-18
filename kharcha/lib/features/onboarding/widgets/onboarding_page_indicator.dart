import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

class OnboardingPageIndicator extends StatelessWidget {
  final Animation<double> animation;
  final int pageCount;
  final int fromPage;
  final int toPage;
  final bool transitioning;

  const OnboardingPageIndicator({
    super.key,
    required this.animation,
    required this.pageCount,
    required this.fromPage,
    required this.toPage,
    required this.transitioning,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final activePage = transitioning && animation.value >= 0.5
            ? toPage
            : fromPage;
        return Semantics(
          label: 'Page ${activePage + 1} of $pageCount',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pageCount, (index) {
              final active = index == activePage;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(
                  key: ValueKey('onboarding_indicator_$index'),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.dotActive : AppColors.dotInactive,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
