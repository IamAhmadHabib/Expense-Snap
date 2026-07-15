import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _statsController;
  bool _darkMode = false;
  bool _weeklyDigest = true;
  bool _budgetAlerts = true;
  bool _spendingInsights = false;
  bool _dailyReminder = false;
  bool _notificationsEnabled = true;
  String _reminderTime = '9:00 PM';

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _entryController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _statsController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          builder: (context, value, child) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildSectionStaggered(
                          index: 0,
                          label: 'Personal Info',
                          showArrow: false,
                          onLabelTap: () =>
                              _showEditInfo(context, 'Full Name', 'Ahmad'),
                          children: [
                            _settingsRow(
                              PhosphorIcons.user(),
                              'Full Name',
                              'Ahmad',
                              onTap: () =>
                                  _showEditInfo(context, 'Full Name', 'Ahmad'),
                            ),
                            _settingsRow(
                              PhosphorIcons.envelope(),
                              'Email',
                              'ahmad@gmail.com',
                              isTappable: false,
                            ),
                          ],
                        ),
                        _buildSectionStaggered(
                          index: 1,
                          label: 'Budget',
                          children: [
                            _settingsRow(
                              PhosphorIcons.chartPieSlice(),
                              'Monthly Budget',
                              'Rs. 25,000',
                              onTap: () => _showMonthlyBudgetPicker(context),
                            ),
                            _settingsRow(
                              PhosphorIcons.listBullets(),
                              'Manage Categories',
                              '',
                              onTap: () => _showCategoryBudgets(context),
                            ),
                            _settingsRow(
                              PhosphorIcons.arrowsClockwise(),
                              'Budget resets on',
                              '1st',
                              onTap: () => _showResetDayPicker(context),
                            ),
                          ],
                        ),
                        _buildSectionStaggered(
                          index: 2,
                          label: 'Currency',
                          children: [
                            _settingsRow(
                              PhosphorIcons.currencyCircleDollar(),
                              'Currency',
                              'PKR',
                              onTap: () => _showCurrencyPicker(context),
                            ),
                          ],
                        ),
                        _buildSectionStaggered(
                          index: 3,
                          label: 'Notifications',
                          children: [
                            _settingsToggle(
                              PhosphorIcons.bellRinging(),
                              'Enable Notifications',
                              _notificationsEnabled,
                              (v) => setState(() => _notificationsEnabled = v),
                            ),
                            if (_notificationsEnabled) ...[
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                indent: 20,
                                endIndent: 20,
                              ),
                              _settingsToggle(
                                PhosphorIcons.bell(),
                                'Weekly digest',
                                _weeklyDigest,
                                (v) => setState(() => _weeklyDigest = v),
                              ),
                              _settingsToggle(
                                PhosphorIcons.warningCircle(),
                                'Budget alerts',
                                _budgetAlerts,
                                (v) => setState(() => _budgetAlerts = v),
                              ),
                              _settingsToggle(
                                PhosphorIcons.lightbulb(),
                                'Spending insights',
                                _spendingInsights,
                                (v) => setState(() => _spendingInsights = v),
                              ),
                              _settingsToggle(
                                PhosphorIcons.calendar(),
                                'Daily reminder',
                                _dailyReminder,
                                (v) {
                                  HapticFeedback.mediumImpact();
                                  setState(() => _dailyReminder = v);
                                },
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: _dailyReminder
                                    ? _settingsRow(
                                        PhosphorIcons.clock(),
                                        'Remind me at',
                                        _reminderTime,
                                        isNested: true,
                                        onTap: () => _showTimePicker(context),
                                      )
                                    : const SizedBox(
                                        width: double.infinity,
                                        height: 0.1,
                                      ),
                              ),
                            ] else ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  56,
                                  12,
                                  20,
                                  20,
                                ),
                                child: Text(
                                  'Enable notifications to receive monthly digest, budget alerts, and spending insights.',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        _buildSectionStaggered(
                          index: 4,
                          label: 'App',
                          children: [
                            _settingsRow(
                              PhosphorIcons.globe(),
                              'Language',
                              'English',
                              onTap: () => _showLanguagePicker(context),
                            ),
                            _settingsToggle(
                              PhosphorIcons.moon(),
                              'Dark Mode',
                              _darkMode,
                              (v) => setState(() => _darkMode = v),
                            ),
                            _settingsRow(
                              PhosphorIcons.star(),
                              'Rate Kharcha',
                              '',
                              onTap: () => _showRateKharcha(context),
                            ),
                            _settingsRow(
                              PhosphorIcons.paperPlaneTilt(),
                              'Send Feedback',
                              '',
                              onTap: () => _showFeedbackPicker(context),
                            ),
                            _settingsRow(
                              PhosphorIcons.info(),
                              'Version',
                              '1.0',
                              isTappable: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildDangerZone(),
                        const SizedBox(
                          height: 120,
                        ), // Bottom padding for floating dock
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Specialized Sheets & Pickers ---

  void _showCurrencyPicker(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CurrencyPickerContent(),
    );
  }

  void _showCategoryBudgets(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CategoryBudgetScreen()),
    );
  }

  void _showMonthlyBudgetPicker(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MonthlyBudgetSheet(),
    );
  }

  void _showEditInfo(BuildContext context, String field, String current) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditInfoSheet(field: field, current: current),
    );
  }

  void _showResetDayPicker(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SimplePickerSheet(
        title: 'Budget Reset Day',
        items: List.generate(
          31,
          (i) => '${i + 1}${_getDaySuffix(i + 1)} of every month',
        ),
        onSelected: (val) {
          HapticFeedback.lightImpact();
          // Logic to update reset day
        },
      ),
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  void _showTimePicker(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SimplePickerSheet(
        title: 'Daily Reminder',
        items: const [
          '8:00 AM',
          '9:00 AM',
          '12:00 PM',
          '6:00 PM',
          '9:00 PM',
          '10:00 PM',
          'Custom Time',
        ],
        onSelected: (val) async {
          if (val == 'Custom Time') {
            // Close the current picker first to avoid overlay issues
            Navigator.pop(context);

            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primary,
                      onPrimary: AppColors.textOnPrimary,
                      surface: AppColors.surface,
                      onSurface: AppColors.primary,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (time != null) {
              if (mounted) setState(() => _reminderTime = time.format(context));
            }
          } else {
            setState(() => _reminderTime = val);
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _SimplePickerSheet(
        title: 'Language',
        items: const ['English', 'Urdu', 'Arabic', 'French', 'Spanish'],
        onSelected: (val) {},
      ),
    );
  }

  void _showRateKharcha(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FeedbackSheet(
        title: 'Enjoying Kharcha?',
        subtitle: 'Your rating helps us grow and improve for everyone.',
        icon: PhosphorIcons.star(PhosphorIconsStyle.fill),
        buttonText: 'Rate on Play Store',
      ),
    );
  }

  void _showFeedbackPicker(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FeedbackSheet(
        title: 'Send Feedback',
        subtitle:
            'Found a bug or have a suggestion? We would love to hear from you.',
        icon: PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill),
        buttonText: 'Send via Email',
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Log out of Kharcha?', style: AppTypography.h3),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: const BorderSide(color: AppColors.profileDivider),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTypography.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Log Out', style: AppTypography.label),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsRow(
    IconData icon,
    String title,
    String value, {
    bool isTappable = true,
    bool isNested = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isTappable ? onTap ?? () => HapticFeedback.lightImpact() : null,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: EdgeInsets.only(
          left: isNested ? 56 : 20,
          right: 20,
          top: 18,
          bottom: 18,
        ),
        child: Row(
          children: [
            if (!isNested) ...[
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.profileSubtext,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (isTappable) ...[
              const SizedBox(width: 8),
              Icon(
                PhosphorIcons.caretRight(),
                size: 16,
                color: AppColors.profileChevron,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _settingsToggle(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              onChanged(v);
            },
            activeColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE0E0E0),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionStaggered({
    required int index,
    required String label,
    List<Widget>? children,
    VoidCallback? onLabelTap,
    bool showArrow = true,
  }) {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        final animation = CurvedAnimation(
          parent: _entryController,
          curve: Interval(
            (0.4 + (index * 0.08)).clamp(0.0, 0.9),
            (0.8 + (index * 0.04)).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        );
        return Transform.translate(
          offset: Offset(0, 12 * (1 - animation.value)),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onLabelTap,
            child: Row(
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (onLabelTap != null && showArrow) ...[
                  const SizedBox(width: 4),
                  Icon(
                    PhosphorIcons.caretRight(),
                    size: 12,
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.sectionCard,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(children: children ?? []),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        final animation = CurvedAnimation(
          parent: _entryController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
        );
        return Transform.translate(
          offset: Offset(0, -16 * (1 - animation.value)),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 72, 24, 40),
        decoration: const BoxDecoration(
          color: AppColors.headerCard,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(48)),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.amberGold.withValues(alpha: 0.45),
                        blurRadius: 40,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Color(0xFF242018),
                    child: Icon(
                      PhosphorIcons.user(PhosphorIconsStyle.fill),
                      color: AppColors.textOnPrimary,
                      size: 40,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => HapticFeedback.mediumImpact(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.amberGold,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIcons.pencilSimple(PhosphorIconsStyle.bold),
                      size: 14,
                      color: AppColors.headerCard,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showEditInfo(context, 'Full Name', 'Ahmad'),
              child: Text(
                'Ahmad',
                style: AppTypography.h2.copyWith(
                  color: AppColors.surface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              'ahmad@gmail.com',
              style: AppTypography.caption.copyWith(
                color: AppColors.surface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            _buildStatsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statItem('47', 'Expenses'),
        _verticalDivider(),
        _statItem('Rs.24k', 'Spent'),
        _verticalDivider(),
        _statItem('8', 'Categories'),
      ],
    );
  }

  Widget _statItem(String value, String label) {
    return AnimatedBuilder(
      animation: _statsController,
      builder: (context, child) {
        return Column(
          children: [
            Text(
              value,
              style: AppTypography.h3.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.overline.copyWith(
                color: AppColors.surface.withValues(alpha: 0.6),
                fontSize: 12,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _verticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: AppColors.surface.withValues(alpha: 0.1),
    );
  }

  Widget _buildDangerZone() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.sectionCard,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _settingsRow(
            PhosphorIcons.signOut(),
            'Log Out',
            '',
            isTappable: true,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.sectionCard,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _showDeleteConfirmation(context),
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.trash(),
                    size: 22,
                    color: AppColors.dangerMuted,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Delete Account',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.dangerMuted,
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

  void _showDeleteConfirmation(BuildContext context) {
    HapticFeedback.heavyImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeleteSheetContent(),
    );
  }
}

class _MonthlyBudgetSheet extends StatefulWidget {
  @override
  State<_MonthlyBudgetSheet> createState() => _MonthlyBudgetSheetState();
}

class _MonthlyBudgetSheetState extends State<_MonthlyBudgetSheet> {
  String _amount = '25000';

  void _onKeyPress(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (key == 'delete') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (key == '.') {
        if (!_amount.contains('.')) _amount += '.';
      } else {
        if (_amount == '0') {
          _amount = key;
        } else if (_amount.length < 10) {
          _amount += key;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double amountValue = double.tryParse(_amount) ?? 0;
    final String formatted = NumberFormat('#,###.##').format(amountValue);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    PhosphorIcons.x(PhosphorIconsStyle.bold),
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Monthly Budget',
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          const SizedBox(height: 48),
          Text(
            'How much do you want to spend this month?',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.translate(
                offset: const Offset(0, 10),
                child: Text(
                  'Rs.',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatted,
                style: AppTypography.display.copyWith(
                  fontSize: 64,
                  height: 1.0,
                  color: AppColors.primary,
                  letterSpacing: -2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const _BlinkingCursor(),
            ],
          ),

          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildNumberPad(),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Confirm Budget',
                    style: AppTypography.button.copyWith(
                      color: AppColors.surface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildNumberPad() {
    final List<String> keys = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '.',
      '0',
      'delete',
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 1.6,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: keys.map((key) {
        return InkWell(
          onTap: () => _onKeyPress(key),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: key == 'delete'
                ? Icon(
                    PhosphorIcons.backspace(),
                    color: AppColors.primary,
                    size: 32,
                  )
                : Text(
                    key,
                    style: AppTypography.h1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontSize: 36,
                    ),
                  ),
          ),
        );
      }).toList(),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(width: 4, height: 48, color: AppColors.accent),
    );
  }
}

class CategoryBudgetScreen extends StatelessWidget {
  const CategoryBudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'icon': PhosphorIcons.hamburger(), 'label': 'Food & Dining'},
      {'icon': PhosphorIcons.car(), 'label': 'Transport'},
      {'icon': PhosphorIcons.shoppingBag(), 'label': 'Shopping'},
      {'icon': PhosphorIcons.pill(), 'label': 'Health'},
      {'icon': PhosphorIcons.filmSlate(), 'label': 'Entertainment'},
      {'icon': PhosphorIcons.house(), 'label': 'Rent & Utilities'},
      {'icon': PhosphorIcons.gift(), 'label': 'Gifts & Donations'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft(), color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Category',
          style: AppTypography.h3.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == categories.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 40),
                    child: GestureDetector(
                      onTap: () => _showAddCategory(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 24,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIcons.plus(PhosphorIconsStyle.bold),
                              color: AppColors.surface,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Add Custom Category',
                              style: AppTypography.button.copyWith(
                                color: AppColors.surface,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final cat = categories[index];
                return _StaggeredItem(
                  delay: index * 40,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sectionCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            cat['icon'] as IconData,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            cat['label'] as String,
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: categories.length + 1),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategory(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddCategorySheet(),
    );
  }
}

class _CurrencyPickerContent extends StatefulWidget {
  @override
  State<_CurrencyPickerContent> createState() => _CurrencyPickerContentState();
}

class _CurrencyPickerContentState extends State<_CurrencyPickerContent> {
  String _selected = 'PKR';
  String _searchQuery = '';

  final List<Map<String, String>> _allCurrencies = [
    {'code': 'USD', 'name': 'United States Dollar', 'symbol': r'$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound Sterling', 'symbol': '£'},
    {'code': 'PKR', 'name': 'Pakistani Rupee', 'symbol': 'Rs'},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
    {'code': 'AED', 'name': 'United Arab Emirates Dirham', 'symbol': 'د.إ'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': '﷼'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': r'$'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': r'$'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'Fr'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': r'$'},
    {'code': 'HKD', 'name': 'Hong Kong Dollar', 'symbol': r'$'},
    {'code': 'TRY', 'name': 'Turkish Lira', 'symbol': '₺'},
    {'code': 'RUB', 'name': 'Russian Ruble', 'symbol': '₽'},
    {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': r'R$'},
    {'code': 'ZAR', 'name': 'South African Rand', 'symbol': 'R'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'RM'},
    {'code': 'THB', 'name': 'Thai Baht', 'symbol': '฿'},
    {'code': 'IDR', 'name': 'Indonesian Rupiah', 'symbol': 'Rp'},
    {'code': 'PHP', 'name': 'Philippine Peso', 'symbol': '₱'},
    {'code': 'VND', 'name': 'Vietnamese Dong', 'symbol': '₫'},
    {'code': 'KRW', 'name': 'South Korean Won', 'symbol': '₩'},
    {'code': 'QAR', 'name': 'Qatari Rial', 'symbol': '﷼'},
    {'code': 'KWD', 'name': 'Kuwaiti Dinar', 'symbol': 'د.ك'},
    {'code': 'OMR', 'name': 'Omani Rial', 'symbol': '﷼'},
    {'code': 'BHD', 'name': 'Bahraini Dinar', 'symbol': '.د.ب'},
    {'code': 'NZD', 'name': 'New Zealand Dollar', 'symbol': r'$'},
    {'code': 'SEK', 'name': 'Swedish Krona', 'symbol': 'kr'},
    {'code': 'NOK', 'name': 'Norwegian Krone', 'symbol': 'kr'},
    {'code': 'DKK', 'name': 'Danish Krone', 'symbol': 'kr'},
    {'code': 'MXN', 'name': 'Mexican Peso', 'symbol': r'$'},
    {'code': 'ARS', 'name': 'Argentine Peso', 'symbol': r'$'},
    {'code': 'CLP', 'name': 'Chilean Peso', 'symbol': r'$'},
    {'code': 'EGP', 'name': 'Egyptian Pound', 'symbol': 'E£'},
    {'code': 'LKR', 'name': 'Sri Lankan Rupee', 'symbol': 'Rs'},
    {'code': 'BDT', 'name': 'Bangladeshi Taka', 'symbol': '৳'},
    {'code': 'NPR', 'name': 'Nepalese Rupee', 'symbol': 'Rs'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _allCurrencies.where((c) {
      final q = _searchQuery.toLowerCase();
      return c['name']!.toLowerCase().contains(q) ||
          c['code']!.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(PhosphorIcons.arrowLeft(), color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                'Currency',
                style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Search 180+ currencies...',
                hintStyle: TextStyle(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
                prefixIcon: Icon(
                  PhosphorIcons.magnifyingGlass(),
                  color: AppColors.primary.withValues(alpha: 0.4),
                  size: 20,
                ),
                border: InputBorder.none,
                isDense: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final curr = filtered[index];
                final isSelected = _selected == curr['code'];

                return _StaggeredItem(
                  delay: index * 30,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.08),
                        width: 1.5,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _selected = curr['code']!);
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.surface.withValues(alpha: 0.1)
                                    : AppColors.background,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  curr['symbol']!,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected
                                        ? AppColors.surface
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    curr['code']!,
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: isSelected
                                          ? AppColors.surface
                                          : AppColors.primary,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  Text(
                                    curr['name']!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isSelected
                                          ? AppColors.surface.withValues(
                                              alpha: 0.7,
                                            )
                                          : AppColors.primary.withValues(
                                              alpha: 0.5,
                                            ),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                PhosphorIcons.checkCircle(
                                  PhosphorIconsStyle.fill,
                                ),
                                color: AppColors.surface,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 32, top: 12),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Confirm Selection',
                    style: AppTypography.button.copyWith(
                      color: AppColors.surface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteSheetContent extends StatefulWidget {
  @override
  State<_DeleteSheetContent> createState() => _DeleteSheetContentState();
}

class _DeleteSheetContentState extends State<_DeleteSheetContent> {
  final TextEditingController _controller = TextEditingController();
  bool _canDelete = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              PhosphorIcons.warning(PhosphorIconsStyle.fill),
              color: AppColors.dangerMuted,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text('Wait! This is permanent.', style: AppTypography.h2),
            const SizedBox(height: 8),
            Text(
              'This will permanently delete all your data. This cannot be undone.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 32),
            Text(
              'Type "DELETE" to confirm',
              style: AppTypography.overline.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              onChanged: (v) => setState(() => _canDelete = v == 'DELETE'),
              decoration: InputDecoration(
                hintText: 'DELETE',
                hintStyle: TextStyle(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _canDelete ? () {} : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerMuted,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.12,
                ),
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                'Delete Forever',
                style: AppTypography.button.copyWith(
                  color: _canDelete
                      ? AppColors.textOnPrimary
                      : AppColors.primary.withValues(alpha: 0.26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  final Widget child;
  final int delay;

  const _StaggeredItem({required this.child, required this.delay});

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _SimplePickerSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final Function(String) onSelected;

  const _SimplePickerSheet({
    required this.title,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),
          Text(title, style: AppTypography.h3),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(color: AppColors.primary.withValues(alpha: 0.05)),
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  leading: items[index] == 'Custom Time'
                      ? Icon(
                          PhosphorIcons.clockCounterClockwise(),
                          color: AppColors.primary,
                        )
                      : Icon(
                          PhosphorIcons.clock(),
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                  title: Text(
                    items[index],
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: items[index] == 'Custom Time'
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: items[index] == 'Custom Time'
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () => onSelected(items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String buttonText;

  const _FeedbackSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppColors.amberGold),
          ),
          const SizedBox(height: 24),
          Text(title, style: AppTypography.h2),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
          if (title.contains('Enjoying')) ...[
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    PhosphorIcons.star(PhosphorIconsStyle.fill),
                    color: AppColors.amberGold,
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: Text(buttonText, style: AppTypography.button),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Maybe Later',
              style: AppTypography.label.copyWith(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditInfoSheet extends StatefulWidget {
  final String field;
  final String current;

  const _EditInfoSheet({required this.field, required this.current});

  @override
  State<_EditInfoSheet> createState() => _EditInfoSheetState();
}

class _EditInfoSheetState extends State<_EditInfoSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.current);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Edit ${widget.field}', style: AppTypography.h2),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(24),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text('Save Changes', style: AppTypography.button),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet();

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final TextEditingController _controller = TextEditingController();
  IconData _selectedIcon = PhosphorIcons.tag();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('Create Category', style: AppTypography.h2),
            const SizedBox(height: 24),
            Row(
              children: [
                GestureDetector(
                  onTap: () => HapticFeedback.lightImpact(),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(_selectedIcon, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Category Name',
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(24),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text('Add Category', style: AppTypography.button),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
