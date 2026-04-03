import 'dart:ui';
import '../transactions/add_transaction_sheet.dart';
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

  const DashboardScreen({
    super.key,
    required this.initialBudget,
    required this.userName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _budgetCountAnimation;
  
  // Animation intervals for sophisticated 'Awakening' sequence
  late Animation<double> _topBarOpacity;
  late Animation<Offset> _heroSlide;
  late Animation<double> _heroScale;
  late Animation<Offset> _bentoSlide;
  late Animation<Offset> _dockSlide;

  bool _isSheetOpen = false;

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
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.2, curve: Curves.easeOut)),
    );

    // 2. Budget Hero Card (200ms - 800ms) - SPRING BOUNCE
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.2, 0.7, curve: Curves.elasticOut)),
    );
    _heroScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.2, 0.7, curve: Curves.elasticOut)),
    );

    // 3. Bento Grid (400ms - 1000ms)
    _bentoSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic)),
    );

    // 4. Floating Glass Dock (600ms - 1200ms)
    _dockSlide = Tween<Offset>(begin: const Offset(0, 1.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic)),
    );

    // 5. Budget Counter & Progress (1000ms - 1800ms)
    _budgetCountAnimation = Tween<double>(begin: 0, end: widget.initialBudget).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.6, 1.0, curve: Curves.easeOutExpo)),
    );

    _mainController.forward();
    _playTactileFeedback();
  }

  void _playTactileFeedback() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Main Scrollable Content ───────────────────
          // Add Overlay when sheet is open
          if (_isSheetOpen)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: Colors.black.withValues(alpha: 0.4),
            ),
          
          SafeArea(
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
                  _buildBudgetHeroCard(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildQuickActions(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildWeeklyVelocity(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildRecentCategories(),
                ],
              ),
            ),
          ),
          
          // ─── Floating Glass Dock ───────────────────────
          _buildFloatingDock(),
        ],
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
            Row(
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
                          widget.userName,
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

            // Right: Notifications
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
                        color: AppColors.accent, // Brand Amber
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.5),
                            blurRadius: 4,
                          )
                        ]
                      ),
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
              colors: [
                Color(0xFF2C2C2E), // Subtle dark metallic grey
                Color(0xFF18181A), // Deep Charcoal
              ],
            ),
            borderRadius: BorderRadius.circular(36), // Deep premium curve
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
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
                    color: Colors.white.withValues(alpha: 0.05),
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
                          Text(
                            'October Budget',
                            style: AppTypography.label.copyWith(color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.normal),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '49% left',
                              style: AppTypography.caption.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      AnimatedBuilder(
                        animation: _budgetCountAnimation,
                        builder: (context, child) {
                          final double currentVal = _budgetCountAnimation.value;
                          String displayValue;
                          
                          if (currentVal >= 1000000) {
                            // High-magnitude compact form for premium legibility
                            displayValue = NumberFormat.compactCurrency(
                              symbol: '', 
                              decimalDigits: 1
                            ).format(currentVal);
                          } else {
                            displayValue = NumberFormat('#,###').format(currentVal);
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0, right: 6.0),
                                child: Text('Rs.', style: AppTypography.h3.copyWith(color: Colors.white.withValues(alpha: 0.5))),
                              ),
                              Flexible(
                                child: Text(
                                  displayValue,
                                  style: AppTypography.display.copyWith(
                                    color: Colors.white, 
                                    fontSize: 56, 
                                    height: 1.0, 
                                    letterSpacing: -2.0
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
                        'of Rs. ${NumberFormat.compact().format(widget.initialBudget)} planned',
                        style: AppTypography.bodySmall.copyWith(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      const SizedBox(height: 32),
                      
                      // Recessed Premium Progress Bar
                      Stack(
                        children: [
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15), // Clear crisp track layout for high contrast
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _mainController,
                            builder: (context, child) {
                              final double progress = CurvedAnimation(
                                parent: _mainController,
                                curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
                              ).value;
                              return FractionallySizedBox(
                                widthFactor: progress * 0.49,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(color: Colors.white.withValues(alpha: 0.4), blurRadius: 8),
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
              child: _buildHeroActionCard('Voice', PhosphorIcons.microphone(PhosphorIconsStyle.light), AppColors.accent, Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 1,
              child: _buildSecondaryActionCard('Scan', PhosphorIcons.scan(PhosphorIconsStyle.light)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 1,
              child: _buildSecondaryActionCard('Manual', PhosphorIcons.notePencil(PhosphorIconsStyle.light)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroActionCard(String title, IconData icon, Color bgColor, Color fgColor) {
    return Container(
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
            )
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActionCard(String title, IconData icon) {
    return Container(
      height: 85, // Uniform height
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6F0), 
        borderRadius: BorderRadius.circular(24), // Unified Squircle
        border: Border.all(color: const Color(0xFFE8DDD0), width: 1.2),
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
            )
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyVelocity() {
    return SlideTransition(
      position: _bentoSlide,
      child: FadeTransition(
        opacity: _topBarOpacity,
        child: Container(
          width: double.infinity,
          height: 190, // Increased height to precisely accommodate texts without overflowing
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
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
                      Text('This Week', style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PKR', 
                          style: AppTypography.overline.copyWith(
                            fontSize: 10, 
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary.withValues(alpha: 0.6)
                          )
                        ),
                      ),
                    ],
                  ),
                  Icon(PhosphorIcons.dotsThree(PhosphorIconsStyle.bold), color: AppColors.primary.withValues(alpha: 0.3)),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBar('Mon', 40, DateTime.now().weekday == 1, "400"),
                  _buildBar('Tue', 60, DateTime.now().weekday == 2, "600"),
                  _buildBar('Wed', 30, DateTime.now().weekday == 3, "300"),
                  _buildBar('Thu', 80, DateTime.now().weekday == 4, "800"),
                  _buildBar('Fri', 20, DateTime.now().weekday == 5, "200"),
                  _buildBar('Sat', 50, DateTime.now().weekday == 6, "500"),
                  _buildBar('Sun', 70, DateTime.now().weekday == 7, "700"),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String day, double height, bool isToday, String amountStr) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          amountStr,
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            color: isToday ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4),
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 32, // wide, thick bars for luxury feel
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: isToday
                  ? [AppColors.accent, AppColors.accent.withValues(alpha: 0.7)]
                  : [const Color(0xFF4A4A4A), const Color(0xFF383838)],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isToday
                ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                : [],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: AppTypography.caption.copyWith(
            color: isToday ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4),
            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Categories / Activity Feed ──────────────────────────

  Widget _buildRecentCategories() {
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
                Text('See all', style: AppTypography.label.copyWith(color: AppColors.accent)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Horizontal Carousel
            SizedBox(
              height: 100, // accommodate card height + shadow padding
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none, // Important to prevent clipping the beautiful soft shadows
                children: [
                  _buildCategoryBox('Food & Dining', 'Rs. 4,200', PhosphorIcons.forkKnife(PhosphorIconsStyle.light), PhosphorIcons.forkKnife(PhosphorIconsStyle.light)),
                  _buildCategoryBox('Transport', 'Rs. 1,200', PhosphorIcons.car(PhosphorIconsStyle.light), PhosphorIcons.car(PhosphorIconsStyle.light)),
                  _buildCategoryBox('Shopping', 'Rs. 8,400', PhosphorIcons.shoppingBag(PhosphorIconsStyle.light), PhosphorIcons.shoppingBag(PhosphorIconsStyle.light)),
                ],
              ),
            ),
            // Padding so you can scroll past the glass dock at the bottom
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBox(String title, String amount, IconData icon1, IconData watermark) {
    return Container(
      width: 270, // Premium wide card format
      height: 90,
      margin: const EdgeInsets.only(right: AppSpacing.md, bottom: 10), // Bottom margin allows shadow breathing room
      decoration: BoxDecoration(
        color: Colors.white,
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
              child: Icon(watermark, size: 80, color: AppColors.primary.withValues(alpha: 0.04)), // Subtle Charcoal watermark
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.03), // Soft Charcoal housing
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.08), width: 1.0), // Structured bezel
                    ),
                    child: Icon(icon1, color: AppColors.primary, size: 22), // Bold Charcoal foreground
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary.withValues(alpha: 0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(amount, style: AppTypography.h3.copyWith(fontSize: 20, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // ─── 4. The Floating Glass Dock ────────────────────────

  Widget _buildFloatingDock() {
    return SlideTransition(
      position: _dockSlide,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            bottom: MediaQuery.paddingOf(context).bottom > 0 ? MediaQuery.paddingOf(context).bottom : 32, // Hovers securely
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
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), // Ultra-diffraction for liquid effect
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20), // Hyper-translucent core
                      borderRadius: BorderRadius.circular(40),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.10), // Ultra-soft sheen
                          Colors.white.withValues(alpha: 0.01), // Near-invis bottom
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.95), // Razor-sharp specular rim
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _dockItem('Home', PhosphorIcons.compass(PhosphorIconsStyle.fill), PhosphorIcons.compass(PhosphorIconsStyle.light), true),
                        _dockItem('Analytics', PhosphorIcons.chartPieSlice(PhosphorIconsStyle.fill), PhosphorIcons.chartPieSlice(PhosphorIconsStyle.light), false),
                        const SizedBox(width: 70), // Center cutout bridging area for the FAB overlay
                        _dockItem('History', PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill), PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.light), false),
                        _dockItem('Profile', PhosphorIcons.user(PhosphorIconsStyle.fill), PhosphorIcons.user(PhosphorIconsStyle.light), false),
                      ],
                    ),
                  ),
                ),
              ),
              
              // The Overlapping Deep Charcoal FAB
              Positioned(
                bottom: 25, // Extends proudly above the visual edge of the glass pill
                child: GestureDetector(
                  onTap: () async {
                    HapticFeedback.mediumImpact();
                    setState(() => _isSheetOpen = true);
                    
                    final result = await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      useSafeArea: true,
                      barrierColor: Colors.black12,
                      builder: (context) => Stack(
                        children: [
                          Positioned.fill(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: const SizedBox.expand(),
                            ),
                          ),
                          const AddTransactionSheet(),
                        ],
                      ),
                    );

                    setState(() => _isSheetOpen = false);
                    
                    if (result == true) {
                      // Success toast or refresh logic
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: _isSheetOpen ? 68 : 64,
                    height: _isSheetOpen ? 68 : 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.accent, // Neon Brand Amber
                          const Color(0xFFE6A300), // Soft Matte Gold
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25), // Soft matte specular rim
                        width: 0.8,
                      ),
                      boxShadow: [
                        // Focused structural shadow
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                        // Soft volumetric glow
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.22),
                          blurRadius: 35,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 300),
                        turns: _isSheetOpen ? 0.125 : 0, // 45 degrees
                        child: Icon(
                          _isSheetOpen ? PhosphorIcons.x(PhosphorIconsStyle.bold) : PhosphorIcons.plus(PhosphorIconsStyle.bold), 
                          color: AppColors.primary, 
                          size: 30,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
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

  Widget _dockItem(String label, IconData activeIcon, IconData inactiveIcon, bool isActive) {
    final color = isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.25);
    final icon = isActive ? activeIcon : inactiveIcon;
    
    return Expanded(
      child: InkWell(
        onTap: () => HapticFeedback.selectionClick(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 24),
                  if (isActive)
                    Positioned(
                      top: -2,
                      right: -4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: isActive ? AppColors.primary : const Color(0xFF8C7E6E),
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
