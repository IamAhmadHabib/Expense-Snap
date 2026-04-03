import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../theme/app_colors.dart';
import 'iphone_skeleton.dart';
/// Screen 2 Illustration: Phone + floating dots/cards sorting
class OnboardingIllustration2 extends StatefulWidget {
  const OnboardingIllustration2({super.key});

  @override
  State<OnboardingIllustration2> createState() => _OnboardingIllustration2State();
}

class _OnboardingIllustration2State extends State<OnboardingIllustration2>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 380,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ─── Phone Body ────────────────────────────
          Positioned(
            top: 20,
            child: _buildPhone(),
          ),

          // ─── Dotted Animated Lines ───────────────────
          Positioned.fill(
            child: CustomPaint(
              painter: _DashedLinesPainter(progress: _controller.value),
            ),
          ),

          // ─── Floating Category Bubbles ────────────────
          Positioned(
            left: -15, // Outward
            top: 40,
            child: _buildCategoryCircle(Icons.restaurant_menu_rounded, delay: 0.0),
          ),
          Positioned(
            right: -10, // Outward
            top: 70,
            child: _buildCategoryCircle(Icons.directions_car_rounded, delay: 0.2),
          ),
          Positioned(
            left: -5, // Outward
            bottom: 60,
            child: _buildCategoryCircle(Icons.directions_subway_rounded, delay: 0.4),
          ),
          Positioned(
            right: 0, // Outward
            bottom: 40,
            child: _buildCategoryCircle(Icons.shopping_bag_rounded, delay: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildPhone() {
    return IPhoneSkeleton(
      child: Column(
        children: [
          const SizedBox(height: 50),
          
          // App Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 50,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Animated Expense Cards drifting slightly
          Expanded(
            child: Stack(
              children: [
                Positioned(top: 10, left: 14, child: _buildExpenseTag('Rs. 200', 0.1, Icons.restaurant_menu_rounded)),
                Positioned(top: 65, right: 10, child: _buildExpenseTag('Rs. 150', 0.3, Icons.directions_car_rounded)),
                Positioned(top: 120, left: 35, child: _buildExpenseTag('Rs. 500', 0.5, Icons.directions_subway_rounded, true)), // Now matches Transit path
                Positioned(top: 175, right: 8, child: _buildExpenseTag('Rs. 120', 0.8, Icons.shopping_bag_rounded)), // Now matches Shopping path
                Positioned(top: 230, left: 12, child: _buildExpenseTag('Rs. 45', 0.9, Icons.restaurant_menu_rounded)),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildExpenseTag(String amount, double delay, IconData iconData, [bool isCenter = false]) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offsetY = math.sin((_controller.value + delay) * math.pi * 2) * 5;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCenter ? 14 : 10, 
              vertical: isCenter ? 10 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    iconData,
                    size: isCenter ? 16 : 14,
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(width: isCenter ? 10 : 8),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: isCenter ? 15 : 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryCircle(IconData icon, {required double delay}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offsetY = math.sin((_controller.value + delay) * math.pi * 2) * 6;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(icon, size: 24, color: AppColors.primary),
                ),
                // Tiny yellow notification dot on top right
                Positioned(
                  top: 0,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Paints dashed dotted lines going from the phone cards to the categories
class _DashedLinesPainter extends CustomPainter {
  final double progress;

  _DashedLinesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    void drawMovingDashes(Path path) {
      for (final metric in path.computeMetrics()) {
        final length = metric.length;
        double distance = -(progress * 24.0) % 12.0;
        
        while (distance < length) {
          if (distance >= 0 && distance < length - 8) {
            final tangent = metric.getTangentForOffset(distance);
            if (tangent != null) {
              canvas.drawCircle(tangent.position, 2.0, paint);
            }
          }
          distance += 12.0;
        }

        final endTangent = metric.getTangentForOffset(length - 4);
        if (endTangent != null) {
          _drawArrowhead(canvas, paint, endTangent);
        }
      }
    }

    // Adjusted paths for wider phone (170x340) positioned at top 20
    // Center of phone is X=160

    // 1. To Food
    final p1 = Path()
      ..moveTo(120, 120)
      ..quadraticBezierTo(80, 80, 55, 80);
    drawMovingDashes(p1);

    // 2. To Car
    final p2 = Path()
      ..moveTo(200, 180)
      ..quadraticBezierTo(250, 110, 270, 115);
    drawMovingDashes(p2);

    // 3. To Secondary Car/Transit
    final p3 = Path()
      ..moveTo(120, 280)
      ..quadraticBezierTo(80, 290, 60, 310);
    drawMovingDashes(p3);

    // 4. To Bag
    final p4 = Path()
      ..moveTo(210, 320)
      ..quadraticBezierTo(240, 320, 270, 310);
    drawMovingDashes(p4);
  }

  void _drawArrowhead(Canvas canvas, Paint paint, /*Tangent*/ dynamic tangent) {
    final Path arrowPath = Path();
    const double arrowSize = 6.0;
    
    canvas.save();
    canvas.translate(tangent.position.dx, tangent.position.dy);
    final double angle = math.atan2(tangent.vector.dy, tangent.vector.dx);
    canvas.rotate(angle);
    
    arrowPath.moveTo(arrowSize, 0); 
    arrowPath.lineTo(-arrowSize, arrowSize * 0.7);
    arrowPath.lineTo(-arrowSize * 0.4, 0);
    arrowPath.lineTo(-arrowSize, -arrowSize * 0.7);
    arrowPath.close();
    
    canvas.drawPath(arrowPath, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DashedLinesPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
