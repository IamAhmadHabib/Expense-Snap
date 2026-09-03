import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/transaction.dart';
import '../../models/transaction_draft.dart';
import '../../repositories/repository_scope.dart';
import '../../repositories/transaction_repository.dart';
import '../../services/capture_adapters.dart';
import '../../services/speech_recognition_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/category_utils.dart';

enum AddTransactionTab { manual, scan, voice }

// ─────────────────────────────────────────────────────────────
// Category model
// ─────────────────────────────────────────────────────────────
class _Category {
  final String name;
  final IconData icon;
  const _Category(this.name, this.icon);
}

final List<_Category> _categories = [
  _Category('Dining', PhosphorIcons.forkKnife(PhosphorIconsStyle.fill)),
  _Category('Transport', PhosphorIcons.carSimple(PhosphorIconsStyle.fill)),
  _Category('Shopping', PhosphorIcons.tote(PhosphorIconsStyle.fill)),
  _Category('Entmnt', PhosphorIcons.ticket(PhosphorIconsStyle.fill)),
  _Category('Health', PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill)),
  _Category('Utilities', PhosphorIcons.receipt(PhosphorIconsStyle.fill)),
  _Category('Education', PhosphorIcons.bookOpen(PhosphorIconsStyle.fill)),
  _Category('Travel', PhosphorIcons.airplaneTilt(PhosphorIconsStyle.fill)),
  _Category('Groceries', PhosphorIcons.basket(PhosphorIconsStyle.fill)),
  _Category('Other', PhosphorIcons.tag(PhosphorIconsStyle.fill)),
];

// ─────────────────────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────────────────────
class AddTransactionSheet extends StatefulWidget {
  final Transaction? transaction;
  final AddTransactionTab? initialTab;
  final TransactionRepository? repository;

  const AddTransactionSheet({
    super.key,
    this.transaction,
    this.initialTab,
    this.repository,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet>
    with TickerProviderStateMixin {
  String _amount = '0';
  late int _activeTab;
  _Category _selectedCategory = _categories[0];
  String _selectedPayment = 'Cash';
  bool _isSaving = false;
  bool _showNumPad = false;
  late TransactionRepository _repository;
  bool _repositoryInitialized = false;

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
    _activeTab =
        (widget.initialTab ??
                (widget.transaction == null
                    ? AddTransactionTab.voice
                    : AddTransactionTab.manual))
            .index;
    _pageController = PageController(initialPage: _activeTab);

    // Initialize from transaction if editing
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _amount = tx.amount.toString().replaceAll('.0', '');
      _descriptionController.text = tx.merchant;
      _noteController.text = tx.note;
      _selectedDate = tx.date;
      _selectedTime = TimeOfDay.fromDateTime(tx.date);
      _selectedPayment = tx.method;

      // Find category
      final cat = _categories.firstWhere(
        (c) => c.name.toLowerCase() == tx.category.toLowerCase(),
        orElse: () => _categories[0],
      );
      _selectedCategory = cat;
    }
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repositoryInitialized) return;
    _repository =
        widget.repository ??
        RepositoryScope.maybeOf(context)?.transactions ??
        TransactionRepository.inMemory();
    _repositoryInitialized = true;
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

  void _closeNumPad() {
    final targetTab = _activeTab;
    setState(() => _showNumPad = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(targetTab);
    });
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
    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    await _saveDraft(
      TransactionDraft(
        merchant: _descriptionController.text,
        category: _selectedCategory.name,
        amount: double.tryParse(_amount) ?? 0,
        date: selectedDateTime,
        note: _noteController.text,
        method: _selectedPayment,
        source: TransactionSource.manual,
      ),
    );
  }

  Future<void> _saveDraft(TransactionDraft draft) async {
    if (_isSaving || draft.amount <= 0) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    final sync = RepositoryScope.maybeOf(context)?.sync;
    final saved = await _repository.saveDraft(
      draft,
      transactionId: widget.transaction?.id,
    );
    unawaited(sync?.syncNow());
    if (mounted) Navigator.pop(context, saved);
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
              onPrimary: AppColors.surface,
              surface: AppColors.warmSurface,
              onSurface: AppColors.primary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: AppTypography.button.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32)),
              ),
              backgroundColor: AppColors.warmSurface,
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
              onPrimary: AppColors.surface,
              surface: AppColors.warmSurface,
              onSurface: AppColors.primary,
              secondary: AppColors.accent,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.warmSurface,
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              dayPeriodColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.primary
                    : AppColors.surface,
              ),
              dayPeriodTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.textOnPrimary
                    : AppColors.primary,
              ),
              hourMinuteColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.primary
                    : AppColors.surface,
              ),
              hourMinuteTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.textOnPrimary
                    : AppColors.primary,
              ),
              dialBackgroundColor: AppColors.surface,
              dialHandColor: AppColors.primary,
              dialTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.textOnPrimary
                    : AppColors.primary,
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(32)),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: AppTypography.button.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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
        _selectedDate.day == now.day) {
      return 'Today';
    }
    return DateFormat('MMM d, yyyy').format(_selectedDate);
  }

  String get _formattedTime {
    final hour = _selectedTime.hourOfPeriod == 0
        ? 12
        : _selectedTime.hourOfPeriod;
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
        color: AppColors.warmSurface,
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
                Expanded(
                  child: Text(
                    'Add Transaction',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
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
                  : PageView.builder(
                      controller: _pageController,
                      itemCount: 3,
                      onPageChanged: (index) {
                        if (!_showNumPad) {
                          FocusScope.of(
                            context,
                          ).unfocus(); // Dismiss keyboard on swipe
                          setState(() => _activeTab = index);
                          HapticFeedback.selectionClick();
                        }
                      },
                      itemBuilder: (context, index) {
                        return RepaintBoundary(
                          child: TickerMode(
                            enabled: _activeTab == index,
                            child: _buildCapturePage(index, keyboardPadding),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturePage(int index, double keyboardPadding) {
    switch (index) {
      case 0:
        return _buildManualTabView(keyboardPadding > 0);
      case 1:
        return _ScanTabView(
          key: const ValueKey('scan_view'),
          onSave: _saveDraft,
        );
      case 2:
      default:
        return _VoiceTabView(
          key: const ValueKey('voice_view'),
          onSave: _saveDraft,
        );
    }
  }

  // ─────────────────────────────── FORM VIEW ───────────────────────────────
  Widget _buildManualTabView(bool isKeyboardActive) {
    return Column(
      children: [
        Expanded(child: _buildFormView()),
        Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, isKeyboardActive ? 12 : 20),
          child: _buildSaveButton(),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      key: const ValueKey('form_view'),
      physics: const BouncingScrollPhysics(),
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
            trailing: Text(
              'optional',
              style: AppTypography.overline.copyWith(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─────────────────────────────── INPUT VIEW ──────────────────────────────
  Widget _buildInputView() {
    return Padding(
      key: const ValueKey('input_view'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildHeroAmount(),
                  const SizedBox(height: 28),
                  _buildNumberPad(),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _closeNumPad();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
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
                          'Confirm Amount',
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────── TABS ────────────────────────────────────
  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warmBorder, width: 1),
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
                child: Icon(
                  icon,
                  color: AppColors.primary.withValues(
                    alpha: isActive ? 1.0 : 0.4,
                  ),
                  size: 18,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  color: AppColors.primary.withValues(
                    alpha: isActive ? 1.0 : 0.4,
                  ),
                ),
              ),
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
    final currencySymbol =
        RepositoryScope.maybeOf(context)?.settings.settings.currencySymbol ??
        'Rs.';

    return Column(
      children: [
        Text(
          'How much did you spend?',
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
                currencySymbol,
                style: AppTypography.h3.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatted,
              style: AppTypography.display.copyWith(
                fontSize: 72,
                height: 1.0,
                color: AppColors.primary,
                letterSpacing: -2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const _BlinkingCursor(),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────── NUMBER PAD ──────────────────────────────
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

  // ─────────────────────────────── CATEGORY ────────────────────────────────
  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.profileDivider, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedCategory.icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _selectedCategory.name,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          Icon(
            PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
            color: AppColors.primary.withValues(alpha: 0.3),
            size: 16,
          ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.profileDivider.withValues(alpha: 0.7),
          width: 1,
        ),
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
                hintStyle: AppTypography.body.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.4),
                ),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.profileDivider.withValues(alpha: 0.7),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary.withValues(alpha: 0.5), size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
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
                  blurRadius: 20,
                  offset: const Offset(0, 10),
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
                        Icon(
                          PhosphorIcons.floppyDisk(PhosphorIconsStyle.fill),
                          color: AppColors.surface,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Save Expense',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.surface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Opacity(
                    opacity: ((value - 0.5) * 2.0).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale:
                          0.5 + (0.5 * ((value - 0.5) * 2.0).clamp(0.0, 1.0)),
                      child: Icon(
                        PhosphorIcons.check(PhosphorIconsStyle.bold),
                        color: AppColors.surface,
                        size: 32,
                      ),
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
  const _CategoryPickerSheet({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, left: 24, right: 24, bottom: 24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 20),
          Text(
            'Choose Category',
            style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
          ),
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
              final catStyle = CategoryUtils.style(cat.name);
              return GestureDetector(
                onTap: () => onSelected(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? catStyle.background
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? catStyle.foreground
                          : AppColors.profileDivider.withValues(alpha: 0.5),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: catStyle.foreground.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat.icon,
                        color: isSelected
                            ? catStyle.foreground
                            : AppColors.primary.withValues(alpha: 0.8),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cat.name,
                        style: AppTypography.overline.copyWith(
                          color: isSelected
                              ? catStyle.foreground
                              : AppColors.primary,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
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
      child: Container(
        margin: const EdgeInsets.only(left: 6, top: 4),
        width: 4,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(2),
        ),
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
  const _PaymentChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
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
            color: widget.isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary
                  : AppColors.profileDivider,
              width: 1.2,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: AppTypography.caption.copyWith(
                color: widget.isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.primary,
                fontWeight: widget.isSelected
                    ? FontWeight.w900
                    : FontWeight.w600,
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
  final Future<void> Function(TransactionDraft draft) onSave;

  const _VoiceTabView({super.key, required this.onSave});

  @override
  State<_VoiceTabView> createState() => _VoiceTabViewState();
}

class _VoiceTabViewState extends State<_VoiceTabView>
    with TickerProviderStateMixin {
  _VoiceState _state = _VoiceState.idle;
  int _hintIndex = 0;
  bool _hasPermission = false;
  Timer? _hintTimer;
  double _soundLevel = 0.0;

  String _currentTranscript = '';
  TransactionDraft _parsedDraft = TransactionDraft(
    merchant: '',
    category: 'Other',
    amount: 0,
    date: DateTime.now(),
    note: '',
    method: 'Cash',
    source: TransactionSource.voice,
  );
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  Timer? _silenceDebounceTimer;

  late AnimationController _micBreathingController;
  late AnimationController _processingPulseController;
  late AnimationController _waveController;
  late AnimationController _dotsController;
  late AnimationController _cardAssemblyController;

  // Assembly steps
  bool _step1Card = false;
  bool _step2Amount = false;
  bool _step3Category = false;
  bool _step4Note = false;
  bool _step5Date = false;
  bool _step6Complete = false;

  final List<String> _hints = [
    'Maine 300 rupay burger pe kharch kiye',
    'Spent 1200 on Uber',
    '450 at Starbucks',
    'Dhai sau petrol',
    '5 hazar bijli ka bill pay kia',
  ];

  double _getVoiceIntensity() {
    double level = _soundLevel;
    if (level < 0.0) {
      if (level < -5.0) {
        level = ((level + 40.0) / 40.0 * 10.0).clamp(0.0, 10.0);
      } else {
        level = 0.0;
      }
    }
    // Noise gate threshold: ambient silence/room noise is typically <= 1.0
    const double noiseFloor = 1.0;
    if (level <= noiseFloor) return 0.0;
    return ((level - noiseFloor) / 7.5).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: '');
    _noteController = TextEditingController(text: '');

    _micBreathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _processingPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _cardAssemblyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _startHintCycling();
    _checkInitialPermission();
  }

  Future<void> _checkInitialPermission() async {
    try {
      final status = await Permission.microphone.status;
      if (mounted) {
        setState(() => _hasPermission = status.isGranted);
      }
      if (!status.isGranted && !status.isPermanentlyDenied) {
        await _requestPermission();
      }
    } catch (_) {}
  }

  void _startHintCycling() {
    _hintTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() => _hintIndex = (_hintIndex + 1) % _hints.length);
    });
  }

  Future<bool> _requestPermission() async {
    HapticFeedback.lightImpact();
    try {
      final status = await Permission.microphone.request();
      if (mounted) {
        setState(() => _hasPermission = status.isGranted);
      }
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Microphone permission is denied. Please enable it in App Settings.',
              ),
              backgroundColor: AppColors.danger,
              action: SnackBarAction(
                label: 'Settings',
                textColor: AppColors.surface,
                onPressed: openAppSettings,
              ),
            ),
          );
        }
        return false;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone permission is required to record voice expenses.',
              ),
              backgroundColor: AppColors.danger,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permission error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return false;
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _silenceDebounceTimer?.cancel();
    _amountController.dispose();
    _noteController.dispose();
    _speechService.cancelListening();
    _micBreathingController.dispose();
    _processingPulseController.dispose();
    _waveController.dispose();
    _dotsController.dispose();
    _cardAssemblyController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    HapticFeedback.mediumImpact();
    _silenceDebounceTimer?.cancel();
    if (!_hasPermission) {
      final granted = await _requestPermission();
      if (!granted) return;
    }
    if (_state == _VoiceState.idle || _state == _VoiceState.error) {
      setState(() {
        _state = _VoiceState.listening;
        _currentTranscript = '';
        _soundLevel = 0.0;
      });
      await _startVoiceCapture();
    } else if (_state == _VoiceState.listening) {
      await _speechService.stopListening();
      await _startProcessing();
    }
  }

  Future<void> _startVoiceCapture() async {
    final hasSpeech = await _speechService.initialize(
      onError: (errorMsg) {
        if (mounted && _state == _VoiceState.listening) {
          if (_currentTranscript.trim().isNotEmpty) {
            _startProcessing();
          } else {
            setState(() => _state = _VoiceState.idle);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Microphone: $errorMsg'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        }
      },
      onStatus: (status) {
        if (mounted && (status == 'done' || status == 'notListening')) {
          if (_state == _VoiceState.listening) {
            if (_currentTranscript.trim().isNotEmpty) {
              _startProcessing();
            } else {
              setState(() => _state = _VoiceState.idle);
            }
          }
        }
      },
    );

    if (hasSpeech && mounted && _state == _VoiceState.listening) {
      final started = await _speechService.startListening(
        onResult: (words) {
          if (!mounted) return;
          setState(() {
            _currentTranscript = words;
          });
          // Auto-stop after 2.2s of silence once words have been spoken
          if (words.trim().isNotEmpty) {
            _silenceDebounceTimer?.cancel();
            _silenceDebounceTimer = Timer(const Duration(milliseconds: 2200), () {
              if (mounted && _state == _VoiceState.listening && _currentTranscript.trim().isNotEmpty) {
                _speechService.stopListening();
                _startProcessing();
              }
            });
          }
        },
        onSoundLevelChange: (level) {
          if (!mounted) return;
          setState(() {
            _soundLevel = level;
          });
        },
      );
      if (!started && mounted && _state == _VoiceState.listening) {
        setState(() => _state = _VoiceState.idle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to listen right now. Please tap the mic again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() => _state = _VoiceState.idle);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone not available or permission denied.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _startProcessing() async {
    _silenceDebounceTimer?.cancel();
    final transcript = _currentTranscript.trim();
    if (transcript.isEmpty) {
      setState(() => _state = _VoiceState.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No speech detected. Please tap the microphone and speak your expense.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _state = _VoiceState.processing;
      _step1Card = _step2Amount = _step3Category = _step4Note = _step5Date =
          _step6Complete = false;
    });

    try {
      final scope = RepositoryScope.maybeOf(context);
      if (scope != null) {
        final result = await scope.services.voiceParser.parse(
          VoiceCaptureInput(transcript: transcript),
        );
        if (mounted) {
          _parsedDraft = result.draft;
          _amountController.text = _parsedDraft.amount > 0
              ? (_parsedDraft.amount % 1 == 0
                  ? _parsedDraft.amount.toInt().toString()
                  : _parsedDraft.amount.toStringAsFixed(2))
              : '0';
          _noteController.text = _parsedDraft.note;
        }
      }
    } catch (_) {}

    if (!mounted) return;

    _cardAssemblyController.reset();
    _cardAssemblyController.forward();

    // Staggered sequence strictly per spec
    Future.delayed(Duration.zero, () {
      if (mounted) setState(() => _step1Card = true);
    });

    // Step 2 — Amount row (0ms – 400ms)
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      setState(() => _step2Amount = true);
      _triggerPulseGlow();
    });

    // Step 3 — Category row (300ms – 600ms)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _step3Category = true);
      _triggerPulseGlow();
    });

    // Step 4 — Note row (600ms – 800ms)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _step4Note = true);
      _triggerPulseGlow();
    });

    // Step 5 — Date row (900ms – 1000ms)
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _step5Date = true);
      _triggerPulseGlow();
    });

    // Step 6 — Card completes & Transition
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _step6Complete = true);

      // Slide up transition to result sheet
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() => _state = _VoiceState.success);
      });
    });
  }

  void _triggerPulseGlow() {
    _processingPulseController.forward(from: 0);
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
              PhosphorIcons.microphone(PhosphorIconsStyle.fill),
              color: AppColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Microphone Access',
            style: AppTypography.h2.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Text(
            'To quickly capture expenses by speaking, we need access to your microphone. Your privacy is our priority.',
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
                    color: AppColors.surface,
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

  // ── Layout ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) return _buildPermissionView();

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
      child: (_state == _VoiceState.success || _state == _VoiceState.correcting)
          ? _buildResultView()
          : _buildRecordingView(),
    );
  }

  // ── Recording View (Combined Layout) ─────────
  Widget _buildRecordingView() {
    final bool isListening = _state == _VoiceState.listening;
    final bool isProcessing = _state == _VoiceState.processing;

    return Stack(
      children: [
        // Language Picker Top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.globe(PhosphorIconsStyle.fill),
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'English + Urdu',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Main Content Area
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isProcessing)
                _buildAssemblyView()
              else ...[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isListening
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentTranscript.isNotEmpty
                                    ? '"$_currentTranscript"'
                                    : "I'm listening...",
                                key: ValueKey(
                                  _currentTranscript.isNotEmpty
                                      ? _currentTranscript
                                      : 'listen',
                                ),
                                textAlign: TextAlign.center,
                                style: AppTypography.h3.copyWith(
                                  color: _currentTranscript.isNotEmpty
                                      ? AppColors.primary
                                      : AppColors.profileSubtext,
                                  fontSize: _currentTranscript.isNotEmpty ? 22 : 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_currentTranscript.isEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Speak your expense naturally',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : isProcessing
                      ? const SizedBox.shrink()
                      : _buildHintText(),
                ),
                if (!isProcessing) ...[
                  const SizedBox(height: 48),
                  _buildWaveform(),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: _buildAssemblyView(),
                  ),
              ],
            ],
          ),
        ),

        // Bottom Rooted Mic
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSoftGlowMic(),
              const SizedBox(height: 16),
              Text(
                isProcessing
                    ? 'Understanding...'
                    : (isListening
                        ? (_getVoiceIntensity() > 0.02
                            ? 'Listening to your voice...'
                            : 'Listening... Speak now')
                        : 'Tap to speak'),
                style: AppTypography.caption.copyWith(
                  color: AppColors.primary.withValues(
                    alpha: isListening && _getVoiceIntensity() > 0.02 ? 0.75 : 0.4,
                  ),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSoftGlowMic() {
    final bool isListening = _state == _VoiceState.listening;
    final bool isProcessing = _state == _VoiceState.processing;
    final Color ringColor = AppColors.warmCharcoal;
    final Color micColor = isListening || isProcessing
        ? AppColors.amberGold
        : AppColors.warmCharcoal;

    return GestureDetector(
      onTap: isProcessing ? null : _toggleListening,
      child: AnimatedBuilder(
        animation: Listenable.merge([_micBreathingController, _waveController]),
        builder: (context, _) {
          final double intensity = _getVoiceIntensity();
          final bool isSpeaking = intensity > 0.02;

          // In listening state, outer rings react dynamically to real voice speech impact
          final double speechScale = isListening && isSpeaking
              ? (1.0 + (intensity * 0.22))
              : 1.0;
          final double breathingScale = isListening
              ? (1.0 + (_micBreathingController.value * 0.04))
              : 1.0;
          final double volumeScale = speechScale * breathingScale;

          return SizedBox(
            width: 200,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Ring (130px)
                _buildBreathingRing(
                  size: 130 * volumeScale,
                  color: ringColor.withValues(
                    alpha: isListening ? (isSpeaking ? 0.22 : 0.12) : 0.07,
                  ),
                  delayFraction: 0.8,
                ),
                // Middle Ring (100px)
                _buildBreathingRing(
                  size: 100 * volumeScale,
                  color: ringColor.withValues(
                    alpha: isListening ? (isSpeaking ? 0.35 : 0.20) : 0.15,
                  ),
                  delayFraction: 0.4,
                ),
                // Inner Button (72px)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: micColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (isListening)
                        BoxShadow(
                          color: micColor.withValues(
                            alpha: isSpeaking
                                ? (0.4 + (intensity * 0.35)).clamp(0.4, 0.75)
                                : 0.3,
                          ),
                          blurRadius: isSpeaking ? (20 + (intensity * 12)) : 16,
                          spreadRadius: isSpeaking ? (2 + (intensity * 3)) : 1,
                        ),
                    ],
                  ),
                  child: Center(
                    child: isProcessing
                        ? _buildProcessingDots()
                        : Icon(
                            PhosphorIcons.microphone(PhosphorIconsStyle.fill),
                            color: AppColors.surface,
                            size: 28,
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

  Widget _buildBreathingRing({
    required double size,
    required Color color,
    required double delayFraction,
  }) {
    // If listening, we stop breathing and use volumeScale from parent
    if (_state == _VoiceState.listening) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }

    return AnimatedBuilder(
      animation: _micBreathingController,
      builder: (context, _) {
        // Simple manual stagger
        double val =
            (math.sin(
                  (_micBreathingController.value * 2 * math.pi) -
                      (delayFraction * math.pi),
                ) +
                1) /
            2;
        double scale = 1.0 + (val * 0.06);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        );
      },
    );
  }

  // ── The Orb ────────────────────────────────────────────────
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
                    color: AppColors.surface.withValues(alpha: opacity),
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
  // ignore: unused_element
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
          color: AppColors.primary.withValues(
            alpha: _state == _VoiceState.idle ? 0.5 : 0.8,
          ),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── Waveform (12 Bars) ──────────
  Widget _buildWaveform() {
    final bool isListening = _state == _VoiceState.listening;
    return SizedBox(
      height: 44,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: !isListening
            ? const SizedBox.shrink()
            : AnimatedBuilder(
                animation: _waveController,
                builder: (context, _) {
                  final double intensity = _getVoiceIntensity();
                  final bool isSpeaking = intensity > 0.02;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(12, (i) {
                      // Parabolic weighting across 12 bars (higher in center, lower at edges)
                      final double bellCurve = math.sin(((i + 1) / 13) * math.pi);
                      // Dynamic acoustic ripple active ONLY when real voice speech is detected
                      final double ripple = isSpeaking
                          ? math.sin((_waveController.value * 4 * math.pi) + (i * 0.55)).abs()
                          : 0.0;
                      // Dynamic height: exactly 4.0 in silence, springing up to 38.0 when speaking
                      final double dynamicHeight = isSpeaking
                          ? (4.0 + (intensity * (10.0 + (ripple * 24.0)) * bellCurve)).clamp(4.0, 38.0)
                          : 4.0;
                      // Color and opacity: calm muted amber in silence, vibrant glowing gold when speaking
                      final double opacity = isSpeaking
                          ? (0.45 + (intensity * 0.55)).clamp(0.45, 1.0)
                          : 0.25;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        curve: Curves.easeOutQuad,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 3.5,
                        height: dynamicHeight,
                        decoration: BoxDecoration(
                          color: AppColors.amberGold.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            if (isSpeaking && intensity > 0.25)
                              BoxShadow(
                                color: AppColors.amberGold.withValues(alpha: intensity * 0.35),
                                blurRadius: 4,
                                spreadRadius: 0.5,
                              ),
                          ],
                        ),
                      );
                    }),
                  );
                },
              ),
      ),
    );
  }

  // ── Processing Assembly View (Refinement) ──────────
  Widget _buildAssemblyView() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Subtle Amber Glow Pulse behind card
        AnimatedBuilder(
          animation: _processingPulseController,
          builder: (context, _) {
            double val = math.sin(_processingPulseController.value * math.pi);
            return Opacity(
              opacity: val * 0.08,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.amberGold, Colors.transparent],
                  ),
                ),
              ),
            );
          },
        ),

        // The Assembly Card
        AnimatedOpacity(
          opacity: _step1Card ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Transform.scale(
            scale: _step1Card ? 1.0 : 0.95,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.warmSurface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _step2Amount
                          ? Row(
                              children: [
                                Text(
                                  'Rs. ',
                                  style: AppTypography.h2.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.warmCharcoal,
                                  ),
                                ),
                                _TypingText(
                                  text: _parsedDraft.amount > 0
                                      ? (_parsedDraft.amount % 1 == 0
                                          ? _parsedDraft.amount.toInt().toString()
                                          : _parsedDraft.amount.toStringAsFixed(2))
                                      : '0',
                                  style: AppTypography.h2.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.warmCharcoal,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Rs. ___',
                              style: AppTypography.h2.copyWith(
                                color: AppColors.warmCharcoal.withValues(
                                  alpha: 0.1,
                                ),
                              ),
                            ),
                      if (_step6Complete)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.warmCharcoal,
                          size: 22,
                        ),
                    ],
                  ),
                  const Divider(
                    height: 32,
                    thickness: 1,
                    color: AppColors.surfaceVariant,
                  ),

                  // Row 2: Category
                  _assemblyRow(
                    PhosphorIcons.tag(PhosphorIconsStyle.fill),
                    _parsedDraft.category,
                    _step3Category,
                    true,
                  ),
                  const SizedBox(height: 14),

                  // Row 3: Note
                  _assemblyRow(
                    PhosphorIcons.note(PhosphorIconsStyle.fill),
                    _parsedDraft.note.isNotEmpty
                        ? _parsedDraft.note
                        : _parsedDraft.merchant,
                    _step4Note,
                    false,
                  ),
                  const SizedBox(height: 14),

                  // Row 4: Date
                  _assemblyRow(
                    PhosphorIcons.calendar(PhosphorIconsStyle.fill),
                    DateFormat('MMM d, h:mm a').format(_parsedDraft.date),
                    _step5Date,
                    false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _assemblyRow(IconData icon, String text, bool visible, bool typeIn) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.headerCard.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: visible && typeIn
                ? _TypingText(
                    text: text,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.headerCard,
                    ),
                  )
                : Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.headerCard,
                    ),
                  ),
          ),
        ],
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
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
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
                          controller: _amountController,
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
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4,
                            ),
                            border: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Text(
                        'Rs. ${_parsedDraft.amount > 0 ? (_parsedDraft.amount % 1 == 0 ? _parsedDraft.amount.toInt().toString() : _parsedDraft.amount.toStringAsFixed(2)) : '0'}',
                        style: AppTypography.h1.copyWith(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _parsedDraft.category,
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
          _state == _VoiceState.correcting
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'Note / Merchant',
                      labelStyle: AppTypography.caption,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                )
              : _detailRow(
                  PhosphorIcons.notepad(PhosphorIconsStyle.fill),
                  'Note',
                  _parsedDraft.note.isNotEmpty
                      ? _parsedDraft.note
                      : _parsedDraft.merchant,
                ),
          _detailRow(
            PhosphorIcons.calendar(PhosphorIconsStyle.fill),
            'Date',
            DateFormat('MMM d, h:mm a').format(_parsedDraft.date),
          ),
          _detailRow(
            PhosphorIcons.wallet(PhosphorIconsStyle.fill),
            'Account',
            _parsedDraft.method,
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
                Icon(
                  PhosphorIcons.quotes(PhosphorIconsStyle.fill),
                  size: 14,
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentTranscript.isNotEmpty
                        ? _currentTranscript
                        : _hints[_hintIndex],
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
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.surfaceVariant,
                        width: 1.5,
                      ),
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
                    final enteredAmount =
                        double.tryParse(_amountController.text.trim());
                    final finalDraft = _parsedDraft.copyWith(
                      amount: enteredAmount != null && enteredAmount > 0
                          ? enteredAmount
                          : _parsedDraft.amount,
                      note: _noteController.text.trim().isNotEmpty
                          ? _noteController.text.trim()
                          : _parsedDraft.note,
                    );
                    widget.onSave(finalDraft);
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
                        color: AppColors.textOnPrimary,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.profileDivider.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isEditing
                ? SizedBox(
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
                          borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                    ),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Helper: Typing Text Animation ───────────────────────────
class _TypingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _TypingText({required this.text, required this.style});

  @override
  State<_TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<_TypingText> {
  String _displayedText = '';
  @override
  void initState() {
    super.initState();
    _type();
  }

  void _type() async {
    for (int i = 0; i <= widget.text.length; i++) {
      if (!mounted) return;
      setState(() => _displayedText = widget.text.substring(0, i));
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayedText, style: widget.style);
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
  final Future<void> Function(TransactionDraft draft) onSave;

  const _ScanTabView({super.key, required this.onSave});

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
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _openScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _openController, curve: Curves.easeOutCubic),
    );
    _openOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _beamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _beamY = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _beamController, curve: Curves.easeInOut),
    );

    _bracketController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _bracketPulse = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _bracketController, curve: Curves.easeInOut),
    );

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
      case _ScanState.idle:
        return 'Point camera at a receipt or screenshot';
      case _ScanState.detecting:
        return 'Receipt found — hold steady...';
      case _ScanState.processing:
        return 'Reading your receipt...';
      case _ScanState.success:
        return 'Got it! Review your expense ✓';
      case _ScanState.error:
        return "Couldn't read receipt — try Upload from Gallery";
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
    showModalBottomSheet<Object>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _ScanResultsSheet(),
    ).then((result) {
      if (mounted) {
        if (result is TransactionDraft) {
          widget.onSave(result);
        } else if (result == 'edit') {
          // Find the parent AddTransactionSheet state to switch tabs
          final parent = context
              .findAncestorStateOfType<_AddTransactionSheetState>();
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
                    color: AppColors.surface,
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
          color: AppColors.cameraSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Container(color: AppColors.cameraBlack),

              // Vignette overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.0,
                      colors: [
                        Colors.transparent,
                        AppColors.primary.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ),

              // Scanning beam
              if (_state == _ScanState.idle || _state == _ScanState.detecting)
                AnimatedBuilder(
                  animation: _beamY,
                  builder: (context, child) => Positioned(
                    top: _beamY.value * (viewfinderH - 2),
                    left: 28,
                    right: 28,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.amberGold.withValues(alpha: 0.7),
                            AppColors.amberGold.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.25, 0.75, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.amberGold.withValues(alpha: 0.45),
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
                  builder: (context, child) {
                    final double scale = _state == _ScanState.detecting
                        ? 1.15
                        : _bracketPulse.value;
                    final Color c = _state == _ScanState.detecting
                        ? AppColors.amberGold
                        : AppColors.amberGold.withValues(alpha: 0.85);
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
                  builder: (context, value, child) => Container(
                    color: AppColors.surface.withValues(alpha: value),
                  ),
                ),

              // Processing overlay
              if (_state == _ScanState.processing) _buildProcessingOverlay(),

              // Instruction card
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
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
      color: AppColors.cameraBlack.withValues(alpha: 0.72),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              color: AppColors.amberGold,
              strokeWidth: 2.2,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Reading receipt...',
            style: TextStyle(
              color: AppColors.surface.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: AppColors.surface.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.amberGold,
                  ),
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
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(_instructionText),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.surface.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _instructionText,
                style: TextStyle(
                  color: AppColors.surface.withValues(alpha: 0.88),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.profileDivider, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIcons.folder(PhosphorIconsStyle.regular),
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Upload from Gallery',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
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
              color: _flashOn ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _flashOn ? AppColors.primary : AppColors.profileDivider,
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
                        ? AppColors.surface
                        : AppColors.primary.withValues(alpha: 0.45),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _flashOn ? 'On' : 'Off',
                  style: AppTypography.caption.copyWith(
                    color: _flashOn
                        ? AppColors.surface
                        : AppColors.primary.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
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

  const _CornerBrackets({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CornerBracketsPainter(
        color: color,
        bracketSize: 28,
        thickness: 3,
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
      Offset(w - inset - b, h - inset),
      Offset(w - inset, h - inset),
      p,
    );
    canvas.drawLine(
      Offset(w - inset, h - inset),
      Offset(w - inset, h - inset - b),
      p,
    );
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────
// Scan Results Sheet
// ─────────────────────────────────────────────────────────────
class _ScanResultsSheet extends StatefulWidget {
  const _ScanResultsSheet();

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
        color: AppColors.background,
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
          const SizedBox(height: 20),

          // ── Header
          _StaggeredItem(
            delay: 0,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Receipt Scanned',
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Extracted fields
          _StaggeredItem(
            delay: 80,
            child: _resultRow(
              PhosphorIcons.storefront(PhosphorIconsStyle.fill),
              'Merchant',
              _merchantCtrl,
            ),
          ),
          const SizedBox(height: 10),
          _StaggeredItem(
            delay: 160,
            child: _resultRow(
              PhosphorIcons.calendar(PhosphorIconsStyle.fill),
              'Date',
              _dateCtrl,
            ),
          ),
          const SizedBox(height: 10),
          _StaggeredItem(
            delay: 240,
            child: _resultRow(
              PhosphorIcons.receipt(PhosphorIconsStyle.fill),
              'Total',
              _totalCtrl,
            ),
          ),
          const SizedBox(height: 18),

          // ── Line items
          _StaggeredItem(
            delay: 320,
            child: Text(
              'Items found:',
              style: AppTypography.caption.copyWith(
                color: AppColors.primary.withValues(alpha: 0.6),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _StaggeredItem(
            delay: 400,
            child: _lineItem(_item1NameCtrl, _item1PriceCtrl),
          ),
          const SizedBox(height: 10),
          _StaggeredItem(
            delay: 480,
            child: _lineItem(_item2NameCtrl, _item2PriceCtrl),
          ),
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
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                PhosphorIcons.checkCircle(
                                  PhosphorIconsStyle.fill,
                                ),
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Done',
                                style: AppTypography.h3.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : GestureDetector(
                      key: const ValueKey('save_btn'),
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        final amount =
                            double.tryParse(
                              _totalCtrl.text.replaceAll(
                                RegExp(r'[^0-9.]'),
                                '',
                              ),
                            ) ??
                            0;
                        Navigator.pop(
                          context,
                          TransactionDraft(
                            merchant: _merchantCtrl.text,
                            category: 'Dining',
                            amount: amount,
                            date: DateTime.now(),
                            note:
                                '${_item1NameCtrl.text}, ${_item2NameCtrl.text}',
                            method: 'Card',
                            source: TransactionSource.scan,
                          ),
                        );
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
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_rounded,
                                color: AppColors.surface,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Save Expense',
                                style: AppTypography.h3.copyWith(
                                  color: AppColors.surface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
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
                        Text(
                          'Edit Details',
                          style: AppTypography.body.copyWith(
                            color: AppColors.primary.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                  child: Text(
                    'Switch to Manual Entry',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultRow(
    IconData icon,
    String label,
    TextEditingController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.profileDivider.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _isEditing
              ? SizedBox(
                  width: 150,
                  child: TextField(
                    controller: controller,
                    textAlign: TextAlign.end,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  ),
                )
              : Text(
                  controller.text,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _lineItem(
    TextEditingController nameCtrl,
    TextEditingController priceCtrl,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _isEditing
                ? TextField(
                    controller: nameCtrl,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  )
                : Text(
                    nameCtrl.text,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          _isEditing
              ? SizedBox(
                  width: 80,
                  child: TextField(
                    controller: priceCtrl,
                    textAlign: TextAlign.end,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  ),
                )
              : Text(
                  priceCtrl.text,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
