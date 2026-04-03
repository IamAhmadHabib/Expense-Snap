import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../theme/app_colors.dart';
import 'iphone_skeleton.dart';
/// Screen 3 Illustration: Phone showing monthly story + floating chart widgets
class OnboardingIllustration3 extends StatefulWidget {
  const OnboardingIllustration3({super.key});

  @override
  State<OnboardingIllustration3> createState() => _OnboardingIllustration3State();
}

class _OnboardingIllustration3State extends State<OnboardingIllustration3>
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

          // ─── Floating: Mini Line Chart (top-right) ─
          Positioned(
            right: -15, // Outward
            top: 60,
            child: _buildMiniLineChart(delay: 0.0),
          ),

          // ─── Floating: Mini Donut Chart (bottom-left) ─
          Positioned(
            left: -10, // Outward
            bottom: 40,
            child: _buildMiniDonutChart(delay: 0.4),
          ),

          // ─── Floating: Trend arrow (bottom-right) ──
          Positioned(
            right: -5, // Outward
            bottom: 60,
            child: _buildTrendCard(delay: 0.7),
          ),

          // ─── Floating: Calendar icon (top-left) ────
          Positioned(
            left: -5, // Outward
            top: 50,
            child: _buildFloatingMiniCard(
              icon: Icons.calendar_month_rounded,
              delay: 0.2,
            ),
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
          const SizedBox(height: 14),

          // Monthly Story Label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Monthly Story',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Skeleton text lines representing the story
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonLine(width: 120),
                const SizedBox(height: 6),
                _skeletonLine(width: 100),
                const SizedBox(height: 6),
                _skeletonLine(width: 115),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mini inline bar chart inside phone
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _miniBar(height: 20 + 6 * _controller.value),
                    const SizedBox(width: 5),
                    _miniBar(height: 30 + 4 * _controller.value),
                    const SizedBox(width: 5),
                    _miniBar(height: 16 + 8 * _controller.value),
                    const SizedBox(width: 5),
                    _miniBar(height: 26 + 3 * _controller.value),
                    const SizedBox(width: 5),
                    _miniBar(height: 12 + 5 * _controller.value),
                    const SizedBox(width: 5),
                    _miniBar(height: 24 + 7 * _controller.value),
                    const SizedBox(width: 5),
                    _miniBar(height: 18 + 4 * _controller.value),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // More skeleton lines
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonLine(width: 110),
                const SizedBox(height: 6),
                _skeletonLine(width: 80),
              ],
            ),
          ),

          const Spacer(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _skeletonLine({required double width}) {
    return Container(
      width: width,
      height: 5,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  Widget _miniBar({required double height}) {
    return Container(
      width: 10,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildMiniLineChart({double delay = 0}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offsetY = math.sin((_controller.value + delay) * math.pi) * 5;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Container(
            width: 76,
            height: 56,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _MiniLineChartPainter(progress: _controller.value),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniDonutChart({double delay = 0}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offsetY = math.sin((_controller.value + delay) * math.pi) * 5;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _MiniDonutPainter(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrendCard({double delay = 0}) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offsetY = math.sin((_controller.value + delay) * math.pi) * 5;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_down_rounded,
                  size: 18,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 5),
                Text(
                  '12%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingMiniCard({
    required IconData icon,
    double delay = 0,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offsetY = math.sin((_controller.value + delay) * math.pi) * 5;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, size: 20, color: AppColors.accent),
            ),
          ),
        );
      },
    );
  }
}

/// Paints a mini line chart with an upward trend
class _MiniLineChartPainter extends CustomPainter {
  final double progress;

  _MiniLineChartPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.2, size.height * 0.5),
      Offset(size.width * 0.4, size.height * 0.65),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.45),
      Offset(size.width, size.height * 0.15),
    ];

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final cp1x = (points[i - 1].dx + points[i].dx) / 2;
      path.cubicTo(
        cp1x, points[i - 1].dy,
        cp1x, points[i].dy,
        points[i].dx, points[i].dy,
      );
    }

    canvas.drawPath(path, paint);

    // Gradient fill below
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accent.withValues(alpha: 0.15),
          AppColors.accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniLineChartPainter oldDelegate) => false;
}

/// Paints a mini donut chart
class _MiniDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;
    const strokeWidth = 5.0;

    final segments = [
      (sweep: 2.2, color: AppColors.accent),
      (sweep: 1.5, color: AppColors.accent.withValues(alpha: 0.4)),
      (sweep: 1.2, color: AppColors.surfaceVariant),
      (sweep: 1.38, color: AppColors.accent.withValues(alpha: 0.2)),
    ];

    double startAngle = -math.pi / 2;
    for (final seg in segments) {
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        seg.sweep,
        false,
        paint,
      );
      startAngle += seg.sweep + 0.08;
    }
  }

  @override
  bool shouldRepaint(covariant _MiniDonutPainter oldDelegate) => false;
}
