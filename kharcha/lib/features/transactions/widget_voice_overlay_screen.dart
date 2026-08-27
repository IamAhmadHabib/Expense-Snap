import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/transaction.dart';
import '../../models/transaction_draft.dart';
import '../../repositories/repository_scope.dart';
import '../../services/capture_adapters.dart';
import '../../services/home_widget_service.dart';
import '../../services/speech_recognition_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

enum _OverlayVoiceState {
  listening,
  processing,
  confirming,
  saved,
}

class WidgetVoiceOverlayScreen extends StatefulWidget {
  const WidgetVoiceOverlayScreen({super.key});

  @override
  State<WidgetVoiceOverlayScreen> createState() => _WidgetVoiceOverlayScreenState();
}

class _WidgetVoiceOverlayScreenState extends State<WidgetVoiceOverlayScreen>
    with TickerProviderStateMixin {
  _OverlayVoiceState _state = _OverlayVoiceState.listening;
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  String _currentTranscript = '';
  double _soundLevel = 0.0;
  String _selectedMethod = 'Cash';

  late TextEditingController _amountController;
  late TextEditingController _merchantController;

  late TransactionDraft _parsedDraft;

  late AnimationController _waveController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _parsedDraft = TransactionDraft(
      merchant: '',
      category: 'Food & Dining',
      amount: 0,
      date: DateTime.now(),
      note: '',
      method: 'Cash',
      source: TransactionSource.voice,
    );

    _amountController = TextEditingController();
    _merchantController = TextEditingController();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOut,
      ),
    );

    _slideController.forward();
    _initAndStartListening();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _slideController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    _speechService.stopListening();
    super.dispose();
  }

  Future<void> _initAndStartListening() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      _startSpeech();
    } else {
      final requested = await Permission.microphone.request();
      if (requested.isGranted) {
        _startSpeech();
      } else {
        if (mounted) {
          setState(() {
            _currentTranscript = 'Microphone permission required';
          });
        }
      }
    }
  }

  Future<void> _startSpeech() async {
    final available = await _speechService.initialize(
      onError: (val) {
        if (mounted && _state == _OverlayVoiceState.listening) {
          _finishListening();
        }
      },
      onStatus: (val) {
        if ((val == 'done' || val == 'notListening') &&
            _state == _OverlayVoiceState.listening &&
            _currentTranscript.trim().isNotEmpty) {
          _finishListening();
        }
      },
    );

    if (available && mounted) {
      HapticFeedback.mediumImpact();
      setState(() {
        _state = _OverlayVoiceState.listening;
        _currentTranscript = '';
      });

      await _speechService.startListening(
        onResult: (text) {
          if (mounted) {
            setState(() => _currentTranscript = text);
          }
        },
        onSoundLevelChange: (level) {
          if (mounted) {
            setState(() => _soundLevel = level);
          }
        },
      );
    }
  }

  Future<void> _finishListening() async {
    if (_state != _OverlayVoiceState.listening) return;
    final scope = RepositoryScope.maybeOf(context);
    await _speechService.stopListening();

    if (_currentTranscript.trim().isEmpty) {
      _dismissOverlay();
      return;
    }

    final parser = scope?.services.voiceParser;
    if (mounted) {
      setState(() => _state = _OverlayVoiceState.processing);
    }

    TransactionDraft draft;
    if (parser != null) {
      final res = await parser.parse(
        VoiceCaptureInput(transcript: _currentTranscript),
      );
      draft = res.draft;
    } else {
      draft = TransactionDraft(
        merchant: 'Expense',
        category: 'Food & Dining',
        amount: 0,
        date: DateTime.now(),
        source: TransactionSource.voice,
      );
    }

    if (mounted) {
      _parsedDraft = draft;
      _selectedMethod = (draft.method.isNotEmpty && (draft.method.toLowerCase() == 'card' || draft.method.toLowerCase() == 'cash'))
          ? (draft.method.toLowerCase() == 'card' ? 'Card' : 'Cash')
          : 'Cash';
      _amountController.text =
          draft.amount > 0 ? draft.amount.toStringAsFixed(0) : '';
      _merchantController.text =
          draft.merchant.isNotEmpty ? draft.merchant : 'Expense';
          (draft.merchant.isNotEmpty && draft.merchant.toLowerCase() != 'expense')
              ? draft.merchant
              : (draft.category != 'Other' ? draft.category : '');
      HapticFeedback.lightImpact();
      setState(() => _state = _OverlayVoiceState.confirming);
    }
  }

  Future<void> _saveTransaction() async {
    if (_state == _OverlayVoiceState.saved) return;
    HapticFeedback.heavyImpact();

    final repo = RepositoryScope.maybeOf(context)?.transactions;
    final settingsRepo = RepositoryScope.maybeOf(context)?.settings;

    final parsedAmount =
        double.tryParse(_amountController.text) ?? _parsedDraft.amount;
    final finalMerchant = _merchantController.text.trim().isNotEmpty
        ? _merchantController.text.trim()
        : (_parsedDraft.merchant.isNotEmpty
    final enteredMerchant = _merchantController.text.trim();
    final finalMerchant = enteredMerchant.isNotEmpty
        ? enteredMerchant
        : ((_parsedDraft.merchant.isNotEmpty && _parsedDraft.merchant.toLowerCase() != 'expense')
            ? _parsedDraft.merchant
            : 'Expense');
            : (_parsedDraft.category != 'Other' ? _parsedDraft.category : 'General'));

    final draftToSave = _parsedDraft.copyWith(
      amount: parsedAmount > 0 ? parsedAmount : 100.0,
      merchant: finalMerchant,
      method: _selectedMethod,
      note: _currentTranscript,
      source: TransactionSource.voice,
    );

    if (repo != null) {
      await repo.saveDraft(draftToSave);
    }

    // Immediately sync to the Home Screen Widget
    if (repo != null && settingsRepo != null) {
      await HomeWidgetService.updateWidgetData(
        transactions: repo.transactions,
        settings: settingsRepo.settings,
      );
    }

    if (mounted) {
      setState(() => _state = _OverlayVoiceState.saved);
      await Future.delayed(const Duration(milliseconds: 700));
      _dismissOverlay();
    }
  }

  void _dismissOverlay() {
    _slideController.reverse().then((_) {
      SystemNavigator.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        RepositoryScope.maybeOf(context)?.settings.settings.currencySymbol ??
        'Rs.';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Semi-transparent backdrop / Outside tap to cancel
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismissOverlay,
              child: Container(
                color: AppColors.primary.withValues(alpha: 0.45),
              ),
            ),
          ),

          // 2. Floating Voice Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.lg,
                  ),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Handle
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _state == _OverlayVoiceState.listening
                                    ? 'Listening...'
                                    : (_state == _OverlayVoiceState.processing
                                        ? 'Processing with AI...'
                                        : (_state == _OverlayVoiceState.saved
                                            ? 'Saved!'
                                            : 'Confirm Expense')),
                                style: AppTypography.h3.copyWith(fontSize: 18),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _dismissOverlay,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppColors.background,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Dynamic Content
                      if (_state == _OverlayVoiceState.listening ||
                          _state == _OverlayVoiceState.processing) ...[
                        _buildListeningBody(),
                      ] else if (_state == _OverlayVoiceState.confirming) ...[
                        _buildConfirmingBody(currency),
                      ] else ...[
                        _buildSavedBody(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningBody() {
    return Column(
      children: [
        // Waveform indicator
        SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(12, (index) {
              final norm = math.sin((index / 12) * math.pi);
              final dynamicScale =
                  (0.3 + (_soundLevel.clamp(0, 10) / 10.0) * 0.7);
              final height = (norm * 36 * dynamicScale).clamp(6.0, 44.0);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 4,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 16),

        // Live Transcript Text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            _currentTranscript.isEmpty
                ? 'Say e.g. "Lunch 450" or "1200 Uber"'
                : '"$_currentTranscript"',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              fontSize: 15,
              color: _currentTranscript.isEmpty
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.primary,
              fontStyle: _currentTranscript.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Action: Done Listening button
        GestureDetector(
          onTap: _finishListening,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'Done Speaking',
                style: AppTypography.button.copyWith(
                  color: AppColors.surface,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmingBody(String currency) {
    return Column(
      children: [
        // Amount and Merchant Row
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Amount',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        currency,
                        style: AppTypography.h3.copyWith(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IntrinsicWidth(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: AppTypography.h2.copyWith(
                            color: AppColors.primary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.chartTrack),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Category',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _parsedDraft.category,
                      style: AppTypography.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Merchant',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _merchantController,
                      textAlign: TextAlign.end,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: 'Merchant / Note',
                        hintStyle: AppTypography.body.copyWith(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, color: AppColors.chartTrack),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Payment Method',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  Row(
                    children: [
                      // Cash Pill
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedMethod = 'Cash');
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedMethod == 'Cash'
                                ? AppColors.accent
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedMethod == 'Cash'
                                  ? AppColors.accent
                                  : AppColors.primary.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '💵 Cash',
                                style: AppTypography.label.copyWith(
                                  color: _selectedMethod == 'Cash'
                                      ? AppColors.surface
                                      : AppColors.primary,
                                  fontWeight: _selectedMethod == 'Cash'
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          child: Text(
                            'Cash',
                            style: AppTypography.label.copyWith(
                              color: _selectedMethod == 'Cash'
                                  ? AppColors.surface
                                  : AppColors.primary,
                              fontWeight: _selectedMethod == 'Cash'
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Card Pill
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedMethod = 'Card');
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedMethod == 'Card'
                                ? AppColors.accent
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedMethod == 'Card'
                                  ? AppColors.accent
                                  : AppColors.primary.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '💳 Card',
                                style: AppTypography.label.copyWith(
                                  color: _selectedMethod == 'Card'
                                      ? AppColors.surface
                                      : AppColors.primary,
                                  fontWeight: _selectedMethod == 'Card'
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          child: Text(
                            'Card',
                            style: AppTypography.label.copyWith(
                              color: _selectedMethod == 'Card'
                                  ? AppColors.surface
                                  : AppColors.primary,
                              fontWeight: _selectedMethod == 'Card'
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Confirm / Save Button
        GestureDetector(
          onTap: _saveTransaction,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.amberGold],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Save Expense',
                style: AppTypography.button.copyWith(
                  color: AppColors.surface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedBody() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppColors.surface,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Expense Saved & Synced!',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
