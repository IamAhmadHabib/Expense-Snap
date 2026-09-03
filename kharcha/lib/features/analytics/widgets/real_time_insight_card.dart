import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../services/analytics_ai_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'insight_detail_sheet.dart';

class RealTimeInsightCard extends StatefulWidget {
  final FinancialInsight insight;
  final String currency;
  final Future<FinancialInsight> Function() onRegenerate;

  const RealTimeInsightCard({
    super.key,
    required this.insight,
    required this.currency,
    required this.onRegenerate,
  });

  @override
  State<RealTimeInsightCard> createState() => _RealTimeInsightCardState();
}

class _RealTimeInsightCardState extends State<RealTimeInsightCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  void _openDetailSheet() {
    InsightDetailSheet.show(
      context: context,
      insight: widget.insight,
      currency: widget.currency,
      onRegenerate: widget.onRegenerate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');
    final formattedSavings =
        '${widget.currency} ${currencyFormatter.format(widget.insight.potentialSavings.toInt())}';

    return GestureDetector(
      onTap: _openDetailSheet,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceDark,
              AppColors.headerCard,
            ],
          ),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.06),
              blurRadius: 32,
              spreadRadius: -4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Radial Ambient AI Glow (Top Right)
              Positioned(
                top: -30,
                right: -30,
                child: AnimatedBuilder(
                  animation: _sparkleController,
                  builder: (context, _) {
                    final double pulse = 0.8 + (_sparkleController.value * 0.4);
                    return Container(
                      width: 140 * pulse,
                      height: 140 * pulse,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Main Card Body
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: AI Chip + Status Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _sparkleController,
                                builder: (context, child) {
                                  final double scale =
                                      0.92 + (_sparkleController.value * 0.16);
                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(
                                          alpha: 0.18,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.accent.withValues(
                                            alpha: 0.35,
                                          ),
                                        ),
                                      ),
                                      child: Icon(
                                        PhosphorIcons.chartLineUp(
                                          PhosphorIconsStyle.bold,
                                        ),
                                        size: 15,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'FINANCIAL INSIGHT',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.surface.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            widget.insight.badgeText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Headline
                    Text(
                      widget.insight.headline,
                      style: AppTypography.h3.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Body
                    Text(
                      widget.insight.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.surface.withValues(alpha: 0.72),
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Bottom Row: Savings Pill & Action Prompt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (widget.insight.potentialSavings > 0)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.accent.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Save up to $formattedSavings',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Text(
                              'Action Plan',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.surface.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              PhosphorIcons.arrowRight(
                                PhosphorIconsStyle.bold,
                              ),
                              size: 12,
                              color: AppColors.surface.withValues(alpha: 0.9),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
