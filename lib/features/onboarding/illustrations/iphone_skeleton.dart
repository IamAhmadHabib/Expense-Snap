import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class IPhoneSkeleton extends StatelessWidget {
  final Widget child;

  const IPhoneSkeleton({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 184, // Slightly wider for more substantial side buttons
      height: 350,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left buttons (Mute, Volume Up, Volume Down)
          Positioned(
            left: 0,
            top: 60, // Modern Mute Switch position
            child: Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 95, // Balanced Volume Up
            child: Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 135, // Balanced Volume Down
            child: Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
              ),
            ),
          ),

          // Right button (Power/Action)
          Positioned(
            right: 0,
            top: 105, // Anatomically correct Power Button position
            child: Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
              ),
            ),
          ),

          // Phone Body
          Positioned(
            left: 4,
            right: 4,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(42), // Deeper premium squircle
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.95),
                  width: 5.5, // Thicker high-end bezel
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Inner App Content
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0), // Creates an optical gap between frame and content
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(36), // Balanced with outer 42
                        child: child,
                      ),
                    ),
                  ),

                  // Modern Dynamic Island (iPhone 17 style)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.only(top: 14), // Floating island position
                      width: 58,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.95), // Deep Charcoal Island
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Small Sensor
                          Container(
                            width: 14,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Front Camera Lens
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: const RadialGradient(
                                colors: [
                                  Color(0xFF1B2F45), // Deep lens color
                                  Color(0xFF0D1821),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.surface.withValues(alpha: 0.05),
                                width: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Home Indicator
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: 55,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
