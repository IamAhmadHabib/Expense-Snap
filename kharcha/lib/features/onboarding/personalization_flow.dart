import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../dashboard/dashboard_screen.dart';
import '../../repositories/repository_scope.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PersonalizationFlow extends StatefulWidget {
  const PersonalizationFlow({super.key});

  @override
  State<PersonalizationFlow> createState() => _PersonalizationFlowState();
}

class _PersonalizationFlowState extends State<PersonalizationFlow> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // ── Data ───────────────────────────────────────────
  Map<String, String> _selectedCurrency = {
    'code': 'USD',
    'name': 'United States Dollar',
    'symbol': r'$',
  };
  String _searchQuery = '';
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final List<String> _selectedCategories = [];

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

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Food', 'icon': Icons.restaurant_rounded},
    {'label': 'Transport', 'icon': Icons.directions_car_rounded},
    {'label': 'Shopping', 'icon': Icons.shopping_bag_rounded},
    {'label': 'Bills', 'icon': Icons.receipt_long_rounded},
    {'label': 'Entertainment', 'icon': Icons.movie_creation_rounded},
    {'label': 'Health', 'icon': Icons.medical_services_rounded},
    {'label': 'Groceries', 'icon': Icons.local_grocery_store_rounded},
    {'label': 'Travel', 'icon': Icons.flight_takeoff_rounded},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _budgetController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticFeedback.lightImpact();
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
      );
    } else {
      // 🚀 Final Destination: Dashboard (to be built)
      debugPrint(
        'Setup Complete: ${_nameController.text}, Budget: ${_selectedCurrency['symbol']}${_budgetController.text}',
      );
    }
  }

  void _onStepChanged(int step) {
    setState(() => _currentStep = step);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Fixed: Prevent keyboard from pushing everything up awkwardly
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),

            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onStepChanged,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCurrencyScreen(),
                  _buildBudgetScreen(),
                  _buildCategoriesScreen(),
                  // Fixed: Use a SingleChildScrollView to absorb overflow
                  // but set physics to NeverScrollableScrollPhysics to disable manual swipe
                  SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 240,
                      child: _buildNameScreen(),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Bottom Actions ────────────────────────
            // Only show when keyboard is not visible to maximize space
            if (MediaQuery.of(context).viewInsets.bottom == 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _handleFinishSetup();
                      },
                      child: Text(
                        'Skip for now',
                        style: AppTypography.label.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.4),
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

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 24, 0),
      child: Row(
        children: [
          // ─── Inline Back Button ──────
          IconButton(
            onPressed: () {
              if (_currentStep > 0) {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuart,
                );
              } else {
                Navigator.pop(context);
              }
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: AppColors.textPrimary,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          // ─── Segmented Progress ──────
          Expanded(
            child: Row(
              children: List.generate(_totalSteps, (index) {
                final isCompleted = index <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 3, // slightly thinner for luxury feel
                    margin: EdgeInsets.only(
                      right: index == _totalSteps - 1 ? 0 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Screen 0: Currency ─────────────────────────────
  Widget _buildCurrencyScreen() {
    final filtered = _allCurrencies.where((c) {
      final q = _searchQuery.toLowerCase();
      return c['name']!.toLowerCase().contains(q) ||
          c['code']!.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'Choose your\ncurrency',
            style: AppTypography.h1.copyWith(height: 1.1),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This will be used for all your budget and transactions.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
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
                hintText: 'Search currency...',
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

          const SizedBox(height: AppSpacing.md),

          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              physics: const BouncingScrollPhysics(),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final curr = filtered[index];
                final isSelected = _selectedCurrency['code'] == curr['code'];

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _selectedCurrency = curr);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.surface.withValues(alpha: 0.2)
                                : AppColors.primary.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              curr['symbol']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
                                style: AppTypography.label.copyWith(
                                  color: isSelected
                                      ? AppColors.surface
                                      : AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                curr['name']!,
                                style: AppTypography.caption.copyWith(
                                  color: isSelected
                                      ? AppColors.surface.withValues(alpha: 0.7)
                                      : AppColors.textPrimary.withValues(
                                          alpha: 0.5,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.surface,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Screen 1: Budget ─────────────────────────────
  Widget _buildBudgetScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s your\nmonthly budget?',
            style: AppTypography.h1.copyWith(height: 1.1),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'We\'ll help you stay within this limit.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Vertically center both
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCurrency['symbol']!,
                          style: AppTypography.label.copyWith(
                            color: AppColors.surface,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Currency',
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandsSeparatorFormatter(),
                  ],
                  autofocus: true,
                  style: AppTypography.h1.copyWith(
                    color: AppColors.primary,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    height: 1.0, // Tighten height for centering
                  ),
                  decoration: InputDecoration(
                    hintText: '0,000',
                    hintStyle: AppTypography.h1.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      fontSize: 48,
                      height: 1.0,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Screen B: Categories ─────────────────────────
  Widget _buildCategoriesScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you\nmostly spend on?',
            style: AppTypography.h1.copyWith(height: 1.1),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Select at least 3 categories.', style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.xxl),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _categories.map((cat) {
              final isSelected = _selectedCategories.contains(cat['label']);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isSelected) {
                      _selectedCategories.remove(cat['label']);
                    } else {
                      _selectedCategories.add(cat['label']);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat['icon'],
                        size: 18,
                        color: isSelected
                            ? AppColors.surface
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat['label'],
                        style: AppTypography.label.copyWith(
                          color: isSelected
                              ? AppColors.surface
                              : AppColors.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Screen C: Name ───────────────────────────────
  Widget _buildNameScreen() {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.start, // Precise control over movement
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // This dynamic spacer ensures perfect centering when idle,
          // and pulls the content ALL THE WAY UP when typing.
          SizedBox(
            height: isKeyboardOpen
                ? 40
                : MediaQuery.of(context).size.height * 0.22,
          ),

          Text(
            'What should\nwe call you?',
            style: AppTypography.h1.copyWith(height: 1.1),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Personalize your greeting.', style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.xxl),

          TextField(
            controller: _nameController,
            autofocus: true,
            style: AppTypography.h1.copyWith(color: AppColors.primary),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: AppTypography.h1.copyWith(
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              border: InputBorder.none,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
          ),

          const Spacer(), // Absorbs the rest of the space
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final bool isLastStep = _currentStep == 3;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (isLastStep) {
          _handleFinishSetup();
        } else {
          _nextStep();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(30),
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
            isLastStep ? 'Finish Setup' : 'Continue',
            style: AppTypography.button,
          ),
        ),
      ),
    );
  }

  Future<void> _handleFinishSetup() async {
    final budget =
        double.tryParse(_budgetController.text.replaceAll(',', '')) ?? 0.0;
    final userName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Ahmad';
    final currencySymbol = _selectedCurrency['symbol'] ?? 'Rs.';
    final settingsRepository = RepositoryScope.maybeOf(context)?.settings;
    if (settingsRepository != null) {
      await settingsRepository.update(
        settingsRepository.settings.copyWith(
          userName: userName,
          monthlyBudget: budget,
          currencySymbol: currencySymbol,
          selectedCategories: List<String>.from(_selectedCategories),
        ),
      );
    }
    if (!mounted) return;
    // 🎬 The Awakening Animation - Transition to Dashboard
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DashboardScreen(
              initialBudget: budget,
              userName: userName,
              currencySymbol: currencySymbol,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Dissolve upward transition
          var fade = FadeTransition(opacity: animation, child: child);
          var slide = SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.05), // Subtle upward drift
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: fade,
          );
          return slide;
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }
}

/// ─── Formatter for 1,000s Comma ───────────────
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Remove existing commas to get raw number
    String chars = newValue.text.replaceAll(',', '');

    // Format with commas 1234567 -> 1,234,567
    String formatted = chars.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
