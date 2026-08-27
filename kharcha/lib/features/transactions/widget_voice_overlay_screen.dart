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
import '../../theme/app_typography.dart';

enum _OverlayVoiceState {
  listening,
  processing,
  confirming,
  saved,
}

class WidgetVoiceOverlayScreen extends StatefulWidget {
  final String? initialTranscript;

  const WidgetVoiceOverlayScreen({super.key, this.initialTranscript});

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
    _currentTranscript = widget.initialTranscript ?? '';
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
    if (widget.initialTranscript == null) {
      _initAndStartListening();
    }
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
            _state == _OverlayVoiceState.listening) {
          _finishListening();
        }
      },
    );

    if (available && mounted) {
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
        merchant: '',
        category: 'Food & Dining',
        amount: 0,
        date: DateTime.now(),
        source: TransactionSource.voice,
      );
    }

    if (mounted) {
      _parsedDraft = draft;
      _selectedMethod = (draft.method.isNotEmpty &&
              (draft.method.toLowerCase() == 'card' ||
                  draft.method.toLowerCase() == 'cash'))
          ? (draft.method.toLowerCase() == 'card' ? 'Card' : 'Cash')
          : 'Cash';
      _amountController.text =
          draft.amount > 0 ? draft.amount.toStringAsFixed(0) : '';
      _merchantController.text = (draft.merchant.isNotEmpty &&
              draft.merchant.toLowerCase() != 'expense')
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
    final enteredMerchant = _merchantController.text.trim();
    final finalMerchant = enteredMerchant.isNotEmpty
        ? enteredMerchant
        : ((_parsedDraft.merchant.isNotEmpty &&
                _parsedDraft.merchant.toLowerCase() != 'expense')
            ? _parsedDraft.merchant
            : (_parsedDraft.category != 'Other'
                ? _parsedDraft.category
                : 'General'));

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
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final settings = RepositoryScope.maybeOf(context)?.settings.settings;
    final currency = settings?.currencySymbol ?? r'$';

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

          // 2. Centered/Bottom Floating Card
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          blurRadius: 36,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top row: pill badge & close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _state ==
                                              _OverlayVoiceState.listening
                                          ? AppColors.danger
                                          : AppColors.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _state == _OverlayVoiceState.listening
                                        ? 'Listening...'
                                        : _state ==
                                                _OverlayVoiceState.processing
                                            ? 'Processing...'
                                            : _state ==
                                                    _OverlayVoiceState.confirming
                                                ? 'Confirm Expense'
                                                : 'Saved',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _dismissOverlay,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.06),
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

                        // State-dependent Content
                        if (_state == _OverlayVoiceState.listening)
                          _buildListeningBody()
                        else if (_state == _OverlayVoiceState.processing)
                          _buildProcessingBody()
                        else if (_state == _OverlayVoiceState.confirming)
                          _buildConfirmingBody(currency)
                        else if (_state == _OverlayVoiceState.saved)
                          _buildSavedBody(),
                      ],
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

  Widget _buildListeningBody() {
    return Column(
      children: [
        // Pulsing Waveform Visualizer
        AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(12, (index) {
                final baseHeight = 12.0;
                final dynamicFactor =
                    math.sin((_waveController.value * 2 * math.pi) + index) *
                        14 +
                    (_soundLevel * 25);
                final height = (baseHeight + dynamicFactor).clamp(6.0, 48.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: 4,
                  height: height,
                  decoration: BoxDecoration(
                    color: index % 2 == 0
                        ? AppColors.accent
                        : AppColors.accent.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            );
          },
        ),

        const SizedBox(height: 24),

        // Live transcript or listening placeholder
        Container(
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          child: Text(
            _currentTranscript.isNotEmpty
                ? '"$_currentTranscript"'
                : 'Say something like "Lunch 450" or "Petrol 2000"...',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: _currentTranscript.isNotEmpty
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.45),
              fontWeight: _currentTranscript.isNotEmpty
                  ? FontWeight.w600
                  : FontWeight.w400,
              fontSize: 15,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Done button
        GestureDetector(
          onTap: _finishListening,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.amberGold],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Done Speaking',
                style: AppTypography.button.copyWith(
                  color: AppColors.surface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingBody() {
    return const Column(
      children: [
        SizedBox(height: 16),
        CircularProgressIndicator(
          color: AppColors.accent,
          strokeWidth: 3,
        ),
        SizedBox(height: 16),
        Text('Resolving expense details...'),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildConfirmingBody(String currency) {
    return Column(
      children: [
        // Amount and Merchant Card
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
                    'Method',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedMethod == 'Cash'
                                ? AppColors.accent
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedMethod == 'Cash'
                                  ? AppColors.accent
                                  : AppColors.primary.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Cash',
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
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedMethod == 'Card'
                                ? AppColors.accent
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedMethod == 'Card'
                                  ? AppColors.accent
                                  : AppColors.primary.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Card',
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
