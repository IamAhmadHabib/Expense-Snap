import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:kharcha/theme/app_colors.dart';
import 'package:kharcha/theme/app_spacing.dart';
import 'package:kharcha/theme/app_typography.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:kharcha/models/transaction.dart';
import 'package:kharcha/repositories/repository_scope.dart';
import 'package:kharcha/repositories/transaction_repository.dart';
import 'dart:math' as math;
import '../../services/analytics_ai_service.dart';
import 'widgets/real_time_insight_card.dart';

class AnalyticsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final Function(bool)? onToggleOverlay;
  final TransactionRepository? repository;
  const AnalyticsScreen({
    super.key,
    this.onBack,
    this.onToggleOverlay,
    this.repository,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  final _aiService = AnalyticsAiService();
  String _selectedPeriod = 'Days';
  int _selectedActivityIndex = -1;
  String _matrixMonthLabel = DateFormat(
    'MMM yyyy',
  ).format(DateTime.now()).toUpperCase();
  bool _isBooksOpen = false;
  late TransactionRepository _repository;
  bool _repositoryInitialized = false;
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
    if (_repositoryInitialized) {
      _repository.removeListener(_onRepositoryChanged);
    }
    _entranceController.dispose();
    _booksController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repositoryInitialized) return;
    _repository =
        widget.repository ??
        RepositoryScope.maybeOf(context)?.transactions ??
        TransactionRepository.inMemory();
    _repository.addListener(_onRepositoryChanged);
    _repositoryInitialized = true;
  }

  void _onRepositoryChanged() {
    if (mounted) setState(() {});
  }

  List<FlSpot> _getLineChartSpots() {
    final expenses = _repository.transactions.where((item) => !item.isIncome);
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'Days':
        return List.generate(7, (index) {
          final startHour = index * 4;
          final total = expenses
              .where(
                (item) =>
                    item.date.year == now.year &&
                    item.date.month == now.month &&
                    item.date.day == now.day &&
                    item.date.hour >= startHour &&
                    item.date.hour < startHour + 4,
              )
              .fold(0.0, (sum, item) => sum + item.amount);
          return FlSpot(startHour.toDouble(), total / 1000);
        });
      case 'Weeks':
        return List.generate(4, (index) {
          final total = expenses
              .where(
                (item) =>
                    item.date.year == now.year &&
                    item.date.month == now.month &&
                    ((item.date.day - 1) ~/ 7).clamp(0, 3) == index,
              )
              .fold(0.0, (sum, item) => sum + item.amount);
          return FlSpot(index.toDouble(), total / 1000);
        });
      case 'Months':
        return List.generate(6, (index) {
          final month = DateTime(now.year, now.month - 5 + index);
          final total = expenses
              .where(
                (item) =>
                    item.date.year == month.year &&
                    item.date.month == month.month,
              )
              .fold(0.0, (sum, item) => sum + item.amount);
          return FlSpot(index.toDouble(), total / 1000);
        });
      default:
        return [];
    }
  }

  List<Transaction> _getPeriodExpenses() {
    final now = DateTime.now();
    return _repository.transactions.where((item) {
      if (item.isIncome) return false;
      switch (_selectedPeriod) {
        case 'Days':
          return item.date.year == now.year &&
              item.date.month == now.month &&
              item.date.day == now.day;
        case 'Weeks':
          return item.date.year == now.year && item.date.month == now.month;
        case 'Months':
          final start = DateTime(now.year, now.month - 5);
          final end = DateTime(now.year, now.month + 1);
          return !item.date.isBefore(start) && item.date.isBefore(end);
        default:
          return false;
      }
    }).toList();
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
    final expenses = _getPeriodExpenses();
    final total = expenses.fold<double>(0, (sum, item) => sum + item.amount);
    final actualValue = expenses.isEmpty ? 0.0 : total / expenses.length;
    if (actualValue < 1000) {
      return 'Rs. ${actualValue.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
    return 'Rs. ${(actualValue / 1000).toStringAsFixed(1)}k';
  }

  Map<String, String> _getPeakStat() {
    final expenses = _getPeriodExpenses();
    if (expenses.isEmpty) {
      return {'label': 'N/A', 'amount': 'Rs. 0'};
    }

    if (_selectedPeriod == 'Days') {
      final now = DateTime.now();
      double maxAmount = -1;
      int maxStartHour = 12;
      for (int i = 0; i < 6; i++) {
        final startHour = i * 4;
        final slotTotal = expenses
            .where((item) =>
                item.date.year == now.year &&
                item.date.month == now.month &&
                item.date.day == now.day &&
                item.date.hour >= startHour &&
                item.date.hour < startHour + 4)
            .fold<double>(0, (sum, item) => sum + item.amount);
        if (slotTotal > maxAmount) {
          maxAmount = slotTotal;
          maxStartHour = startHour + 2;
        }
      }
      final label = '${maxStartHour.toString().padLeft(2, '0')}:00';
      final formattedAmount = maxAmount < 1000
          ? 'Rs. ${maxAmount.toInt()}'
          : 'Rs. ${(maxAmount / 1000).toStringAsFixed(1)}k';
      return {'label': label, 'amount': formattedAmount};
    } else if (_selectedPeriod == 'Weeks') {
      final dayTotals = <int, double>{};
      for (final item in expenses) {
        dayTotals[item.date.weekday] = (dayTotals[item.date.weekday] ?? 0) + item.amount;
      }
      int peakWeekday = 5;
      double maxAmount = -1;
      dayTotals.forEach((weekday, total) {
        if (total > maxAmount) {
          maxAmount = total;
          peakWeekday = weekday;
        }
      });
      const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final label = dayNames[(peakWeekday - 1) % 7];
      final formattedAmount = maxAmount < 1000
          ? 'Rs. ${maxAmount.toInt()}'
          : 'Rs. ${(maxAmount / 1000).toStringAsFixed(1)}k';
      return {'label': label, 'amount': formattedAmount};
    } else {
      final monthTotals = <int, double>{};
      for (final item in expenses) {
        monthTotals[item.date.month] = (monthTotals[item.date.month] ?? 0) + item.amount;
      }
      int peakMonth = DateTime.now().month;
      double maxAmount = -1;
      monthTotals.forEach((month, total) {
        if (total > maxAmount) {
          maxAmount = total;
          peakMonth = month;
        }
      });
      const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
      final label = monthNames[(peakMonth - 1) % 12];
      final formattedAmount = maxAmount < 1000
          ? 'Rs. ${maxAmount.toInt()}'
          : 'Rs. ${(maxAmount / 1000).toStringAsFixed(1)}k';
      return {'label': label, 'amount': formattedAmount};
    }
  }

  Map<String, dynamic> _getTrendDelta() {
    final now = DateTime.now();
    final allExpenses = _repository.transactions.where((item) => !item.isIncome);
    double currentTotal = 0;
    double previousTotal = 0;

    if (_selectedPeriod == 'Days') {
      currentTotal = allExpenses
          .where((item) => item.date.year == now.year && item.date.month == now.month && item.date.day == now.day)
          .fold<double>(0, (sum, item) => sum + item.amount);
      final yesterday = now.subtract(const Duration(days: 1));
      previousTotal = allExpenses
          .where((item) => item.date.year == yesterday.year && item.date.month == yesterday.month && item.date.day == yesterday.day)
          .fold<double>(0, (sum, item) => sum + item.amount);
    } else if (_selectedPeriod == 'Weeks') {
      currentTotal = allExpenses
          .where((item) => item.date.year == now.year && item.date.month == now.month)
          .fold<double>(0, (sum, item) => sum + item.amount);
      final prevMonthDate = DateTime(now.year, now.month - 1);
      previousTotal = allExpenses
          .where((item) => item.date.year == prevMonthDate.year && item.date.month == prevMonthDate.month)
          .fold<double>(0, (sum, item) => sum + item.amount);
    } else {
      currentTotal = allExpenses
          .where((item) => item.date.year == now.year)
          .fold<double>(0, (sum, item) => sum + item.amount);
      previousTotal = allExpenses
          .where((item) => item.date.year == now.year - 1)
          .fold<double>(0, (sum, item) => sum + item.amount);
    }

    if (previousTotal == 0) {
      if (currentTotal == 0) return {'text': '0.0%', 'isUp': true};
      return {'text': '+100%', 'isUp': true};
    }

    final diff = currentTotal - previousTotal;
    final pct = (diff / previousTotal) * 100;
    final prefix = pct >= 0 ? '+' : '';
    return {
      'text': '$prefix${pct.toStringAsFixed(1)}%',
      'isUp': pct >= 0,
    };
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
                    RepaintBoundary(child: _buildMainTrendChart()),
                    const SizedBox(height: AppSpacing.xl),
                    RepaintBoundary(child: _buildDistributionRow()),
                    const SizedBox(height: AppSpacing.xl),
                    RepaintBoundary(child: _buildHeatmapSection()),
                    const SizedBox(height: AppSpacing.xl),
                    RepaintBoundary(child: _buildFloatingInsight()),
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
        color: AppColors.surfaceVariant,
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
                      'Avg per expense',
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
                Builder(
                  builder: (context) {
                    final delta = _getTrendDelta();
                    final isUp = delta['isUp'] as bool;
                    final text = delta['text'] as String;
                    final color = isUp ? AppColors.accent : AppColors.chartNeutral;
                    return Container(
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
                            isUp
                                ? PhosphorIcons.trendUp(PhosphorIconsStyle.bold)
                                : PhosphorIcons.trendDown(PhosphorIconsStyle.bold),
                            color: color,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            text,
                            style: AppTypography.caption.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
                      colors: [AppColors.accent, AppColors.accentLight],
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
    final entries = _repository.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (sum, entry) => sum + entry.value);
    const colors = [
      AppColors.accent,
      AppColors.chartNeutral,
      AppColors.chartCharcoal,
      AppColors.primary,
    ];
    final items = entries.take(4).toList().asMap().entries.map((indexed) {
      final entry = indexed.value;
      return <String, dynamic>{
        'label': entry.key,
        'amount': 'Rs. ${NumberFormat.compact().format(entry.value)}',
        'value': total == 0 ? 0.0 : entry.value / total,
        'color': colors[indexed.key],
      };
    }).toList();
    return {
      'total': 'Rs. ${NumberFormat.compact().format(total)}',
      'items': items,
    };
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
                  Expanded(
                    child: Text(
                      'By Category',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h3.copyWith(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
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
              Column(
                children: [
                  Center(
                    child: SizedBox(
                      width: 132,
                      height: 132,
                      child: CustomPaint(
                        painter: RadialBarPainter(
                          values: items
                              .map((e) => e['value'] as double)
                              .toList(),
                          colors: items
                              .map((e) => e['color'] as Color)
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (items.isEmpty)
                    Text(
                      'No spending yet',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    Column(
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
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Stat',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.6,
                                    ),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                              Builder(
                                builder: (context) {
                                  final peak = _getPeakStat();
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        peak['label'] ?? 'N/A',
                                        style: AppTypography.h2.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                        ),
                                      ),
                                      Text(
                                        peak['amount'] ?? 'Rs. 0',
                                        style: AppTypography.bodySmall.copyWith(
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
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
      crossAxisAlignment: CrossAxisAlignment.center,
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
            maxLines: 2,
            overflow: TextOverflow.visible,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 76,
          child: Text(
            amount,
            maxLines: 1,
            textAlign: TextAlign.right,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.primary.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  double _activityAmount(int index) {
    final month = DateFormat('MMM yyyy').parseLoose(_matrixMonthLabel);
    final day = index + 1;
    return _repository.transactions
        .where(
          (transaction) =>
              !transaction.isIncome &&
              transaction.date.year == month.year &&
              transaction.date.month == month.month &&
              transaction.date.day == day,
        )
        .fold(0, (total, transaction) => total + transaction.amount);
  }

  double get _maxActivityAmount {
    return List.generate(
      28,
      _activityAmount,
    ).fold<double>(0, (max, value) => value > max ? value : max);
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
                      final maxAmount = _maxActivityAmount;
                      final intensity = maxAmount == 0
                          ? 0.0
                          : _activityAmount(idx) / maxAmount;
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

    final detailText = _selectedActivityIndex != -1
        ? 'Day ${_selectedActivityIndex + 1}: Rs. ${NumberFormat('#,###').format(_activityAmount(_selectedActivityIndex))}'
        : 'Tap a day for breakdown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Activity Matrix',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
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
                children: [
                  Expanded(
                    child: Text(
                      detailText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (_selectedActivityIndex != -1
                                  ? AppTypography.bodySmall
                                  : AppTypography.caption)
                              .copyWith(
                                fontWeight: _selectedActivityIndex != -1
                                    ? FontWeight.w800
                                    : null,
                                color: AppColors.primary.withValues(
                                  alpha: _selectedActivityIndex != -1 ? 1 : 0.5,
                                ),
                                fontStyle: _selectedActivityIndex == -1
                                    ? FontStyle.italic
                                    : null,
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _heatmapLegend(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showMonthPicker(BuildContext context) {
    HapticFeedback.selectionClick();
    final currentYear = DateTime.now().year;
    final months = List.generate(12, (index) {
      final d = DateTime(currentYear, index + 1);
      return DateFormat('MMM yyyy').format(d).toUpperCase();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Month',
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(
                  '$currentYear',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: Scrollbar(
                thumbVisibility: true,
                radius: const Radius.circular(4),
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: months.length,
                  separatorBuilder: (_, index) => Divider(
                    height: 1,
                    thickness: 0.5,
                    color: AppColors.profileDivider.withValues(alpha: 0.4),
                  ),
                  itemBuilder: (context, index) {
                    final m = months[index];
                    final isSelected = _matrixMonthLabel == m;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(
                        m,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: isSelected
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
                    );
                  },
                ),
              ),
            ),
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
    final settings = RepositoryScope.maybeOf(context)?.settings.settings;
    final monthlyBudget = settings?.monthlyBudget ?? 0.0;
    final currency = settings?.currencySymbol ?? 'Rs.';

    final insight = _aiService.generateInsight(
      transactions: _repository.transactions,
      monthlyBudget: monthlyBudget,
      currency: currency,
    );

    return RealTimeInsightCard(
      insight: insight,
      currency: currency,
      onRegenerate: () async {
        return await _aiService.generateGeminiDeepDive(
          baseInsight: insight,
          transactions: _repository.transactions,
          monthlyBudget: monthlyBudget,
          currency: currency,
        );
      },
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
                  color: AppColors.surface,
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
  bool shouldRepaint(covariant RadialBarPainter oldDelegate) {
    if (oldDelegate.values.length != values.length ||
        oldDelegate.colors.length != colors.length) {
      return true;
    }
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    for (var i = 0; i < colors.length; i++) {
      if (oldDelegate.colors[i] != colors[i]) return true;
    }
    return false;
  }
}
