import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../theme/app_colors.dart';
import 'iphone_skeleton.dart';

/// Screen 1 Illustration: Phone with voice waveform + sound waves + floating cards
class OnboardingIllustration1 extends StatefulWidget {
  const OnboardingIllustration1({super.key});

  @override
  State<OnboardingIllustration1> createState() => _OnboardingIllustration1State();
}

class _OnboardingIllustration1State extends State<OnboardingIllustration1>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
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
      height: 380, // Brought height down, matching screens 2 and 3
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ─── Sound Wave Arcs ────
          Positioned(
            top: -50,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(320, 240), // Increased height to prevent clipping
                  painter: _SoundWavePainter(
                    progress: _controller.value,
                  ),
                );
              },
            ),
          ),

          // ─── Phone Body (at top: 20 to match other screens) ─
          Positioned(
            top: 20,
            child: _buildPhone(),
          ),

          // ─── Floating Card: Receipt (bottom-left) ──
          Positioned(
            left: -10, // Moved further out
            bottom: 40,
            child: _buildFloatingCard(
              icon: Icons.receipt_long_rounded,
              angle: -0.1,
              delay: 0.0,
            ),
          ),

          // ─── Floating Card: Camera (top-right) ─────
          Positioned(
            right: -5, // Moved further out
            top: 80,
            child: _buildFloatingCard(
              icon: Icons.camera_alt_rounded,
              angle: 0.08,
              delay: 0.3,
            ),
          ),

          // ─── Floating Card: Keyboard (bottom-right) ─
          Positioned(
            right: 0, // Moved further out
            bottom: 30,
            child: _buildFloatingCard(
              icon: Icons.keyboard_rounded,
              angle: 0.12,
              delay: 0.6,
              size: 42,
              iconSize: 18,
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
          const SizedBox(height: 34), // Padding below notch
          
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
                  width: 45,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Animated Text Lines (simulating voice-to-text)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _textLine(width: 120, opacity: 1.0),
                    const SizedBox(height: 7),
                    _textLine(width: 100, opacity: 0.85),
                    const SizedBox(height: 7),
                    _textLine(width: 110, opacity: 0.65),
                    const SizedBox(height: 7),
                    _textLine(
                      width: 60 + 30 * _controller.value,
                      opacity: 0.3 + 0.4 * _controller.value,
                    ),
                    const SizedBox(height: 7),
                    _textLine(
                      width: 30 + 50 * _controller.value,
                      opacity: 0.15 + 0.3 * _controller.value,
                    ),
                    const SizedBox(height: 7),
                    _textLine(
                      width: 10 + 40 * _controller.value,
                      opacity: 0.05 + 0.2 * _controller.value,
                    ),
                  ],
                );
              },
            ),
          ),
          
          Expanded(child: SizedBox()), // Push everything else to the bottom
          
          // ─── Animated Waveform ─────────────────────
          SizedBox(
            width: 120,
            height: 36,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(120, 36),
                  painter: _WaveformPainter(
                    progress: _controller.value,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // ─── Microphone button (BELOW the waveform) ─
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mic_rounded,
              color: AppColors.accent,
              size: 26,
            ),
          ),
          const SizedBox(height: 24), // Above bottom indicator
        ],
      ),
    );
  }

  Widget _textLine({required double width, required double opacity}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08 + 0.12 * opacity),
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }

  Widget _buildFloatingCard({
    required IconData icon,
    double angle = 0,
    double delay = 0,
    double size = 48,
    double iconSize = 22,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final offsetY = math.sin((_controller.value + delay) * math.pi) * 6;
        return Transform.translate(
          offset: Offset(0, offsetY),
          child: Transform.rotate(
            angle: angle,
            child: Container(
              width: size,
              height: size,
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
                child: Icon(
                  icon,
                  size: iconSize,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Paints the animated sound wave arcs above the phone
class _SoundWavePainter extends CustomPainter {
  final double progress;

  _SoundWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Center behind the phone. Phone is at top: 20 in Stack. Paint is at top: -50.
    // So y=180 in canvas is stack y=130 (which is 110px down the phone body).
    final center = Offset(size.width / 2, 180);

    for (int i = 0; i < 6; i++) {
      final radius = 60.0 + (i * 28); // Larger gaps, bigger waves
      final opacity = (0.55 - (i * 0.07)).clamp(0.08, 0.55); // Higher opacity to be clearly visible
      final animatedOpacity =
          opacity * (0.6 + 0.4 * math.sin(progress * math.pi * 2 + i * 0.6));

      final paint = Paint()
        ..color = AppColors.accent.withValues(alpha: animatedOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi * 0.88,
        math.pi * 0.76,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SoundWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Paints the animated voice waveform inside the phone screen
class _WaveformPainter extends CustomPainter {
  final double progress;

  _WaveformPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    const barCount = 28;
    final barWidth = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      final normalizedI = i / barCount;

      final envelope = math.sin(normalizedI * math.pi);
      final wave =
          math.sin(normalizedI * math.pi * 4 + progress * math.pi * 2);
      final height = envelope * (8 + wave * 5);

      canvas.drawLine(
        Offset(x, centerY - height),
        Offset(x, centerY + height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
