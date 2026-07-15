import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:kharcha/theme/app_colors.dart';
import 'package:kharcha/theme/app_spacing.dart';
import 'package:kharcha/theme/app_typography.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class AnalyticsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(bool)? onToggleOverlay;
  const AnalyticsScreen({super.key, this.onBack, this.onToggleOverlay});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  String _selectedPeriod = 'Days';
  int _selectedActivityIndex = -1;
  String _matrixMonthLabel = 'APR 2026';
  bool _isBooksOpen = false;
  late AnimationController _entranceController;
  late AnimationController _booksController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _booksController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _booksController.dispose();
    super.dispose();
  }

  // --- Mock Data Helpers ---

  List<FlSpot> _getLineChartSpots() {
    switch (_selectedPeriod) {
      case 'Days':
        return [
          const FlSpot(0, 1.2),
          const FlSpot(4, 2.5),
          const FlSpot(8, 1.8),
          const FlSpot(12, 3.2),
          const FlSpot(16, 2.7),
          const FlSpot(20, 4.5),
          const FlSpot(24, 3.8),
        ];
      case 'Weeks':
        return [
          const FlSpot(0, 8),
          const FlSpot(1, 12),
          const FlSpot(2, 7.5),
          const FlSpot(3, 15),
        ];
      case 'Months':
        return [
          const FlSpot(0, 35),
          const FlSpot(1, 42),
          const FlSpot(2, 38),
          const FlSpot(3, 50),
          const FlSpot(4, 45),
          const FlSpot(5, 55),
        ];
      default:
        return [];
    }
  }

  double _getMaxY() {
    final spots = _getLineChartSpots();
    if (spots.isEmpty) return 100;
    double maxVal = spots.map((e) => e.y).reduce(math.max);

    // Auto-adjust scale: slightly above max value
    if (maxVal < 1) return 1.5;
    if (maxVal < 10) return (maxVal * 1.3).ceilToDouble();
    return (maxVal * 1.25).ceilToDouble();
  }

  String _getXAxisLabel(double value) {
    if (_selectedPeriod == 'Days') {
      int hour = value.toInt();
      if (hour % 6 != 0) return '';
      return '$hour:00';
    } else if (_selectedPeriod == 'Weeks') {
      int week = value.toInt() + 1;
      return 'W$week';
    } else {
      List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
      int idx = value.toInt();
      if (idx >= 0 && idx < months.length) return months[idx];
      return '';
    }
  }

  String _getAverageSpendingText() {
    double avg = 0;
    final spots = _getLineChartSpots();
    if (spots.isNotEmpty) {
      avg = spots.map((e) => e.y).reduce((a, b) => a + b) / spots.length;
    }

    double actualValue = avg * 1000;
    if (actualValue < 1000) {
      return 'Rs. ${actualValue.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
    return 'Rs. ${(actualValue / 1000).toStringAsFixed(1)}k';
  }

  String _getYAxisLabel(double value) {
    if (value == 0) return '';

    if (_selectedPeriod == 'Days') {
      // For Days, we use 1.0 = Rs. 1000
      double actualValue = value * 1000;
      if (actualValue < 1000) return '${actualValue.toInt()}';
      return '${(actualValue / 1000).toStringAsFixed(1)}k';
    }

    // For Weeks/Months, we use 1 = Rs. 1000
    if (value < 1) return '${(value * 1000).toInt()}';
    return '${value.toInt()}k';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.md,
                  AppSpacing.screenHorizontal,
                  140,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildPeriodSelector(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildMainTrendChart(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildDistributionRow(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildHeatmapSection(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildFloatingInsight(),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
            if (_isBooksOpen) _buildBooksOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (widget.onBack != null)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onBack?.call();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    PhosphorIcons.caretLeft(PhosphorIconsStyle.bold),
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            if (widget.onBack != null) const SizedBox(width: 16),
            Text(
              'Insights',
              style: AppTypography.h2.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EDE8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: ['Days', 'Weeks', 'Months'].map((period) {
          final label = period == 'Days'
              ? 'Today'
              : (period == 'Weeks' ? 'Monthly' : 'Yearly');
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedPeriod = period;
                  _selectedActivityIndex = -1;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainTrendChart() {
    final spots = _getLineChartSpots();
    final maxY = _getMaxY();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 24, 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average Spending',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.surface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getAverageSpendingText(),
                      style: AppTypography.h2.copyWith(
                        color: AppColors.surface,
                        fontSize: 32,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        PhosphorIcons.trendUp(PhosphorIconsStyle.bold),
                        color: AppColors.accent,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+4.2%',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180, // More compact height for the chart
            child: LineChart(
              key: ValueKey(
                _selectedPeriod,
              ), // Ensures state is reset when period changes to avoid RangeErrors
              LineChartData(
                minX: 0,
                maxX: _selectedPeriod == 'Days'
                    ? 24
                    : (_selectedPeriod == 'Weeks' ? 3 : 5),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: maxY / 4,
                  verticalInterval: _selectedPeriod == 'Days' ? 6 : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.surface.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: AppColors.surface.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: _selectedPeriod == 'Days' ? 6 : 1,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            _getXAxisLabel(value),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.surface.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _getYAxisLabel(value),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.surface.withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 35,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, Color(0xFFF5DEB3)],
                    ),
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: AppColors.accent,
                          ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.2),
                          AppColors.accent.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        AppColors.primary.withValues(alpha: 0.8),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final flSpot = barSpot;
                        double val = _selectedPeriod == 'Days'
                            ? flSpot.y * 1000
                            : flSpot.y * 1000;
                        String formatted = val < 1000
                            ? '${val.toInt()}'
                            : '${(val / 1000).toStringAsFixed(1)}k';
                        return LineTooltipItem(
                          'Rs. $formatted',
                          AppTypography.bodySmall.copyWith(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCategoryData() {
    switch (_selectedPeriod) {
      case 'Days':
        return {
          'total': 'Rs. 2,450',
          'items': [
            {
              'label': 'Food',
              'amount': 'Rs. 1,200',
              'value': 0.65,
              'color': AppColors.accent,
            },
            {
              'label': 'Travel',
              'amount': 'Rs. 850',
              'value': 0.45,
              'color': const Color(0xFF908D89),
            },
            {
              'label': 'Shopping',
              'amount': 'Rs. 400',
              'value': 0.25,
              'color': const Color(0xFF4A4A4A),
            },
            {
              'label': 'Health',
              'amount': 'Rs. 0',
              'value': 0.08,
              'color': AppColors.primary,
            },
          ],
        };
      case 'Weeks': // Monthly
        return {
          'total': 'Rs. 70.1k',
          'items': [
            {
              'label': 'Housing',
              'amount': 'Rs. 45k',
              'value': 0.85,
              'color': AppColors.primary,
            },
            {
              'label': 'Food',
              'amount': 'Rs. 12.4k',
              'value': 0.65,
              'color': AppColors.accent,
            },
            {
              'label': 'Shopping',
              'amount': 'Rs. 8.2k',
              'value': 0.45,
              'color': const Color(0xFF4A4A4A),
            },
            {
              'label': 'Travel',
              'amount': 'Rs. 4.5k',
              'value': 0.25,
              'color': const Color(0xFF908D89),
            },
          ],
        };
      case 'Months': // Yearly
        return {
          'total': 'Rs. 840k',
          'items': [
            {
              'label': 'Housing',
              'amount': 'Rs. 540k',
              'value': 0.92,
              'color': AppColors.primary,
            },
            {
              'label': 'Invest',
              'amount': 'Rs. 120k',
              'value': 0.75,
              'color': AppColors.accent,
            },
            {
              'label': 'Lifestyle',
              'amount': 'Rs. 95k',
              'value': 0.55,
              'color': const Color(0xFF4A4A4A),
            },
            {
              'label': 'Health',
              'amount': 'Rs. 85k',
              'value': 0.35,
              'color': const Color(0xFF908D89),
            },
          ],
        };
      default:
        return {};
    }
  }

  Widget _buildDistributionRow() {
    final catData = _getCategoryData();
    final items = catData['items'] as List<Map<String, dynamic>>;

    return Column(
      children: [
        // 1. By Category (Full Width)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.profileDivider.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.02),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'By Category',
                    style: AppTypography.h3.copyWith(fontSize: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Expenditure',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary.withValues(alpha: 0.3),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        catData['total'],
                        style: AppTypography.h3.copyWith(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  // Radial Chart
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: CustomPaint(
                      painter: RadialBarPainter(
                        values: items.map((e) => e['value'] as double).toList(),
                        colors: items.map((e) => e['color'] as Color).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  // Legend
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _categoryLegendItem(
                            item['color'] as Color,
                            item['label'] as String,
                            item['amount'] as String,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // 2. Active Stat (Option 2: Inset Spotlight)
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
          },
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.profileDivider.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Spotlight Sidebar
                  Container(
                    width: 64,
                    color: AppColors.primary,
                    child: Center(
                      child: Icon(
                        _selectedPeriod == 'Days'
                            ? PhosphorIcons.lightning(PhosphorIconsStyle.fill)
                            : (_selectedPeriod == 'Weeks'
                                  ? PhosphorIcons.sparkle(
                                      PhosphorIconsStyle.fill,
                                    )
                                  : PhosphorIcons.trophy(
                                      PhosphorIconsStyle.fill,
                                    )),
                        color: AppColors.surface,
                        size: 26, // Slightly larger for impact
                      ),
                    ),
                  ),
                  // Details Section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Stat',
                                style: AppTypography.h3.copyWith(
                                  fontSize: 14,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedPeriod == 'Days'
                                    ? 'Peak Hour'
                                    : (_selectedPeriod == 'Weeks'
                                          ? 'Peak Day'
                                          : 'Peak Month'),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.6,
                                  ),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _selectedPeriod == 'Days'
                                    ? '14:00'
                                    : (_selectedPeriod == 'Weeks'
                                          ? 'Friday'
                                          : 'April'),
                                style: AppTypography.h2.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                ),
                              ),
                              Text(
                                _selectedPeriod == 'Days'
                                    ? 'Rs. 950'
                                    : (_selectedPeriod == 'Weeks'
                                          ? 'Rs. 8.4k'
                                          : 'Rs. 45k'),
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryLegendItem(Color color, String label, String amount) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12), // Minimum gap to prevent "merging"
        Text(
          amount,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.primary.withValues(alpha: 0.5),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _categoryDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapSection() {
    final matrixWidget = Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 40),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                  return SizedBox(
                    width: 28,
                    child: Center(
                      child: Text(
                        day,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(4, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    'W${weekIndex + 1}',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (dayIndex) {
                      final idx = weekIndex * 7 + dayIndex;
                      final intensity = math.Random(
                        idx + _matrixMonthLabel.hashCode,
                      ).nextDouble();
                      final isSelected = _selectedActivityIndex == idx;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(
                            () =>
                                _selectedActivityIndex = isSelected ? -1 : idx,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.primary.withValues(
                                    alpha: intensity * 0.8 + 0.05,
                                  ),
                            borderRadius: BorderRadius.circular(6),
                            border: isSelected
                                ? Border.all(color: AppColors.accent, width: 2)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );

    final detailWidget = _selectedActivityIndex != -1
        ? Text(
            'Day ${_selectedActivityIndex + 1}: Rs. ${(math.Random(_selectedActivityIndex + _matrixMonthLabel.hashCode).nextDouble() * 4000).toInt()}',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          )
        : Expanded(
            child: Text(
              'Tap a day for breakdown',
              style: AppTypography.caption.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activity Matrix',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
            ),
            GestureDetector(
              onTap: () => _showMonthPicker(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      _matrixMonthLabel,
                      style: AppTypography.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.profileDivider.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              matrixWidget,
              const SizedBox(height: 12),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [detailWidget, const Spacer(), _heatmapLegend()],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMonthPicker(BuildContext context) {
    HapticFeedback.selectionClick();
    final months = ['JAN 2026', 'FEB 2026', 'MAR 2026', 'APR 2026'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Month',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            ...months.map(
              (m) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  m,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: _matrixMonthLabel == m
                        ? FontWeight.w900
                        : FontWeight.w500,
                    color: _matrixMonthLabel == m
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),
                trailing: _matrixMonthLabel == m
                    ? Icon(
                        PhosphorIcons.check(PhosphorIconsStyle.bold),
                        color: AppColors.accent,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _matrixMonthLabel = m;
                    _selectedActivityIndex = -1;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _heatmapLegend() {
    return Row(
      children: [
        Text(
          'Quiet',
          style: AppTypography.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(left: 4),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: (i + 1) * 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Busy',
          style: AppTypography.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingInsight() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(
          0xFF1E1E20,
        ).withValues(alpha: 0.95), // Premium translucent black
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, Color(0xFFD4AF37)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              PhosphorIcons.lightbulb(PhosphorIconsStyle.fill),
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real-time Insight',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Spending pattern suggests a Rs. 2,500 saving potential this week.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
            color: AppColors.surface.withValues(alpha: 0.3),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildBooksOverlay() {
    return GestureDetector(
      onTap: () {
        _booksController.reverse().then((_) {
          setState(() => _isBooksOpen = false);
          widget.onToggleOverlay?.call(false);
        });
      },
      child: Stack(
        children: [
          // Background Blur
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _booksController,
              builder: (context, child) {
                final animation = CurvedAnimation(
                  parent: _booksController,
                  curve: Curves.easeOutQuint,
                  reverseCurve: Curves.easeIn,
                );

                final slide = Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(animation).value;

                final scale = Tween<double>(
                  begin: 0.92,
                  end: 1.0,
                ).animate(animation).value;

                return Transform.translate(
                  offset: slide * MediaQuery.of(context).size.height * 0.5,
                  child: Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: _booksController.value,
                      child: child,
                    ),
                  ),
                );
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFBFB),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text('Detailed Breakdown', style: AppTypography.h2),
                    const SizedBox(height: 8),
                    Text(
                      'Opening the books for ${_selectedPeriod == 'Days' ? 'Today' : (_selectedPeriod == 'Weeks' ? 'This Month' : 'This Year')}...',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _overlayDetailRow(
                      'Rent & Utilities',
                      'Rs. 45,000',
                      0.8,
                      AppColors.accent,
                    ),
                    _overlayDetailRow(
                      'Food & Dining',
                      'Rs. 12,400',
                      0.4,
                      AppColors.primary,
                    ),
                    _overlayDetailRow(
                      'Shopping',
                      'Rs. 8,200',
                      0.25,
                      AppColors.textPrimary,
                    ),
                    _overlayDetailRow(
                      'Travel',
                      'Rs. 4,500',
                      0.15,
                      AppColors.profileSubtext,
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () {
                        _booksController.reverse().then((_) {
                          setState(() => _isBooksOpen = false);
                          widget.onToggleOverlay?.call(false);
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'Close Books',
                            style: AppTypography.label.copyWith(
                              color: AppColors.textOnPrimary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overlayDetailRow(
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                value,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class RadialBarPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  RadialBarPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;
    const strokeWidth = 10.0;
    const spacing = 4.0;

    for (int i = 0; i < values.length; i++) {
      final radius =
          maxRadius - (i * (strokeWidth + spacing)) - (strokeWidth / 2);
      final rect = Rect.fromCircle(center: center, radius: radius);

      // Track
      final trackPaint = Paint()
        ..color = colors[i].withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

      // Progress
      final progressPaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Start from top (-pi/2)
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * values[i],
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
