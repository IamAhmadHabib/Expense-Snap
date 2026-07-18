import 'dart:math' as math;

import 'package:flutter/material.dart';

class OnboardingIllustrationTransition extends StatelessWidget {
  final Animation<double> animation;
  final int fromIndex;
  final int toIndex;
  final String fromAsset;
  final String toAsset;
  final String fromSemanticLabel;
  final String toSemanticLabel;
  final bool transitioning;
  final bool reducedMotion;

  const OnboardingIllustrationTransition({
    super.key,
    required this.animation,
    required this.fromIndex,
    required this.toIndex,
    required this.fromAsset,
    required this.toAsset,
    required this.fromSemanticLabel,
    required this.toSemanticLabel,
    required this.transitioning,
    required this.reducedMotion,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
          final cacheWidth = math.min(
            1254,
            math.max(1, (constraints.maxWidth * devicePixelRatio).round()),
          );

          if (!transitioning) {
            return _IllustrationImage(
              key: ValueKey('onboarding_illustration_$fromIndex'),
              asset: fromAsset,
              semanticLabel: fromSemanticLabel,
              cacheWidth: cacheWidth,
            );
          }

          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final progress = Curves.easeInOutCubic.transform(animation.value);
              if (reducedMotion) {
                return Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: 1 - progress,
                      child: _IllustrationImage(
                        key: ValueKey('onboarding_illustration_$fromIndex'),
                        asset: fromAsset,
                        semanticLabel: fromSemanticLabel,
                        cacheWidth: cacheWidth,
                      ),
                    ),
                    Opacity(
                      opacity: progress,
                      child: _IllustrationImage(
                        key: ValueKey('onboarding_illustration_$toIndex'),
                        asset: toAsset,
                        semanticLabel: toSemanticLabel,
                        cacheWidth: cacheWidth,
                      ),
                    ),
                  ],
                );
              }

              final outgoing = _interval(progress, 0, 0.65);
              final incoming = _interval(progress, 0.25, 1);
              return Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  _motionLayer(
                    opacity: 1 - outgoing,
                    horizontalFraction: -0.08 * outgoing,
                    verticalFraction: -0.02 * outgoing,
                    scale: 1 - (0.06 * outgoing),
                    turns: -0.012 * outgoing,
                    child: _IllustrationImage(
                      key: ValueKey('onboarding_illustration_$fromIndex'),
                      asset: fromAsset,
                      semanticLabel: fromSemanticLabel,
                      cacheWidth: cacheWidth,
                    ),
                  ),
                  _motionLayer(
                    opacity: incoming,
                    horizontalFraction: 0.08 * (1 - incoming),
                    verticalFraction: 0.02 * (1 - incoming),
                    scale: 1 + (0.04 * (1 - incoming)),
                    turns: 0.012 * (1 - incoming),
                    child: _IllustrationImage(
                      key: ValueKey('onboarding_illustration_$toIndex'),
                      asset: toAsset,
                      semanticLabel: toSemanticLabel,
                      cacheWidth: cacheWidth,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  static Widget _motionLayer({
    required double opacity,
    required double horizontalFraction,
    required double verticalFraction,
    required double scale,
    required double turns,
    required Widget child,
  }) {
    return Opacity(
      opacity: opacity.clamp(0, 1),
      child: FractionalTranslation(
        translation: Offset(horizontalFraction, verticalFraction),
        child: Transform.rotate(
          angle: turns * math.pi * 2,
          child: Transform.scale(scale: scale, child: child),
        ),
      ),
    );
  }

  static double _interval(double value, double begin, double end) {
    return ((value - begin) / (end - begin)).clamp(0, 1);
  }
}

class _IllustrationImage extends StatelessWidget {
  final String asset;
  final String semanticLabel;
  final int cacheWidth;

  const _IllustrationImage({
    super.key,
    required this.asset,
    required this.semanticLabel,
    required this.cacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      excludeSemantics: true,
      image: true,
      label: semanticLabel,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
        cacheWidth: cacheWidth,
        excludeFromSemantics: true,
      ),
    );
  }
}
