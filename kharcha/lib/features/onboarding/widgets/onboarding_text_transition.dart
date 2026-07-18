import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class OnboardingTextTransition extends StatelessWidget {
  final Animation<double> animation;
  final String fromTitle;
  final String fromDescription;
  final String toTitle;
  final String toDescription;
  final bool transitioning;
  final bool reducedMotion;
  final bool compact;

  const OnboardingTextTransition({
    super.key,
    required this.animation,
    required this.fromTitle,
    required this.fromDescription,
    required this.toTitle,
    required this.toDescription,
    required this.transitioning,
    required this.reducedMotion,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    if (!transitioning) {
      return _TextContent(
        title: fromTitle,
        description: fromDescription,
        compact: compact,
      );
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = Curves.easeInOutCubic.transform(animation.value);
        final outgoing = reducedMotion ? progress : _interval(progress, 0, 0.4);
        final incoming = reducedMotion
            ? progress
            : _interval(progress, 0.35, 1);
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            _textLayer(
              opacity: 1 - outgoing,
              offset: reducedMotion
                  ? Offset.zero
                  : Offset(-20 * outgoing, -4 * outgoing),
              child: _TextContent(
                title: fromTitle,
                description: fromDescription,
                compact: compact,
              ),
            ),
            _textLayer(
              opacity: incoming,
              offset: reducedMotion
                  ? Offset.zero
                  : Offset(20 * (1 - incoming), 4 * (1 - incoming)),
              child: _TextContent(
                title: toTitle,
                description: toDescription,
                compact: compact,
              ),
            ),
          ],
        );
      },
    );
  }

  static Widget _textLayer({
    required double opacity,
    required Offset offset,
    required Widget child,
  }) {
    return Opacity(
      opacity: opacity.clamp(0, 1),
      child: Transform.translate(offset: offset, child: child),
    );
  }

  static double _interval(double value, double begin, double end) {
    return ((value - begin) / (end - begin)).clamp(0, 1);
  }
}

class _TextContent extends StatelessWidget {
  final String title;
  final String description;
  final bool compact;

  const _TextContent({
    required this.title,
    required this.description,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTypography.h1.copyWith(
      fontSize: compact ? 34 : 42,
      height: 1.12,
    );
    final descriptionStyle = AppTypography.body.copyWith(
      color: AppColors.textPrimary.withValues(alpha: 0.65),
      fontSize: compact ? 16 : 18,
      height: 1.45,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Align(
          alignment: Alignment.topCenter,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, textAlign: TextAlign.center, style: titleStyle),
                  SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: descriptionStyle,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
