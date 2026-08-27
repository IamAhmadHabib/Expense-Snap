import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/speech_recognition_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_typography.dart';

/// Isolated, lightweight secondary Flutter Engine entry point.
/// Must be annotated with `@pragma('vm:entry-point')` so the AOT compiler
/// does not tree-shake it during release compilation.
@pragma('vm:entry-point')
void voiceOverlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _IsolatedVoiceOverlayApp());
}

class _IsolatedVoiceOverlayApp extends StatelessWidget {
  const _IsolatedVoiceOverlayApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
        ),
      ),
      home: const _FloatingVoiceCard(),
    );
  }
}

class _FloatingVoiceCard extends StatefulWidget {
  const _FloatingVoiceCard();

  @override
  State<_FloatingVoiceCard> createState() => _FloatingVoiceCardState();
}

class _FloatingVoiceCardState extends State<_FloatingVoiceCard>
    with TickerProviderStateMixin {
  static const _channel = MethodChannel('com.kharcha.voice_overlay/bridge');

  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();

  late AnimationController _waveController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool _isListening = true;
  String _selectedMethod = 'Cash';
  String _transcript = '';
  double _soundLevel = 0.0;
  String _category = 'Food & Dining';

  @override
  void initState() {
    super.initState();
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

    _slideController.forward();

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onOverlayPresented') {
        _startListening();
      }
    });

    _startListening();
  }

  Future<void> _startListening() async {
    final available = await _speechService.initialize();
    if (!available) {
      if (mounted) {
        setState(() {
          _transcript = 'Microphone permission needed';
          _isListening = false;
        });
      }
      return;
    }

    await _speechService.startListening(
      onResult: (text) {
        if (!mounted) return;
        setState(() {
          _transcript = text;
        });
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() {
          _soundLevel = level;
        });
      },
    );
  }

  void _finishListening() async {
    await _speechService.stopListening();
    if (!mounted) return;

    // Fast local heuristic extraction
    final parsed = _parseLocalInput(_transcript);

    setState(() {
      _isListening = false;
      _category = parsed['category'] as String;
      _selectedMethod = parsed['method'] as String;
      final amount = parsed['amount'] as double;
      _amountController.text = amount > 0 ? amount.toStringAsFixed(0) : '';
      _merchantController.text = parsed['merchant'] as String;
    });
    HapticFeedback.lightImpact();
  }

  Map<String, dynamic> _parseLocalInput(String text) {
    final lower = text.toLowerCase();

    // 1. Amount extraction
    double amount = 0.0;
    final digitsMatch = RegExp(r'\b(\d+(?:\.\d+)?)\b').firstMatch(lower);
    if (digitsMatch != null) {
      amount = double.tryParse(digitsMatch.group(1)!) ?? 0.0;
    } else if (lower.contains('dhai sau') || lower.contains('250')) {
      amount = 250.0;
    } else if (lower.contains('derh sau') || lower.contains('150')) {
      amount = 150.0;
    } else if (lower.contains('hazar') || lower.contains('thousand')) {
      amount = 1000.0;
    }

    // 2. Category & Merchant
    String category = 'Food & Dining';
    String merchant = 'Food';

    if (lower.contains('uber') || lower.contains('petrol') || lower.contains('ride') || lower.contains('indrive')) {
      category = 'Transportation';
      merchant = lower.contains('uber') ? 'Uber' : (lower.contains('petrol') ? 'Petrol' : 'Ride');
    } else if (lower.contains('chai') || lower.contains('coffee') || lower.contains('burger') || lower.contains('pizza') || lower.contains('lunch') || lower.contains('dinner')) {
      category = 'Food & Dining';
      merchant = lower.contains('chai') ? 'Chai' : (lower.contains('coffee') ? 'Coffee' : (lower.contains('burger') ? 'Burger' : 'Lunch'));
    } else if (lower.contains('bill') || lower.contains('electricity') || lower.contains('wifi') || lower.contains('load')) {
      category = 'Bills & Utilities';
      merchant = 'Utility Bill';
    } else if (lower.contains('grocer') || lower.contains('milk') || lower.contains('doodh')) {
      category = 'Groceries';
      merchant = 'Groceries';
    }

    // 3. Payment Method
    String method = 'Cash';
    if (lower.contains('card') || lower.contains('visa') || lower.contains('debit')) {
      method = 'Card';
    }

    return {
      'amount': amount,
      'merchant': merchant,
      'category': category,
      'method': method,
    };
  }

  void _dismiss() {
    HapticFeedback.lightImpact();
    _speechService.cancelListening();
    _channel.invokeMethod('dismiss');
  }

  void _saveExpense() {
    HapticFeedback.heavyImpact();
    final amount = double.tryParse(_amountController.text.trim()) ?? 100.0;
    final merchant = _merchantController.text.trim().isNotEmpty
        ? _merchantController.text.trim()
        : _category;

    _channel.invokeMethod('commitTransaction', {
      'amount': amount,
      'merchant': merchant,
      'category': _category,
      'method': _selectedMethod,
      'note': _transcript,
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _slideController.dispose();
    _amountController.dispose();
    _merchantController.dispose();
    _speechService.cancelListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Semi-transparent backdrop / Outside tap dismiss
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismiss,
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
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.08),
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
                              _isListening ? 'Listening...' : 'Confirm Expense',
                              style: AppTypography.h3.copyWith(fontSize: 18),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _dismiss,
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

                    if (_isListening) ...[
                      // Waveform
                      SizedBox(
                        height: 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(12, (index) {
                            final norm = math.sin((index / 12) * math.pi);
                            final dynamicScale = (0.3 + (_soundLevel.clamp(0, 10) / 10.0) * 0.7);
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

                      // Live Transcript Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          _transcript.isEmpty ? 'Say e.g. "Lunch 450" or "1200 Uber"' : '"$_transcript"',
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(
                            fontSize: 15,
                            color: _transcript.isEmpty ? AppColors.primary.withValues(alpha: 0.4) : AppColors.primary,
                            fontStyle: _transcript.isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Done Speaking Button
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
                    ] else ...[
                      // Confirm Card
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
                                      'Rs.',
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
                            const Divider(height: 20, color: AppColors.chartTrack),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _category,
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
                                  'Payment Method',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _selectedMethod = 'Cash');
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _selectedMethod == 'Cash' ? AppColors.accent : AppColors.surface,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _selectedMethod == 'Cash' ? AppColors.accent : AppColors.primary.withValues(alpha: 0.15),
                                          ),
                                        ),
                                        child: Text(
                                          'Cash',
                                          style: AppTypography.label.copyWith(
                                            color: _selectedMethod == 'Cash' ? AppColors.surface : AppColors.primary,
                                            fontWeight: _selectedMethod == 'Cash' ? FontWeight.w700 : FontWeight.w500,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(() => _selectedMethod = 'Card');
                                      },
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _selectedMethod == 'Card' ? AppColors.accent : AppColors.surface,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _selectedMethod == 'Card' ? AppColors.accent : AppColors.primary.withValues(alpha: 0.15),
                                          ),
                                        ),
                                        child: Text(
                                          'Card',
                                          style: AppTypography.label.copyWith(
                                            color: _selectedMethod == 'Card' ? AppColors.surface : AppColors.primary,
                                            fontWeight: _selectedMethod == 'Card' ? FontWeight.w700 : FontWeight.w500,
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
                      GestureDetector(
                        onTap: _saveExpense,
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
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
