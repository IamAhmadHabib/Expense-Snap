import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';

// ─────────────────────────────────────────────────────────────
// Category model
// ─────────────────────────────────────────────────────────────
class _Category {
  final String name;
  final IconData icon;
  const _Category(this.name, this.icon);
}

final List<_Category> _categories = [
  _Category('Dining',      PhosphorIcons.hamburger(PhosphorIconsStyle.regular)),
  _Category('Transport',   PhosphorIcons.car(PhosphorIconsStyle.regular)),
  _Category('Shopping',    PhosphorIcons.shoppingBag(PhosphorIconsStyle.regular)),
  _Category('Entmnt',      PhosphorIcons.popcorn(PhosphorIconsStyle.regular)),
  _Category('Health',      PhosphorIcons.heartbeat(PhosphorIconsStyle.regular)),
  _Category('Utilities',   PhosphorIcons.lightning(PhosphorIconsStyle.regular)),
  _Category('Education',   PhosphorIcons.graduationCap(PhosphorIconsStyle.regular)),
  _Category('Travel',      PhosphorIcons.airplane(PhosphorIconsStyle.regular)),
  _Category('Groceries',   PhosphorIcons.shoppingCart(PhosphorIconsStyle.regular)),
  _Category('Other',       PhosphorIcons.dotsThree(PhosphorIconsStyle.regular)),
];


// ─────────────────────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────────────────────
class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet>
    with TickerProviderStateMixin {
  String _amount = '0';
  int _activeTab = 0;
  _Category _selectedCategory = _categories[0];
  String _selectedPayment = 'Cash';
  bool _isSaving = false;
  bool _showNumPad = false;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Text controllers
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _noteFocus = FocusNode();

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _activeTab);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _noteController.dispose();
    _descriptionFocus.dispose();
    _noteFocus.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_activeTab != index) {
      HapticFeedback.lightImpact();
      setState(() {
        _activeTab = index;
        _showNumPad = false;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

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

  Future<void> _handleSave() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) Navigator.pop(context, true);
  }

  // ── Category Picker ──────────────────────────────────────
  void _openCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setPickerState) {
          return _CategoryPickerSheet(
            selected: _selectedCategory,
            onSelected: (cat) {
              setPickerState(() => _selectedCategory = cat);
              setState(() => _selectedCategory = cat);
              HapticFeedback.lightImpact();
            },
          );
        },
      ),
    );
  }

  // ── Premium Date Picker ──────────────────────────────────
  Future<void> _openDatePicker() async {
    HapticFeedback.lightImpact();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: const Color(0xFFFAF9F6),
              onSurface: AppColors.primary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: AppTypography.button.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32)),
              ),
              backgroundColor: Color(0xFFFAF9F6),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── Premium Time Picker ──────────────────────────────────
  Future<void> _openTimePicker() async {
    HapticFeedback.lightImpact();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: const Color(0xFFFAF9F6),
              onSurface: AppColors.primary,
              secondary: AppColors.accent,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color(0xFFFAF9F6),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              dayPeriodColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : Colors.white),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? Colors.white
                      : AppColors.primary),
              hourMinuteColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? AppColors.primary
                      : Colors.white),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? Colors.white
                      : AppColors.primary),
              dialBackgroundColor: Colors.white,
              dialHandColor: AppColors.primary,
              dialTextColor: WidgetStateColor.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? Colors.white
                      : AppColors.primary),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32)),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: AppTypography.button.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String get _formattedDate {
    final now = DateTime.now();
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) return 'Today';
    return DateFormat('MMM d, yyyy').format(_selectedDate);
  }

  String get _formattedTime {
    final hour = _selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod;
    final min = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    // This value represents the keyboard height
    final double keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      // Allow the sheet to shift upward when the keyboard is open
      padding: EdgeInsets.only(bottom: keyboardPadding),
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFFAF9F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48, height: 6,
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
                  icon: Icon(PhosphorIcons.x(PhosphorIconsStyle.bold), color: AppColors.primary),
                ),
                Text('Add Transaction', style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Tabs — always visible except when numpad is active
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            child: _showNumPad
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: _buildTabs(),
                  ),
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _showNumPad
                  ? _buildInputView()
                  : PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        if (!_showNumPad) {
                          FocusScope.of(context).unfocus(); // Dismiss keyboard on swipe
                          setState(() => _activeTab = index);
                          HapticFeedback.selectionClick();
                        }
                      },
                      children: [
                        _buildFormView(keyboardPadding > 0),
                        const _ScanTabView(key: ValueKey('scan_view')),
                        const _VoiceTabView(key: ValueKey('voice_view')),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────── FORM VIEW ───────────────────────────────
  Widget _buildFormView(bool isKeyboardActive) {
    return SingleChildScrollView(
      key: const ValueKey('form_view'),
      // Only allow scrolling if the keyboard is pushing content
      physics: isKeyboardActive ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showNumPad = true),
            child: _buildHeroAmount(),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _openCategoryPicker,
            child: _buildCategorySelector(),
          ),
          const SizedBox(height: 10),
          _buildTextInputField(
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            placeholder: 'What was it for?',
            icon: PhosphorIcons.pencilLine(PhosphorIconsStyle.light),
          ),
          const SizedBox(height: 10),
          _buildDateTimeRow(),
          const SizedBox(height: 10),
          _buildPaymentSelector(),
          const SizedBox(height: 10),
          _buildTextInputField(
            controller: _noteController,
            focusNode: _noteFocus,
            placeholder: 'Add a note (optional)',
            icon: PhosphorIcons.note(PhosphorIconsStyle.light),
            trailing: Text('optional', style: AppTypography.overline.copyWith(color: AppColors.primary.withValues(alpha: 0.3))),
          ),
          // When keyboard is up, we don't need a massive spacer
          isKeyboardActive ? const SizedBox(height: 32) : const SizedBox(height: 60), 
          _buildSaveButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─────────────────────────────── INPUT VIEW ──────────────────────────────
  Widget _buildInputView() {
    return Padding(
      key: const ValueKey('input_view'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildHeroAmount(),
          const SizedBox(height: 48),
          _buildNumberPad(),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              setState(() => _showNumPad = false);
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
                    blurRadius: 15, offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Confirm Amount',
                  style: AppTypography.button.copyWith(
                    color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w800, letterSpacing: 0.8,
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

  // ─────────────────────────────── TABS ────────────────────────────────────
  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DDD0), width: 1),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: FractionalOffset(_activeTab * 0.5, 0),
            child: FractionallySizedBox(
              widthFactor: 0.33,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Row(
            children: [
              _tabItem('Manual', PhosphorIcons.pencilSimple(), 0),
              _tabItem('Scan', PhosphorIcons.scan(), 1),
              _tabItem('Voice', PhosphorIcons.microphone(), 2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String label, IconData icon, int index) {
    final bool isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabTapped(index),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 400),
                scale: isActive ? 1.15 : 1.0,
                curve: Curves.elasticOut,
                child: Icon(icon,
                    color: AppColors.primary.withValues(alpha: isActive ? 1.0 : 0.4),
                    size: 18),
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: AppTypography.caption.copyWith(
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: isActive ? 1.0 : 0.4))),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────── HERO AMOUNT ─────────────────────────────
  Widget _buildHeroAmount() {
    final double amountValue = double.tryParse(_amount) ?? 0;
    final String formatted = amountValue >= 1000000
        ? NumberFormat.compact().format(amountValue)
        : NumberFormat('#,###.##').format(amountValue);

    return Column(
      children: [
        Text('How much did you spend?',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textPrimary.withValues(alpha: 0.6))),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.translate(
              offset: const Offset(0, 10),
              child: Text('Rs.',
                  style: AppTypography.h3
                      .copyWith(color: AppColors.primary.withValues(alpha: 0.4))),
            ),
            const SizedBox(width: 12),
            Text(formatted,
                style: AppTypography.display.copyWith(
                    fontSize: 72,
                    height: 1.0,
                    color: AppColors.primary,
                    letterSpacing: -2,
                    fontWeight: FontWeight.w900)),
            const _BlinkingCursor(),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────── NUMBER PAD ──────────────────────────────
  Widget _buildNumberPad() {
    final List<String> keys = [
      '1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', 'delete'
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
                ? Icon(PhosphorIcons.backspace(), color: AppColors.primary, size: 32)
                : Text(key,
                    style: AppTypography.h1.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 36)),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────── CATEGORY ────────────────────────────────
  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8DDD0), width: 1.2)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: Icon(_selectedCategory.icon,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(_selectedCategory.name,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          Icon(PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
              color: AppColors.primary.withValues(alpha: 0.3), size: 16),
        ],
      ),
    );
  }

  // ─────────────────────────────── TEXT INPUT ──────────────────────────────
  Widget _buildTextInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    required IconData icon,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DDD0).withValues(alpha: 0.7), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary.withValues(alpha: 0.4), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: AppTypography.body.copyWith(color: AppColors.primary),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: AppTypography.body
                    .copyWith(color: AppColors.primary.withValues(alpha: 0.4)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );
  }

  // ─────────────────────────────── DATE / TIME ROW ─────────────────────────
  Widget _buildDateTimeRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _openDatePicker,
            child: _buildDisplayField(
              label: _formattedDate,
              icon: PhosphorIcons.calendar(PhosphorIconsStyle.light),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: _openTimePicker,
            child: _buildDisplayField(
              label: _formattedTime,
              icon: PhosphorIcons.clock(PhosphorIconsStyle.light),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayField({required String label, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DDD0).withValues(alpha: 0.7), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary.withValues(alpha: 0.5), size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────── PAYMENT CHIPS ───────────────────────────
  Widget _buildPaymentSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ['Cash', 'Card', 'Online'].map((method) {
        return Expanded(
          child: _PaymentChip(
            label: method,
            isSelected: _selectedPayment == method,
            onTap: () => setState(() => _selectedPayment = method),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────── SAVE BUTTON ─────────────────────────────
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _handleSave,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0.0, end: _isSaving ? 1.0 : 0.0),
        builder: (context, value, child) {
          final double fullWidth = MediaQuery.of(context).size.width - 48;
          final double currentWidth = fullWidth - ((fullWidth - 120) * value);
          return Container(
            width: currentWidth,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20 + (10 * value)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20, offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: (1.0 - value * 2.0).clamp(0.0, 1.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIcons.floppyDisk(PhosphorIconsStyle.fill),
                            color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Text('Save Expense',
                            style: AppTypography.h3.copyWith(
                                color: Colors.white, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: ((value - 0.5) * 2.0).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.5 + (0.5 * ((value - 0.5) * 2.0).clamp(0.0, 1.0)),
                      child: Icon(PhosphorIcons.check(PhosphorIconsStyle.bold),
                          color: Colors.white, size: 32),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Category Picker Bottom Sheet
// ─────────────────────────────────────────────────────────────
class _CategoryPickerSheet extends StatelessWidget {
  final _Category selected;
  final ValueChanged<_Category> onSelected;
  const _CategoryPickerSheet({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 24, right: 24, bottom: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF9F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 48, height: 6,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Choose Category',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final bool isSelected = cat.name == selected.name;
              return GestureDetector(
                onTap: () => onSelected(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : const Color(0xFFE8DDD0).withValues(alpha: 0.5),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat.icon,
                        color: isSelected ? Colors.white : AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cat.name,
                        style: AppTypography.overline.copyWith(
                          color: isSelected ? Colors.white : AppColors.primary,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 10,
                          letterSpacing: 0.0,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Blinking Cursor
// ─────────────────────────────────────────────────────────────
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();
  @override
  _BlinkingCursorState createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
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
      child: Container(
        margin: const EdgeInsets.only(left: 6, top: 4),
        width: 4, height: 60,
        decoration: BoxDecoration(
            color: AppColors.accent, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Payment Chip
// ─────────────────────────────────────────────────────────────
class _PaymentChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _PaymentChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  State<_PaymentChip> createState() => _PaymentChipState();
}

class _PaymentChipState extends State<_PaymentChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.94), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.03), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_PaymentChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => HapticFeedback.lightImpact(),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected ? AppColors.primary : const Color(0xFFE8DDD0),
              width: 1.2,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTypography.caption.copyWith(
                color: widget.isSelected ? Colors.white : AppColors.primary,
                fontWeight: widget.isSelected ? FontWeight.w900 : FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Voice State Machine
// ─────────────────────────────────────────────────────────────
enum _VoiceState { idle, listening, processing, success, error, correcting }

// ─────────────────────────────────────────────────────────────
// Voice Tab View — "The Evolving Orb"
// ─────────────────────────────────────────────────────────────
class _VoiceTabView extends StatefulWidget {
  const _VoiceTabView({super.key});

  @override
  State<_VoiceTabView> createState() => _VoiceTabViewState();
}

class _VoiceTabViewState extends State<_VoiceTabView> with TickerProviderStateMixin {
  _VoiceState _state = _VoiceState.idle;
  int _hintIndex = 0;

  // Animation controllers
  late AnimationController _glowController;   // Ambient glow pulse
  late AnimationController _waveController;   // Waveform bars
  late AnimationController _dotsController;   // Processing dots

  final List<String> _hints = [
    'Maine 300 rupay burger pe kharch kiye',
    'Spent 1200 on Uber',
    '450 at Starbucks just now',
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _startHintCycling();
  }

  void _startHintCycling() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
      _startHintCycling();
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _waveController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_state == _VoiceState.idle || _state == _VoiceState.error) {
        _state = _VoiceState.listening;
        _simulateVoiceCapture();
      } else if (_state == _VoiceState.listening) {
        _state = _VoiceState.processing;
      }
    });
  }

  void _simulateVoiceCapture() {
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted || _state != _VoiceState.listening) return;
      setState(() => _state = _VoiceState.processing);

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        HapticFeedback.heavyImpact();
        setState(() => _state = _VoiceState.success);
      });
    });
  }

  // ── Layout ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool showOrb = _state != _VoiceState.success && _state != _VoiceState.correcting;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: showOrb
          ? _buildRecordingView()
          : _buildResultView(),
    );
  }

  // ── Recording View (Idle / Listening / Processing) ─────────
  Widget _buildRecordingView() {
    return Column(
      key: const ValueKey('recording'),
      children: [
        const SizedBox(height: 60),
        _buildOrb(),
        const SizedBox(height: 40),
        _buildStatusText(),
        const SizedBox(height: 16),
        if (_state == _VoiceState.listening)
          _buildWaveform()
        else if (_state == _VoiceState.idle || _state == _VoiceState.error)
          _buildHintText(),
      ],
    );
  }

  // ── The Orb ────────────────────────────────────────────────
  Widget _buildOrb() {
    final bool isActive = _state == _VoiceState.listening || _state == _VoiceState.processing;
    final Color orbColor = isActive ? AppColors.accent : AppColors.primary;

    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          final double glowPulse = _glowController.value;
          final double glowSize = isActive ? 20 + (glowPulse * 25) : 10 + (glowPulse * 8);
          final double glowOpacity = isActive ? 0.25 + (glowPulse * 0.15) : 0.08 + (glowPulse * 0.04);

          return Container(
            width: 180,
            height: 180,
            alignment: Alignment.center,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ambient Glow
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: orbColor.withValues(alpha: glowOpacity),
                        blurRadius: glowSize * 2,
                        spreadRadius: glowSize,
                      ),
                    ],
                  ),
                ),

                // The Orb itself
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        orbColor,
                        Color.lerp(orbColor, Colors.black, 0.15)!,
                      ],
                      center: const Alignment(-0.2, -0.2),
                      radius: 0.9,
                    ),
                  ),
                  child: Center(
                    child: _state == _VoiceState.processing
                        ? _buildProcessingDots()
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Icon(
                              PhosphorIcons.microphone(PhosphorIconsStyle.fill),
                              key: ValueKey(_state),
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Processing Dots (typing-indicator style) ──────────────
  Widget _buildProcessingDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final double phase = (_dotsController.value + i * 0.2) % 1.0;
            final double scale = 0.6 + (math.sin(phase * math.pi) * 0.4);
            final double opacity = 0.4 + (math.sin(phase * math.pi) * 0.6);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // ── Status Text ───────────────────────────────────────────
  Widget _buildStatusText() {
    String text;
    switch (_state) {
      case _VoiceState.idle:
        text = 'Tap to speak';
        break;
      case _VoiceState.listening:
        text = 'Listening...';
        break;
      case _VoiceState.processing:
        text = 'Understanding...';
        break;
      case _VoiceState.error:
        text = 'Didn\'t catch that — try again';
        break;
      default:
        text = '';
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        text,
        key: ValueKey(text),
        style: AppTypography.body.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.primary.withValues(alpha: _state == _VoiceState.idle ? 0.5 : 0.8),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── Waveform Bars ────────────────────────────────────────
  Widget _buildWaveform() {
    return SizedBox(
      height: 44,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(24, (i) {
              final double phase = _waveController.value * 2 * math.pi;
              final double distFromCenter = (i - 11.5).abs() / 11.5;
              final double envelope = 1.0 - (distFromCenter * distFromCenter);

              final double wave = (math.sin(phase + i * 0.35) * 0.5 + 0.5) * envelope;
              final double secondary = (math.sin(phase * 1.3 + i * 0.6) * 0.3 + 0.5) * envelope;
              final double combined = (wave * 0.65 + secondary * 0.35);

              final double barHeight = (4 + combined * 34).clamp(3.0, 38.0);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 3,
                height: barHeight,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.6 + combined * 0.4),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // ── Hint Text ────────────────────────────────────────────
  Widget _buildHintText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Text(
            'Try saying',
            style: AppTypography.caption.copyWith(
              color: AppColors.primary.withValues(alpha: 0.35),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: Text(
              '"${_hints[_hintIndex]}"',
              key: ValueKey(_hintIndex),
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.primary.withValues(alpha: 0.55),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Result View (Success / Correcting) ─────────────────────
  Widget _buildResultView() {
    return SingleChildScrollView(
      key: const ValueKey('result'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Amount Hero ──
          Center(
            child: Column(
              children: [
                _state == _VoiceState.correcting
                    ? SizedBox(
                        width: 220,
                        child: TextField(
                          controller: TextEditingController(text: '300'),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: AppTypography.h1.copyWith(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                            height: 1.2,
                            color: AppColors.primary,
                          ),
                          decoration: InputDecoration(
                            prefixText: 'Rs. ',
                            prefixStyle: AppTypography.h1.copyWith(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              height: 1.2,
                              color: AppColors.primary,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.08)),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.08)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.12)),
                            ),
                          ),
                        ),
                      )
                    : Text(
                        'Rs. 300',
                        style: AppTypography.h1.copyWith(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Food & Dining',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Details ──
          _detailRow(
            PhosphorIcons.notepad(PhosphorIconsStyle.fill),
            'Note',
            'Burger',
          ),
          _detailRow(
            PhosphorIcons.calendar(PhosphorIconsStyle.fill),
            'Date',
            'Today, 2:45 PM',
          ),
          _detailRow(
            PhosphorIcons.wallet(PhosphorIconsStyle.fill),
            'Account',
            'Cash',
          ),

          const SizedBox(height: 16),

          // Original transcript
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.quotes(PhosphorIconsStyle.fill), size: 14, color: AppColors.primary.withValues(alpha: 0.2)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Maine 300 rupay burger pe kharch kiye',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Action Buttons ──
          Row(
            children: [
              // Edit / Done toggle
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _state = _state == _VoiceState.correcting
                          ? _VoiceState.success
                          : _VoiceState.correcting;
                    });
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF0EBE4), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _state == _VoiceState.correcting ? 'Done' : 'Edit',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Save button
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Save Expense',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Detail Row ──────────────────────────────────────────
  Widget _detailRow(IconData icon, String label, String value) {
    final bool isEditing = _state == _VoiceState.correcting;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE8DDD0).withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.85)),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          isEditing
              ? SizedBox(
                  width: 140,
                  height: 24,
                  child: TextField(
                    controller: TextEditingController(text: value),
                    textAlign: TextAlign.end,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.08)),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.08)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.12)),
                      ),
                    ),
                  ),
                )
              : Text(
                  value,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Scan State Machine
// ─────────────────────────────────────────────────────────────
enum _ScanState { idle, detecting, processing, success, error }

// ─────────────────────────────────────────────────────────────
// Scan Tab View
// ─────────────────────────────────────────────────────────────
class _ScanTabView extends StatefulWidget {
  const _ScanTabView({super.key});

  @override
  State<_ScanTabView> createState() => _ScanTabViewState();
}

class _ScanTabViewState extends State<_ScanTabView>
    with TickerProviderStateMixin {
  late final AnimationController _openController;
  late final AnimationController _beamController;
  late final AnimationController _bracketController;

  late final Animation<double> _openScale;
  late final Animation<double> _openOpacity;
  late final Animation<double> _beamY;
  late final Animation<double> _bracketPulse;

  bool _hasPermission = false; // Simulated permission state
  _ScanState _state = _ScanState.idle;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();

    _openController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _openScale = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _openController, curve: Curves.easeOutCubic));
    _openOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _openController,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));

    _beamController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _beamY = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _beamController, curve: Curves.easeInOut));

    _bracketController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _bracketPulse = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _bracketController, curve: Curves.easeInOut));

    if (_hasPermission) {
      _startOpenAnimation();
    }
  }

  void _startOpenAnimation() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) {
        _openController.forward().then((_) {
          if (mounted) HapticFeedback.mediumImpact();
        });
      }
    });
  }

  void _requestPermission() {
    HapticFeedback.mediumImpact();
    // Simulate luxurious permission delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _hasPermission = true);
        _startOpenAnimation();
      }
    });
  }

  @override
  void dispose() {
    _openController.dispose();
    _beamController.dispose();
    _bracketController.dispose();
    super.dispose();
  }

  String get _instructionText {
    switch (_state) {
      case _ScanState.idle:       return 'Point camera at a receipt or screenshot';
      case _ScanState.detecting:  return 'Receipt found — hold steady...';
      case _ScanState.processing: return 'Reading your receipt...';
      case _ScanState.success:    return 'Got it! Review your expense ✓';
      case _ScanState.error:      return "Couldn't read receipt — try Upload from Gallery";
    }
  }

  void _simulateDetection() {
    if (_state != _ScanState.idle) return;
    HapticFeedback.lightImpact();
    setState(() => _state = _ScanState.detecting);

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      HapticFeedback.lightImpact();
      setState(() => _state = _ScanState.processing);
      _beamController.stop();

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        setState(() => _state = _ScanState.success);
        _showResultsSheet();
      });
    });
  }

  void _showResultsSheet() {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _ScanResultsSheet(),
    ).then((result) {
      if (mounted) {
        if (result == 'edit') {
          // Find the parent AddTransactionSheet state to switch tabs
          final parent = context.findAncestorStateOfType<_AddTransactionSheetState>();
          if (parent != null) {
            parent._onTabTapped(0); // Switch to Manual tab
          }
        } else {
          setState(() => _state = _ScanState.idle);
          _beamController.repeat();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return _buildPermissionView();
    }

    return Padding(
      key: const ValueKey('scan_view'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          ScaleTransition(
            scale: _openScale,
            child: FadeTransition(
              opacity: _openOpacity,
              child: _buildViewfinder(context),
            ),
          ),
          const SizedBox(height: 14),
          FadeTransition(opacity: _openOpacity, child: _buildActionButtons()),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPermissionView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.camera(PhosphorIconsStyle.fill),
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Camera Access',
            style: AppTypography.h2.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Text(
            'To scan receipts with precision, we need access to your camera. Your privacy is our priority.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.primary.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _requestPermission,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Allow Access',
                  style: AppTypography.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewfinder(BuildContext context) {
    final double viewfinderH = MediaQuery.of(context).size.height * 0.37;

    return GestureDetector(
      onTap: _simulateDetection,
      child: Container(
        width: double.infinity,
        height: viewfinderH,
        decoration: BoxDecoration(
          color: const Color(0xFF0C0C0C),
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Container(color: const Color(0xFF0A0A0A)),

              // Vignette overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ),

              // Scanning beam
              if (_state == _ScanState.idle || _state == _ScanState.detecting)
                AnimatedBuilder(
                  animation: _beamY,
                  builder: (_, __) => Positioned(
                    top: _beamY.value * (viewfinderH - 2),
                    left: 28, right: 28,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFFC9973A).withValues(alpha: 0.7),
                            const Color(0xFFC9973A).withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.25, 0.75, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC9973A).withValues(alpha: 0.45),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Corner brackets
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _bracketPulse,
                  builder: (_, __) {
                    final double scale = _state == _ScanState.detecting
                        ? 1.15 : _bracketPulse.value;
                    final Color c = _state == _ScanState.detecting
                        ? const Color(0xFFC9973A)
                        : const Color(0xFFC9973A).withValues(alpha: 0.85);
                    return Transform.scale(
                      scale: scale,
                      child: _CornerBrackets(color: c),
                    );
                  },
                ),
              ),

              // Shutter flash
              if (_state == _ScanState.processing)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 0.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  builder: (_, v, __) =>
                      Container(color: Colors.white.withValues(alpha: v)),
                ),

              // Processing overlay
              if (_state == _ScanState.processing) _buildProcessingOverlay(),

              // Instruction card
              Positioned(
                left: 14, right: 14, bottom: 14,
                child: _buildInstructionCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: const Color(0xFF0A0A0A).withValues(alpha: 0.72),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 34, height: 34,
            child: CircularProgressIndicator(
              color: Color(0xFFC9973A), strokeWidth: 2.2),
          ),
          const SizedBox(height: 14),
          Text('Reading receipt...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: v,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC9973A)),
                  minHeight: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2), end: Offset.zero).animate(anim),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(_instructionText),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18), width: 1),
        ),
        child: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_instructionText,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: () => HapticFeedback.lightImpact(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8DDD0), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.folder(PhosphorIconsStyle.regular),
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Upload from Gallery',
                      style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600, color: AppColors.primary)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _flashOn = !_flashOn);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _flashOn ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _flashOn ? AppColors.primary : const Color(0xFFE8DDD0),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedRotation(
                  turns: _flashOn ? 0.0 : 0.5,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    PhosphorIcons.lightning(PhosphorIconsStyle.fill),
                    color: _flashOn
                        ? Colors.white
                        : AppColors.primary.withValues(alpha: 0.45),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 5),
                Text(_flashOn ? 'On' : 'Off',
                    style: AppTypography.caption.copyWith(
                      color: _flashOn
                          ? Colors.white
                          : AppColors.primary.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Corner Brackets Overlay (CustomPainter)
// ─────────────────────────────────────────────────────────────
class _CornerBrackets extends StatelessWidget {
  final Color color;
  final double bracketSize;
  final double thickness;

  const _CornerBrackets({
    required this.color,
    this.bracketSize = 28,
    this.thickness = 3,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CornerBracketsPainter(
        color: color,
        bracketSize: bracketSize,
        thickness: thickness,
      ),
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  final Color color;
  final double bracketSize;
  final double thickness;

  const _CornerBracketsPainter({
    required this.color,
    required this.bracketSize,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double inset = 22;
    final double b = bracketSize;
    final double w = size.width;
    final double h = size.height;

    // Top-left
    canvas.drawLine(Offset(inset, inset + b), Offset(inset, inset), p);
    canvas.drawLine(Offset(inset, inset), Offset(inset + b, inset), p);
    // Top-right
    canvas.drawLine(Offset(w - inset - b, inset), Offset(w - inset, inset), p);
    canvas.drawLine(Offset(w - inset, inset), Offset(w - inset, inset + b), p);
    // Bottom-left
    canvas.drawLine(Offset(inset, h - inset - b), Offset(inset, h - inset), p);
    canvas.drawLine(Offset(inset, h - inset), Offset(inset + b, h - inset), p);
    // Bottom-right
    canvas.drawLine(
        Offset(w - inset - b, h - inset), Offset(w - inset, h - inset), p);
    canvas.drawLine(
        Offset(w - inset, h - inset), Offset(w - inset, h - inset - b), p);
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────
// Scan Results Sheet
// ─────────────────────────────────────────────────────────────
class _ScanResultsSheet extends StatefulWidget {
  const _ScanResultsSheet({super.key});

  @override
  State<_ScanResultsSheet> createState() => _ScanResultsSheetState();
}

class _ScanResultsSheetState extends State<_ScanResultsSheet> {
  bool _isEditing = false;
  
  // Controllers for editable fields
  final _merchantCtrl = TextEditingController(text: 'Starbucks');
  final _dateCtrl = TextEditingController(text: 'Apr 3, 2026');
  final _totalCtrl = TextEditingController(text: 'Rs. 450');
  
  // Controllers for line items
  final _item1NameCtrl = TextEditingController(text: 'Caramel Latte');
  final _item1PriceCtrl = TextEditingController(text: 'Rs. 350');
  final _item2NameCtrl = TextEditingController(text: 'Chocolate Muffin');
  final _item2PriceCtrl = TextEditingController(text: 'Rs. 100');

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _dateCtrl.dispose();
    _totalCtrl.dispose();
    _item1NameCtrl.dispose();
    _item1PriceCtrl.dispose();
    _item2NameCtrl.dispose();
    _item2PriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 24, right: 24, bottom: 32),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF9F6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48, height: 6,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Header
          _StaggeredItem(
            delay: 0,
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Text('Receipt Scanned',
                    style: AppTypography.h3
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Extracted fields
          _StaggeredItem(delay: 80,  child: _resultRow(PhosphorIcons.storefront(PhosphorIconsStyle.fill), 'Merchant', _merchantCtrl)),
          const SizedBox(height: 10),
          _StaggeredItem(delay: 160, child: _resultRow(PhosphorIcons.calendar(PhosphorIconsStyle.fill), 'Date', _dateCtrl)),
          const SizedBox(height: 10),
          _StaggeredItem(delay: 240, child: _resultRow(PhosphorIcons.receipt(PhosphorIconsStyle.fill), 'Total', _totalCtrl)),
          const SizedBox(height: 18),

          // ── Line items
          _StaggeredItem(
            delay: 320,
            child: Text('Items found:',
                style: AppTypography.caption.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
          ),
          const SizedBox(height: 12),
          _StaggeredItem(delay: 400, child: _lineItem(_item1NameCtrl, _item1PriceCtrl)),
          const SizedBox(height: 10),
          _StaggeredItem(delay: 480, child: _lineItem(_item2NameCtrl, _item2PriceCtrl)),
          const SizedBox(height: 22),

          // ── Action (Save or Done) button
          _StaggeredItem(
            delay: 560,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isEditing
                ? GestureDetector(
                    key: const ValueKey('done_btn'),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() => _isEditing = false);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            blurRadius: 20, offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Text('Done',
                                style: AppTypography.h3.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  )
                : GestureDetector(
                    key: const ValueKey('save_btn'),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      Navigator.pop(context, true);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 20, offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text('Save Expense',
                                style: AppTypography.h3.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Edit link
          if (!_isEditing)
            _StaggeredItem(
              delay: 620,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isEditing = true);
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.pencilSimple(PhosphorIconsStyle.fill),
                          size: 16,
                          color: AppColors.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Text('Edit Details',
                            style: AppTypography.body.copyWith(
                                color: AppColors.primary.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          if (_isEditing)
            _StaggeredItem(
              delay: 0,
              child: Center(
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context, 'edit');
                  },
                  child: Text('Switch to Manual Entry', 
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    )),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultRow(IconData icon, String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFE8DDD0).withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.85)),
          const SizedBox(width: 12),
          Text('$label:',
              style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          _isEditing 
            ? SizedBox(
                width: 150,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.end,
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.08)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.12)),
                    ),
                  ),
                ),
              )
            : Text(controller.text,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _lineItem(TextEditingController nameCtrl, TextEditingController priceCtrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
                color: AppColors.accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _isEditing
              ? TextField(
                  controller: nameCtrl,
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.08)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.12)),
                    ),
                  ),
                )
              : Text(nameCtrl.text,
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          _isEditing
            ? SizedBox(
                width: 80,
                child: TextField(
                  controller: priceCtrl,
                  textAlign: TextAlign.end,
                  style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.08)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.12)),
                    ),
                  ),
                ),
              )
            : Text(priceCtrl.text,
                style: AppTypography.bodySmall
                    .copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Staggered Reveal Item
// ─────────────────────────────────────────────────────────────
class _StaggeredItem extends StatefulWidget {
  final Widget child;
  final int delay; // ms before animation starts

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
        vsync: this, duration: const Duration(milliseconds: 380));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
            begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

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
