import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../services/analytics_ai_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../utils/category_utils.dart';

class InsightDetailSheet extends StatefulWidget {
  final FinancialInsight insight;
  final String currency;
  final Future<FinancialInsight> Function() onRegenerate;

  const InsightDetailSheet({
    super.key,
    required this.insight,
    required this.currency,
    required this.onRegenerate,
  });

  static Future<void> show({
    required BuildContext context,
    required FinancialInsight insight,
    required String currency,
    required Future<FinancialInsight> Function() onRegenerate,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InsightDetailSheet(
        insight: insight,
        currency: currency,
        onRegenerate: onRegenerate,
      ),
    );
  }

  @override
  State<InsightDetailSheet> createState() => _InsightDetailSheetState();
}

class _InsightDetailSheetState extends State<InsightDetailSheet> {
  late FinancialInsight _currentInsight;
  bool _isRegenerating = false;
  final Set<int> _completedTips = {};

  @override
  void initState() {
    super.initState();
    _currentInsight = widget.insight;
  }

  Future<void> _handleRegenerate() async {
    if (_isRegenerating) return;
    HapticFeedback.lightImpact();
    setState(() => _isRegenerating = true);
    try {
      final updated = await widget.onRegenerate();
      if (mounted) {
        setState(() {
          _currentInsight = updated;
          _isRegenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRegenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,###');
    final formattedSavings = '${widget.currency} ${currencyFormatter.format(_currentInsight.potentialSavings.toInt())}';
    final hasCategory = _currentInsight.topCategory != 'None';
    final categoryStyle = hasCategory ? CategoryUtils.style(_currentInsight.topCategory) : null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Scrollable Content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Icon(
                              PhosphorIcons.chartLineUp(PhosphorIconsStyle.bold),
                              size: 18,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Financial Diagnosis',
                                style: AppTypography.h3.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Real-time Spending Analysis',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.profileDivider.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(
                            PhosphorIcons.x(PhosphorIconsStyle.bold),
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Hero Savings Highlight Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.surfaceDark, AppColors.backgroundDark],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.accent.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                _currentInsight.badgeText,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (_currentInsight.potentialSavings > 0)
                              Text(
                                'Identified Opportunity',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.surface.withValues(alpha: 0.45),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _currentInsight.potentialSavings > 0
                              ? formattedSavings
                              : 'Healthy Cash Flow',
                          style: AppTypography.h1.copyWith(
                            color: AppColors.surface,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentInsight.headline,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.surface.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Diagnosis Explanation
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.profileDivider.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.chartLineUp(PhosphorIconsStyle.bold),
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Spending Breakdown',
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _currentInsight.body,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary.withValues(alpha: 0.75),
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (hasCategory && categoryStyle != null) ...[
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: AppColors.profileDivider),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: categoryStyle.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    categoryStyle.icon,
                                    size: 16,
                                    color: categoryStyle.foreground,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _currentInsight.topCategory,
                                          style: AppTypography.caption.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Text(
                                          '${widget.currency} ${currencyFormatter.format(_currentInsight.topCategorySpend.toInt())} (${_currentInsight.topCategoryPercentage.toStringAsFixed(0)}%)',
                                          style: AppTypography.caption.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (_currentInsight.topCategoryPercentage / 100).clamp(0.0, 1.0),
                                        backgroundColor: AppColors.surfaceVariant,
                                        valueColor: AlwaysStoppedAnimation(categoryStyle.foreground),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Plan
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                        size: 18,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Personalized Action Plan',
                        style: AppTypography.h3.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._currentInsight.actionableTips.asMap().entries.map((entry) {
                    final index = entry.key;
                    final tip = entry.value;
                    final isChecked = _completedTips.contains(index);

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (isChecked) {
                            _completedTips.remove(index);
                          } else {
                            _completedTips.add(index);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isChecked
                              ? AppColors.success.withValues(alpha: 0.08)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isChecked
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.profileDivider.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isChecked ? AppColors.success : Colors.transparent,
                                border: Border.all(
                                  color: isChecked ? AppColors.success : AppColors.primary.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: isChecked
                                  ? const Icon(Icons.check, size: 14, color: AppColors.surface)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                tip,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isChecked
                                      ? AppColors.primary.withValues(alpha: 0.5)
                                      : AppColors.primary,
                                  decoration: isChecked ? TextDecoration.lineThrough : null,
                                  fontWeight: isChecked ? FontWeight.w500 : FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 18),

                  // Regenerate Button
                  GestureDetector(
                    onTap: _isRegenerating ? null : _handleRegenerate,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: _isRegenerating
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(AppColors.accent),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Updating Analysis...',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    PhosphorIcons.arrowsClockwise(PhosphorIconsStyle.bold),
                                    size: 16,
                                    color: AppColors.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Refresh Analysis',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
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
