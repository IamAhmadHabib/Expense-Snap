import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import '../../services/home_widget_service.dart';
import '../analytics/analytics_screen.dart';
import '../history/history_screen.dart';
import '../transactions/add_transaction_sheet.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../repositories/app_settings_repository.dart';
import '../../repositories/repository_scope.dart';
import '../../repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kharcha/theme/app_colors.dart';
import 'package:kharcha/theme/app_spacing.dart';
import 'package:kharcha/theme/app_typography.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DashboardScreen extends StatefulWidget {
  final double initialBudget;
  final String userName;
  final String currencySymbol;

  const DashboardScreen({
    super.key,
    this.initialBudget = 0.0,
    this.userName = 'Ahmad',
    this.currencySymbol = r'$',
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _mainController;
  late Animation<double> _budgetCountAnimation;

  // Animation intervals for sophisticated 'Awakening' sequence
  late Animation<double> _topBarOpacity;
  late Animation<Offset> _heroSlide;
  late Animation<double> _heroScale;
  late Animation<Offset> _bentoSlide;
  late Animation<Offset> _dockSlide;
  late PageController _tabPageController;

  int _activeTab = 0; // 0: Home, 1: Analytics, 2: History, 3: Profile
  bool _isSheetOpen = false;
  bool _isAddPressed = false;

  // Controller for screen transitions
  late AnimationController _screenTransitionController;
  bool _isAnalyticsOverlayOpen = false;
  late TransactionRepository _transactions;
  late AppSettingsRepository _settings;
  bool _repositoriesInitialized = false;
  late List<Widget> _tabPages;
  bool _tabPagesInitialized = false;
  StreamSubscription<Uri?>? _widgetClickSub;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // ─── Staggered Assembly ────────────────────────

    // 1. Top Bar & Greeting (0ms - 400ms)
    _topBarOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    // 2. Budget Hero Card (200ms - 800ms) - SPRING BOUNCE
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
          ),
        );
    _heroScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    // 3. Bento Grid (400ms - 1000ms)
    _bentoSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    // 4. Floating Glass Dock (600ms - 1200ms)
    _dockSlide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    // 5. Budget Counter & Progress (1000ms - 1800ms)
    _budgetCountAnimation = Tween<double>(begin: 0, end: widget.initialBudget)
        .animate(
          CurvedAnimation(
            parent: _mainController,
            curve: const Interval(0.6, 1.0, curve: Curves.easeOutExpo),
          ),
        );

    _mainController.forward();
    _tabPageController = PageController(initialPage: _activeTab);

    _screenTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addObserver(this);
    _playTactileFeedback();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_repositoriesInitialized) {
        _transactions.load();
        _settings.load();
      }
    }
  }

  void _playTactileFeedback() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetClickSub?.cancel();
    if (_repositoriesInitialized) {
      _transactions.removeListener(_onRepositoryChanged);
      _settings.removeListener(_onRepositoryChanged);
    }
    _mainController.dispose();
    _tabPageController.dispose();
    _screenTransitionController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repositoriesInitialized) return;
    final scope = RepositoryScope.maybeOf(context);
    _transactions = scope?.transactions ?? TransactionRepository.inMemory();
    _settings = scope?.settings ?? AppSettingsRepository.inMemory();
    _transactions.addListener(_onRepositoryChanged);
    _settings.addListener(_onRepositoryChanged);
    _tabPages = _buildTabPages();
    _tabPagesInitialized = true;
    _repositoriesInitialized = true;
    _widgetClickSub ??= HomeWidgetService.registerClickCallback(_handleWidgetUri);
    _syncHomeWidget();
  }

  void _onRepositoryChanged() {
    _syncHomeWidget();
    if (mounted) {
      setState(() {
        _tabPages = _buildTabPages();
      });
    }
  }

  void _syncHomeWidget() {
    if (!_repositoriesInitialized) return;
    unawaited(
      HomeWidgetService.updateWidgetData(
        transactions: _transactions.transactions,
        settings: _settings.settings,
      ),
    );
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null || !mounted) return;
    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();

    if (host == 'capture' || path.contains('capture')) {
      if (path.contains('voice') || host == 'voice') {
        _openAddTransaction(AddTransactionTab.voice);
      } else if (path.contains('scan') || host == 'scan') {
        _openAddTransaction(AddTransactionTab.scan);
      } else if (path.contains('manual') || host == 'manual') {
        _openAddTransaction(AddTransactionTab.manual);
      }
    } else if (host == 'home') {
      _selectTab(0);
    }
  }

  double get _budget => _settings.settings.monthlyBudget > 0
      ? _settings.settings.monthlyBudget
      : widget.initialBudget;
  String get _currency => _settings.settings.currencySymbol.isNotEmpty
      ? _settings.settings.currencySymbol
      : widget.currencySymbol;
  String get _userName => _settings.settings.userName.isNotEmpty
      ? _settings.settings.userName
      : widget.userName;
  double get _spent => _transactions.currentMonthExpenses;
  double get _remainingBudget => (_budget - _spent).clamp(0, _budget);
  double get _budgetLeftFraction =>
      _budget <= 0 ? 0 : _remainingBudget / _budget;

  SystemUiOverlayStyle _getStatusBarStyle() {
    switch (_activeTab) {
      case 2: // History (Dark header)
      case 3: // Profile (Dark header)
        return SystemUiOverlayStyle.light;
      case 0: // Home (Light background)
      case 1: // Analytics (Light background)
      default:
        return SystemUiOverlayStyle.dark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _activeTab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _activeTab != 0) {
          _selectTab(0);
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: _getStatusBarStyle(),
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // ─── Content Layers ──────────
              _buildScreenContent(),

              // Overlay when sheet is open
              // ─── Floating Glass Dock ───────────────────────
              if (!_isAnalyticsOverlayOpen) _buildFloatingDock(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreenContent() {
    if (!_tabPagesInitialized) {
      return const SizedBox.shrink();
    }
    return PageView(
      controller: _tabPageController,
      physics: const NeverScrollableScrollPhysics(),
      allowImplicitScrolling: true,
      onPageChanged: (index) {
        if (_activeTab != index) {
          setState(() => _activeTab = index);
        }
      },
      children: _tabPages,
    );
  }

  List<Widget> _buildTabPages() {
    return [
      _KeepAliveTabPage(child: RepaintBoundary(child: _buildDashboardBody())),
      _KeepAliveTabPage(
        child: RepaintBoundary(
          child: AnalyticsScreen(
            repository: _transactions,
            onBack: () => _selectTab(0),
            onToggleOverlay: (isOpen) =>
                setState(() => _isAnalyticsOverlayOpen = isOpen),
          ),
        ),
      ),
      _KeepAliveTabPage(
        child: RepaintBoundary(child: HistoryScreen(repository: _transactions)),
      ),
      _KeepAliveTabPage(
        child: RepaintBoundary(
          child: ProfileScreen(
            settingsRepository: _settings,
            transactionRepository: _transactions,
          ),
        ),
      ),
    ];
  }

  void _selectTab(int index) {
    if (_activeTab == index) return;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(() => _activeTab = index);
    if (_tabPageController.hasClients) {
      _tabPageController.jumpToPage(index);
    }
  }

  void _openNotifications() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
  }

  Future<void> _openAddTransaction(AddTransactionTab initialTab) async {
    if (_isSheetOpen) return;

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    setState(() => _isSheetOpen = true);

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      barrierColor: AppColors.primary.withValues(alpha: 0.12),
      builder: (context) => RepaintBoundary(
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: const SizedBox.expand(),
              ),
            ),
            AddTransactionSheet(
              initialTab: initialTab,
              repository: _transactions,
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _isSheetOpen = false);

    if (result == true) {
      // Phase 2 will refresh shared transaction data here.
    }
  }

  Widget _buildDashboardBody() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: AppSpacing.screenHorizontal,
          right: AppSpacing.screenHorizontal,
          top: AppSpacing.md,
          bottom: 140, // Generous padding to clear the floating dock
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClassicHeader(),
            const SizedBox(height: AppSpacing.lg),
            RepaintBoundary(child: _buildBudgetHeroCard()),
            const SizedBox(height: AppSpacing.xl),
            RepaintBoundary(child: _buildQuickActions()),
            const SizedBox(height: AppSpacing.xl),
            RepaintBoundary(child: _buildWeeklyVelocity()),
            const SizedBox(height: AppSpacing.lg),
            RepaintBoundary(child: _buildRecentCategories()),
          ],
        ),
      ),
    );
  }

  // ─── 1. Top Bar & Greeting ───────────────────────────

  Widget _buildClassicHeader() {
    return FadeTransition(
      opacity: _topBarOpacity,
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Profile & Message
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _selectTab(3),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        PhosphorIcons.user(PhosphorIconsStyle.light),
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Good morning,',
                        style: AppTypography.label.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _userName,
                            style: AppTypography.h3.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('👋', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right: Notifications
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openNotifications,
              child: Container(
                width: 48,
                height: 48,
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      PhosphorIcons.bell(PhosphorIconsStyle.light),
                      color: AppColors.primary,
                      size: 24,
                    ),
                    Positioned(
                      top: 13,
                      right: 13,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 2. Budget Hero Card (Optical Kerning Refactor) ───

  Widget _buildBudgetHeroCard() {
    return SlideTransition(
      position: _heroSlide,
      child: ScaleTransition(
        scale: _heroScale,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.surfaceDark, AppColors.backgroundDark],
            ),
            borderRadius: BorderRadius.circular(36), // Deep premium curve
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: Stack(
              children: [
                // Prominent Status Icon Watermark
                Positioned(
                  right: -40,
                  bottom: -50,
                  child: Icon(
                    PhosphorIcons.wallet(PhosphorIconsStyle.fill),
                    size: 200,
                    color: AppColors.surface.withValues(alpha: 0.05),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'October Budget',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label.copyWith(
                                color: AppColors.surface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${(_budgetLeftFraction * 100).round()}% left',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      AnimatedBuilder(
                        animation: _budgetCountAnimation,
                        builder: (context, child) {
                          final double animationProgress =
                              widget.initialBudget > 0
                              ? (_budgetCountAnimation.value /
                                        widget.initialBudget)
                                    .clamp(0, 1)
                              : _mainController.value;
                          final double currentVal =
                              _remainingBudget * animationProgress;
                          String displayValue;

                          if (currentVal >= 1000000) {
                            // High-magnitude compact form for premium legibility
                            displayValue = NumberFormat.compactCurrency(
                              symbol: '',
                              decimalDigits: 1,
                            ).format(currentVal);
                          } else {
                            displayValue = NumberFormat(
                              '#,###',
                            ).format(currentVal);
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8.0,
                                  right: 6.0,
                                ),
                                child: Text(
                                  _currency,
                                  style: AppTypography.h3.copyWith(
                                    color: AppColors.surface.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  displayValue,
                                  style: AppTypography.display.copyWith(
                                    color: AppColors.surface,
                                    fontSize: 56,
                                    height: 1.0,
                                    letterSpacing: -2.0,
                                  ),
                                  overflow: TextOverflow.visible,
                                  softWrap: false,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'of $_currency ${NumberFormat.compact().format(_budget)} planned',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.surface.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Recessed Premium Progress Bar
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(
                                alpha: 0.15,
                              ), // Clear crisp track layout for high contrast
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _mainController,
                            builder: (context, child) {
                              final double progress = CurvedAnimation(
                                parent: _mainController,
                                curve: const Interval(
                                  0.6,
                                  1.0,
                                  curve: Curves.easeInOut,
                                ),
                              ).value;
                              return FractionallySizedBox(
                                widthFactor: progress * _budgetLeftFraction,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.surface.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
      ),
    );
  }

  // ─── 3. Horizontal Weekly Velocity ───────────────────────

  Widget _buildQuickActions() {
    return SlideTransition(
      position: _bentoSlide,
      child: FadeTransition(
        opacity: _topBarOpacity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 2,
              child: _buildHeroActionCard(
                'Voice',
                PhosphorIcons.microphone(PhosphorIconsStyle.light),
                AppColors.accent,
                AppColors.surface,
                () => _openAddTransaction(AddTransactionTab.voice),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 1,
              child: _buildSecondaryActionCard(
                'Scan',
                PhosphorIcons.scan(PhosphorIconsStyle.light),
                () => _openAddTransaction(AddTransactionTab.scan),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 1,
              child: _buildSecondaryActionCard(
                'Manual',
                PhosphorIcons.notePencil(PhosphorIconsStyle.light),
                () => _openAddTransaction(AddTransactionTab.manual),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroActionCard(
    String title,
    IconData icon,
    Color bgColor,
    Color fgColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 85,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [bgColor, bgColor.withValues(alpha: 0.9)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTypography.h3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryActionCard(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 85,
        decoration: BoxDecoration(
          color: AppColors.warmSurfaceMuted,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.warmBorder, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyVelocity() {
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final weeklyAmounts = List<double>.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      return _transactions.transactions
          .where(
            (transaction) =>
                !transaction.isIncome &&
                transaction.date.year == day.year &&
                transaction.date.month == day.month &&
                transaction.date.day == day.day,
          )
          .fold(0, (total, transaction) => total + transaction.amount);
    });
    final maxAmount = weeklyAmounts.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SlideTransition(
      position: _bentoSlide,
      child: FadeTransition(
        opacity: _topBarOpacity,
        child: Container(
          width: double.infinity,
          height:
              224, // Accommodates the 48px action target plus 90px weekly bars and text labels
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(32),
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
                  Row(
                    children: [
                      Text(
                        'This Week',
                        style: AppTypography.h3.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PKR',
                          style: AppTypography.overline.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Semantics(
                    button: true,
                    label: 'Open weekly analytics',
                    child: GestureDetector(
                      key: const ValueKey('weekly_velocity_menu'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _selectTab(1),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: Icon(
                            PhosphorIcons.dotsThree(PhosphorIconsStyle.bold),
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  final amount = weeklyAmounts[index];
                  final height = (amount <= 0 || maxAmount <= 0)
                      ? 0.0
                      : (amount / maxAmount * 66.0).clamp(16.0, 66.0);
                  return _buildBar(
                    labels[index],
                    height,
                    now.weekday == index + 1,
                    NumberFormat.compact().format(amount),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String day, double height, bool isToday, String amountStr) {
    const double maxBarHeight = 90.0;
    const double barWidth = 32.0;
    const double pillRadius = 16.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          amountStr,
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            color: isToday
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.4),
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        // Pill track with subtle greyish background representing empty bar
        Container(
          width: barWidth,
          height: maxBarHeight,
          decoration: BoxDecoration(
            color: AppColors.chartTrack,
            borderRadius: BorderRadius.circular(pillRadius),
          ),
          alignment: Alignment.bottomCenter,
          child: height > 0
              ? Container(
                  width: barWidth,
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: isToday
                          ? [
                              AppColors.accent,
                              AppColors.accent.withValues(alpha: 0.7),
                            ]
                          : [
                              AppColors.chartCharcoal,
                              AppColors.chartCharcoalDark,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(pillRadius),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: AppTypography.caption.copyWith(
            color: isToday
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.4),
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Categories / Activity Feed ──────────────────────────

  Widget _buildRecentCategories() {
    final categories = _transactions.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = categories.take(5).toList();
    final items = topCategories.isEmpty
        ? [
            _buildCategoryBox(
              'No spending yet',
              '$_currency 0',
              PhosphorIcons.sparkle(PhosphorIconsStyle.light),
              PhosphorIcons.sparkle(PhosphorIconsStyle.light),
            ),
          ]
        : topCategories.map((entry) {
            final icon = _categoryIcon(entry.key);
            return _buildCategoryBox(
              entry.key,
              '$_currency ${NumberFormat('#,###').format(entry.value)}',
              icon,
              icon,
            );
          }).toList();

    return SlideTransition(
      position: _bentoSlide,
      child: FadeTransition(
        opacity: _topBarOpacity, // Re-use the entrance fade/slide
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Top Spending', style: AppTypography.h3),
                Semantics(
                  button: true,
                  label: 'See all transactions',
                  child: GestureDetector(
                    key: const ValueKey('top_spending_see_all'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _selectTab(2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Text(
                        'See all',
                        style: AppTypography.label.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Column(
              key: const ValueKey('top_spending_static_list'),
              children: items,
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'dining':
      case 'food':
      case 'food & dining':
        return PhosphorIcons.forkKnife(PhosphorIconsStyle.light);
      case 'transport':
        return PhosphorIcons.car(PhosphorIconsStyle.light);
      case 'shopping':
        return PhosphorIcons.shoppingBag(PhosphorIconsStyle.light);
      default:
        return PhosphorIcons.tag(PhosphorIconsStyle.light);
    }
  }

  Widget _buildCategoryBox(
    String title,
    String amount,
    IconData icon1,
    IconData watermark,
  ) {
    return Container(
      width: double.infinity,
      height: 90,
      margin: const EdgeInsets.only(
        bottom: 10,
      ), // Bottom margin allows shadow breathing room
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned(
              right: -5,
              top: 5, // Perfectly centers the 80px icon inside the 90px card
              child: Icon(
                watermark,
                size: 80,
                color: AppColors.primary.withValues(alpha: 0.04),
              ), // Subtle Charcoal watermark
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.03,
                      ), // Soft Charcoal housing
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        width: 1.0,
                      ), // Structured bezel
                    ),
                    child: Icon(
                      icon1,
                      color: AppColors.primary,
                      size: 22,
                    ), // Bold Charcoal foreground
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          amount,
                          style: AppTypography.h3.copyWith(
                            fontSize: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 4. The Floating Glass Dock ────────────────────────

  Widget _buildFloatingDock() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dockHorizontalPadding = ((screenWidth - 280) * 0.20).clamp(
      8.0,
      AppSpacing.screenHorizontal,
    );

    return SlideTransition(
      position: _dockSlide,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            left: dockHorizontalPadding,
            right: dockHorizontalPadding,
            bottom: MediaQuery.paddingOf(context).bottom > 0
                ? MediaQuery.paddingOf(context).bottom
                : 32, // Hovers securely
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              // Dark Definition Well (Provides contrast for clear glass)
              Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
              ),

              // The Liquid Glass Base
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 40,
                    sigmaY: 40,
                  ), // Ultra-diffraction for liquid effect
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(
                        alpha: 0.20,
                      ), // Hyper-translucent core
                      borderRadius: BorderRadius.circular(40),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.surface.withValues(
                            alpha: 0.10,
                          ), // Ultra-soft sheen
                          AppColors.surface.withValues(
                            alpha: 0.01,
                          ), // Near-invis bottom
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.surface.withValues(
                          alpha: 0.95,
                        ), // Razor-sharp specular rim
                        width: 0.8,
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const centerGap = 60.0;
                        final groupWidth =
                            (constraints.maxWidth - centerGap) / 2;
                        final reduceMotion =
                            MediaQuery.maybeOf(context)?.disableAnimations ??
                            false;

                        return Row(
                          children: [
                            SizedBox(
                              width: groupWidth,
                              child: _buildDockGroup(
                                groupWidth: groupWidth,
                                reduceMotion: reduceMotion,
                                destinations: [
                                  _DockDestination(
                                    label: 'Home',
                                    activeIcon: PhosphorIcons.house(
                                      PhosphorIconsStyle.fill,
                                    ),
                                    inactiveIcon: PhosphorIcons.house(
                                      PhosphorIconsStyle.light,
                                    ),
                                    index: 0,
                                  ),
                                  _DockDestination(
                                    label: 'Analytics',
                                    activeIcon: PhosphorIcons.chartPieSlice(
                                      PhosphorIconsStyle.fill,
                                    ),
                                    inactiveIcon: PhosphorIcons.chartPieSlice(
                                      PhosphorIconsStyle.light,
                                    ),
                                    index: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: centerGap),
                            SizedBox(
                              width: groupWidth,
                              child: _buildDockGroup(
                                groupWidth: groupWidth,
                                reduceMotion: reduceMotion,
                                destinations: [
                                  _DockDestination(
                                    label: 'History',
                                    activeIcon:
                                        PhosphorIcons.clockCounterClockwise(
                                          PhosphorIconsStyle.fill,
                                        ),
                                    inactiveIcon:
                                        PhosphorIcons.clockCounterClockwise(
                                          PhosphorIconsStyle.light,
                                        ),
                                    index: 2,
                                  ),
                                  _DockDestination(
                                    label: 'Profile',
                                    activeIcon: PhosphorIcons.user(
                                      PhosphorIconsStyle.fill,
                                    ),
                                    inactiveIcon: PhosphorIcons.user(
                                      PhosphorIconsStyle.light,
                                    ),
                                    index: 3,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              // The fixed Kharcha add tile.
              Positioned(
                bottom:
                    25, // Extends proudly above the visual edge of the glass pill
                child: Semantics(
                  button: true,
                  label: 'Add transaction',
                  child: GestureDetector(
                    key: const ValueKey('dock_add_button'),
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) {
                      if (!_isSheetOpen) {
                        setState(() => _isAddPressed = true);
                      }
                    },
                    onTapUp: (_) => setState(() => _isAddPressed = false),
                    onTapCancel: () => setState(() => _isAddPressed = false),
                    onTap: () async {
                      await _openAddTransaction(AddTransactionTab.voice);
                    },
                    child: AnimatedScale(
                      duration: Duration(
                        milliseconds:
                            (MediaQuery.maybeOf(context)?.disableAnimations ??
                                false)
                            ? 80
                            : 110,
                      ),
                      curve: Curves.easeOutCubic,
                      scale: _isAddPressed ? 0.94 : 1,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isSheetOpen ? 66 : 64,
                        height: _isSheetOpen ? 66 : 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.accent, AppColors.amberGold],
                          ),
                          borderRadius: BorderRadius.circular(
                            _isSheetOpen ? 23 : 21,
                          ),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedRotation(
                            duration: const Duration(milliseconds: 300),
                            turns: _isSheetOpen ? 0.125 : 0,
                            child: const _KharchaAddMark(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockGroup({
    required double groupWidth,
    required bool reduceMotion,
    required List<_DockDestination> destinations,
  }) {
    final activeInGroup = destinations.any(
      (destination) => destination.index == _activeTab,
    );
    final restingWidth = groupWidth / destinations.length;
    const compactWidth = 44.0;
    final expandedWidth = groupWidth - compactWidth;

    return Row(
      children: destinations.map((destination) {
        final isActive = destination.index == _activeTab;
        final targetWidth = activeInGroup
            ? (isActive ? expandedWidth : compactWidth)
            : restingWidth;

        return _AnimatedDockItem(
          key: ValueKey('dock_tab_${destination.index}'),
          destination: destination,
          isActive: isActive,
          width: targetWidth,
          reduceMotion: reduceMotion,
          onTap: () => _selectTab(destination.index),
        );
      }).toList(),
    );
  }
}

class _KharchaAddMark extends StatelessWidget {
  const _KharchaAddMark();

  @override
  Widget build(BuildContext context) {
    const barDecoration = BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.all(Radius.circular(99)),
    );

    return const SizedBox.square(
      dimension: 29,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 29,
            height: 4.5,
            child: DecoratedBox(decoration: barDecoration),
          ),
          SizedBox(
            width: 4.5,
            height: 29,
            child: DecoratedBox(decoration: barDecoration),
          ),
        ],
      ),
    );
  }
}

class _DockDestination {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final int index;

  const _DockDestination({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.index,
  });
}

class _AnimatedDockItem extends StatefulWidget {
  final _DockDestination destination;
  final bool isActive;
  final double width;
  final bool reduceMotion;
  final VoidCallback onTap;

  const _AnimatedDockItem({
    super.key,
    required this.destination,
    required this.isActive,
    required this.width,
    required this.reduceMotion,
    required this.onTap,
  });

  @override
  State<_AnimatedDockItem> createState() => _AnimatedDockItemState();
}

class _AnimatedDockItemState extends State<_AnimatedDockItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _selectionController;

  Duration get _forwardDuration =>
      Duration(milliseconds: widget.reduceMotion ? 140 : 320);

  Duration get _reverseDuration =>
      Duration(milliseconds: widget.reduceMotion ? 120 : 260);

  Curve get _motionCurve => widget.reduceMotion
      ? Curves.easeOutCubic
      : const Cubic(0.20, 1.04, 0.30, 1.0);

  @override
  void initState() {
    super.initState();
    _selectionController = AnimationController(
      vsync: this,
      duration: _forwardDuration,
      reverseDuration: _reverseDuration,
      value: widget.isActive ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant _AnimatedDockItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectionController
      ..duration = _forwardDuration
      ..reverseDuration = _reverseDuration;

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _selectionController.forward();
      } else {
        _selectionController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widthDuration = Duration(
      milliseconds: widget.reduceMotion ? 140 : 300,
    );

    return Semantics(
      button: true,
      selected: widget.isActive,
      label: widget.destination.label,
      onTap: widget.onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: widthDuration,
          curve: _motionCurve,
          width: widget.width,
          height: 56,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.accent.withValues(alpha: 0.12)
                : AppColors.surface.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(24),
          ),
          child: AnimatedBuilder(
            animation: _selectionController,
            builder: (context, child) {
              final progress = _motionCurve.transform(
                _selectionController.value,
              );
              final reveal = const Interval(
                0.12,
                1,
                curve: Curves.easeOutCubic,
              ).transform(_selectionController.value);
              final pulse = widget.reduceMotion
                  ? 0.0
                  : math.sin(math.pi * _selectionController.value);
              final iconColor = Color.lerp(
                AppColors.navInactive,
                AppColors.primary,
                progress.clamp(0, 1),
              )!;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.rotate(
                      angle: -0.07 * pulse,
                      child: Transform.scale(
                        scale: 1 + (0.035 * pulse),
                        child: Icon(
                          widget.isActive
                              ? widget.destination.activeIcon
                              : widget.destination.inactiveIcon,
                          color: iconColor,
                          size: 22,
                        ),
                      ),
                    ),
                    if (_selectionController.value > 0.001) ...[
                      SizedBox(width: 4 * reveal),
                      Flexible(
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: reveal,
                            child: Opacity(
                              opacity: reveal.clamp(0, 1),
                              child: Transform.translate(
                                offset: Offset(8 * (1 - reveal), 0),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    widget.destination.label,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.clip,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10.5,
                                      height: 1,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _KeepAliveTabPage extends StatefulWidget {
  final Widget child;

  const _KeepAliveTabPage({required this.child});

  @override
  State<_KeepAliveTabPage> createState() => _KeepAliveTabPageState();
}

class _KeepAliveTabPageState extends State<_KeepAliveTabPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
