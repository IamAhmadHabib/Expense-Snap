import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class OnboardingPrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final Animation<double> pressAnimation;
  final VoidCallback onPressed;

  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.pressAnimation,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pressAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 - (0.02 * pressAnimation.value),
          child: child,
        );
      },
      child: Container(
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
          key: const ValueKey('onboarding_primary_cta'),
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            disabledForegroundColor: AppColors.textOnPrimary.withValues(
              alpha: 0.65,
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              label,
              key: ValueKey(label),
              style: AppTypography.label,
            ),
          ),
        ),
      ),
    );
  }
}
