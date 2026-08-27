import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kharcha/theme/app_colors.dart';
import 'package:kharcha/theme/app_typography.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kharcha/features/transactions/add_transaction_sheet.dart';
import 'package:kharcha/models/transaction.dart';
import 'package:kharcha/repositories/repository_scope.dart';
import 'package:kharcha/repositories/transaction_repository.dart';
import 'package:kharcha/utils/category_utils.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final TransactionRepository? repository;
  const HistoryScreen({super.key, this.onBack, this.repository});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _searchController;
  late Animation<double> _searchWidthAnimation;
  final TextEditingController _searchFieldController = TextEditingController();

  bool _isSearchActive = false;
  String _searchQuery = '';
  final Set<String> _activeFilters = {'All'};
  String? _expandedId;
  final Set<String> _collapsedGroups = {};
  final Set<String> _dismissedTransactionIds = {};

  final List<String> _filterOptions = [
    'All',
    'This Month',
    'Food',
    'Transport',
    'Shopping',
    'Health',
    'Travel',
  ];
  static const Set<String> _categoryFilterOptions = {
    'Food',
    'Transport',
    'Shopping',
    'Health',
    'Travel',
  };

  Timer? _snackBarTimer;
  late TransactionRepository _repository;
  bool _repositoryInitialized = false;
  List<Transaction> get _allTransactions => _repository.transactions;

  @override
  void initState() {
    super.initState();
    _searchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _searchWidthAnimation = CurvedAnimation(
      parent: _searchController,
      curve: Curves.easeOutCubic,
    );
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

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    if (_repositoryInitialized) {
      _repository.removeListener(_onRepositoryChanged);
    }
    _searchController.dispose();
    _searchFieldController.dispose();
    super.dispose();
  }

  List<Transaction> _getFilteredTransactions() {
    return _allTransactions.where((tx) {
      if (_dismissedTransactionIds.contains(tx.id)) return false;

      // 1. Search Filter (Always applies)
      final matchesSearch =
          tx.merchant.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.note.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.amount.toString().contains(_searchQuery) ||
          NumberFormat('#,###').format(tx.amount).contains(_searchQuery);

      if (!matchesSearch) return false;

      // 2. Specialized Filters
      // If 'All' is selected, we don't apply segmented filters (it's the default state)
      if (_activeFilters.contains('All') && _activeFilters.length == 1) {
        return true;
      }

      // Check Category (Top Bar Filters)
      final categoryFilters = _activeFilters
          .where(_categoryFilterOptions.contains)
          .toList();
      if (categoryFilters.isNotEmpty) {
        final matchesCategory = categoryFilters.any(
          (filter) => CategoryUtils.matchesFilter(tx.category, filter),
        );
        if (!matchesCategory) return false;
      }

      // Check Source (Filter Sheet)
      final sourceFilters = _activeFilters
          .where((f) => ['Voice', 'Scan', 'Manual'].contains(f))
          .toList();
      if (sourceFilters.isNotEmpty) {
        String txSource = '';
        switch (tx.source) {
          case TransactionSource.voice:
            txSource = 'Voice';
            break;
          case TransactionSource.scan:
            txSource = 'Scan';
            break;
          case TransactionSource.manual:
            txSource = 'Manual';
            break;
        }
        if (!sourceFilters.contains(txSource)) return false;
      }

      // Check Type (Filter Sheet)
      final typeFilters = _activeFilters
          .where((f) => ['Expenses', 'Income'].contains(f))
          .toList();
      if (typeFilters.isNotEmpty) {
        final txType = tx.isIncome ? 'Income' : 'Expenses';
        if (!typeFilters.contains(txType)) return false;
      }

      // Check Special Time Filters
      if (_activeFilters.contains('This Month')) {
        final now = DateTime.now();
        if (tx.date.month != now.month || tx.date.year != now.year) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Map<String, List<Transaction>> _groupTransactions(
    List<Transaction> transactions,
  ) {
    Map<String, List<Transaction>> groups = {};
    for (var tx in transactions) {
      String groupKey;
      final now = DateTime.now();
      final difference = now.difference(tx.date).inDays;

      if (difference == 0 && tx.date.day == now.day) {
        groupKey = 'Today — ${DateFormat('MMM d').format(tx.date)}';
      } else if (difference == 1 ||
          (difference == 0 && tx.date.day != now.day)) {
        groupKey = 'Yesterday — ${DateFormat('MMM d').format(tx.date)}';
      } else if (difference < 7) {
        groupKey = 'This Week';
      } else {
        groupKey = DateFormat('MMMM yyyy').format(tx.date);
      }

      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = [];
      }
      groups[groupKey]!.add(tx);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredTransactions();
    final grouped = _groupTransactions(filtered);
    final totalAmount = filtered.fold(
      0.0,
      (sum, item) => sum + (item.isIncome ? 0 : item.amount),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(totalAmount, filtered.length),
            _buildFilterBar(),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : _buildTransactionList(grouped),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double totalAmount, int count) {
    // Determine status bar height for better integration
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(24, statusBarHeight + 16, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Default Title View
              Opacity(
                opacity: _isSearchActive ? 0 : 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'History',
                      style: AppTypography.h2.copyWith(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.surface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Row(
                      children: [
                        _headerIconButton(PhosphorIcons.magnifyingGlass(), () {
                          setState(() => _isSearchActive = true);
                          _searchController.forward();
                        }, true),
                        const SizedBox(width: 10),
                        _headerIconButton(PhosphorIcons.sliders(), () {
                          _showFilterSheet();
                        }, true),
                      ],
                    ),
                  ],
                ),
              ),

              // Search Overlay View
              if (_isSearchActive)
                AnimatedBuilder(
                  animation: _searchWidthAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _searchWidthAnimation.value,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: AppColors.surface.withValues(alpha: 0.15),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              PhosphorIcons.magnifyingGlass(),
                              size: 22,
                              color: AppColors.surface,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchFieldController,
                                autofocus: true,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.surface,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search transactions...',
                                  hintStyle: TextStyle(
                                    color: AppColors.surface.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                ),
                                cursorColor: AppColors.accent,
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _searchController.reverse().then((_) {
                                  setState(() {
                                    _isSearchActive = false;
                                    _searchQuery = '';
                                    _searchFieldController.clear();
                                  });
                                });
                              },
                              child: Icon(
                                PhosphorIcons.x(PhosphorIconsStyle.bold),
                                size: 18,
                                color: AppColors.surface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIcons.receipt(PhosphorIconsStyle.fill),
                  color: AppColors.accent,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  'Rs. ${NumberFormat('#,###').format(totalAmount)} · $count items',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton(
    IconData icon,
    VoidCallback onTap, [
    bool isDark = false,
  ]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surface.withValues(alpha: 0.1)
              : AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.surface, size: 20),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _activeFilters.contains(filter);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (filter == 'All') {
                  _activeFilters.clear();
                  _activeFilters.add('All');
                } else {
                  _activeFilters.remove('All');
                  if (isSelected) {
                    _activeFilters.remove(filter);
                    if (_activeFilters.isEmpty) _activeFilters.add('All');
                  } else {
                    _activeFilters.add(filter);
                  }
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.profileDivider,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  filter,
                  style: AppTypography.label.copyWith(
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionList(Map<String, List<Transaction>> grouped) {
    final keys = grouped.keys.toList();
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: keys.length,
      itemBuilder: (context, groupIdx) {
        final groupKey = keys[groupIdx];
        final transactions = grouped[groupKey]!;
        final isCollapsed = _collapsedGroups.contains(groupKey);
        final groupTotal = transactions.fold(
          0.0,
          (sum, tx) => sum + (tx.isIncome ? 0 : tx.amount),
        );

        return Column(
          children: [
            _buildDateHeader(groupKey, groupTotal, isCollapsed),
            if (!isCollapsed)
              ...transactions.asMap().entries.map((entry) {
                return _buildTransactionRow(entry.value, entry.key, groupIdx);
              }),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String title, double total, bool isCollapsed) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_collapsedGroups.contains(title)) {
            _collapsedGroups.remove(title);
          } else {
            _collapsedGroups.add(title);
          }
        });
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isCollapsed ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Rs. ${NumberFormat('#,###').format(total)} total',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.warmBorder, height: 1, thickness: 1.2),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(Transaction tx, int index, int groupIdx) {
    final isExpanded = _expandedId == tx.id;
    final categoryIcon = CategoryUtils.icon(tx.category);

    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 300 + (index * 40)),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, (1 - value) * 15),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _expandedId = isExpanded ? null : tx.id);
          },
          child: Dismissible(
            key: Key(tx.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              // Dismissible requires the row to leave this build immediately.
              // Repository persistence and cloud sync can safely finish after.
              setState(() {
                _dismissedTransactionIds.add(tx.id);
                _expandedId = null;
              });
              unawaited(_deleteTransaction(tx.id));
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.dangerSurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(PhosphorIcons.trash(), color: AppColors.dangerMuted),
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.warmBorder.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.softCharcoal,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          categoryIcon,
                          color: AppColors.surface,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  tx.merchant,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                if (tx.source != TransactionSource.manual) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    tx.source == TransactionSource.voice
                                        ? PhosphorIcons.microphone(
                                            PhosphorIconsStyle.fill,
                                          )
                                        : PhosphorIcons.calendar(
                                            PhosphorIconsStyle.fill,
                                          ),
                                    size: 13,
                                    color: AppColors.accent,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${tx.category} · ${DateFormat('h:mm a').format(tx.date)}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${tx.isIncome ? '+' : '–'} Rs. ${NumberFormat('#,###').format(tx.amount)}',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: tx.isIncome
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            isExpanded
                                ? PhosphorIcons.caretUp(PhosphorIconsStyle.bold)
                                : PhosphorIcons.caretDown(
                                    PhosphorIconsStyle.bold,
                                  ),
                            size: 14,
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Expanded Details
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: isExpanded
                        ? _buildRowDetails(tx)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRowDetails(Transaction tx) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: AppColors.profileDivider, height: 1),
        ),
        _detailInfoRow(
          PhosphorIcons.note(),
          'Note:',
          tx.note.isEmpty ? 'No note recorded' : tx.note,
        ),
        _detailInfoRow(PhosphorIcons.creditCard(), 'Method:', tx.method),
        _detailInfoRow(
          PhosphorIcons.calendarBlank(),
          'Date:',
          DateFormat('EEEE, MMM d, yyyy').format(tx.date),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _actionButton(
                'Edit Entry',
                PhosphorIcons.pencilLine(),
                AppColors.primary.withValues(alpha: 0.05),
                AppColors.primary,
                () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddTransactionSheet(
                      transaction: tx,
                      initialTab: AddTransactionTab.manual,
                      repository: _repository,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionButton(
                'Delete',
                PhosphorIcons.trash(),
                AppColors.danger.withValues(alpha: 0.12),
                AppColors.dangerMuted,
                () {
                  _deleteTransaction(tx.id);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showFilterSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter Transactions', style: AppTypography.h3),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(PhosphorIcons.x(), color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _filterSectionTitle('Source'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _filterChip('Voice', setModalState)),
                  const SizedBox(width: 8),
                  Expanded(child: _filterChip('Scan', setModalState)),
                  const SizedBox(width: 8),
                  Expanded(child: _filterChip('Manual', setModalState)),
                ],
              ),
              const SizedBox(height: 32),
              _filterSectionTitle('Transaction Type'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _filterChip('Expenses', setModalState)),
                  const SizedBox(width: 12),
                  Expanded(child: _filterChip('Income', setModalState)),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Update main screen when closing
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Apply Filters',
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimary,
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

  Widget _filterSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: AppColors.primary.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _filterChip(String label, StateSetter setModalState) {
    bool isSelected = _activeFilters.contains(label);
    return GestureDetector(
      onTap: () {
        setModalState(() {
          if (_activeFilters.contains(label)) {
            _activeFilters.remove(label);
          } else {
            _activeFilters.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.profileDivider.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? AppColors.textOnPrimary : AppColors.primary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _detailInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color bg,
    Color fg,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: fg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(String id) async {
    HapticFeedback.mediumImpact();
    final sync = RepositoryScope.maybeOf(context)?.sync;
    await _repository.delete(id);
    unawaited(sync?.syncNow());
    if (!mounted) return;
    setState(() => _expandedId = null);

    _snackBarTimer?.cancel();
    final messenger = ScaffoldMessenger.of(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        dismissDirection: DismissDirection.horizontal,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: bottomPadding + 96,
        ),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Transaction deleted',
          style: AppTypography.label.copyWith(color: AppColors.textOnPrimary),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.accent,
          onPressed: () async {
            _snackBarTimer?.cancel();
            messenger.hideCurrentSnackBar();
            await _repository.undoDelete();
            if (mounted) {
              setState(() => _dismissedTransactionIds.remove(id));
              unawaited(RepositoryScope.maybeOf(context)?.sync?.syncNow());
            }
          },
        ),
      ),
    );

    // Guaranteed fallback timer to auto-dismiss even if Android accessibility mode overrides duration
    _snackBarTimer = Timer(const Duration(milliseconds: 4000), () {
      messenger.hideCurrentSnackBar();
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.ghost(),
            size: 80,
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 24),
          Text(
            'No transactions found',
            style: AppTypography.h3.copyWith(
              color: AppColors.primary.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 8),
          Text('Start by tapping the + button', style: AppTypography.caption),
        ],
      ),
    );
  }
}
