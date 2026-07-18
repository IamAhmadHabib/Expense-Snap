import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/features/auth/auth_screen.dart';
import 'package:kharcha/features/onboarding/onboarding_screen.dart';
import 'package:kharcha/theme/app_theme.dart';

Future<void> _pumpOnboarding(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(disableAnimations: reducedMotion),
          child: child!,
        );
      },
      home: const OnboardingScreen(),
    ),
  );
  await tester.pump();
}

Future<void> _finishTransition(WidgetTester tester) async {
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts with the capture illustration and matching content', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpOnboarding(tester);

    expect(
      find.byKey(const ValueKey('onboarding_illustration_0')),
      findsOneWidget,
    );
    expect(find.text('Track Every Expense'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Expense entry methods including voice, camera, receipt, and keyboard',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('onboarding_indicator_0')))
          .width,
      24,
    );
    semantics.dispose();
  });

  testWidgets('Continue advances through categories and insights in order', (
    tester,
  ) async {
    await _pumpOnboarding(tester);

    await tester.tap(find.byKey(const ValueKey('onboarding_primary_cta')));
    await _finishTransition(tester);

    expect(
      find.byKey(const ValueKey('onboarding_illustration_1')),
      findsOneWidget,
    );
    expect(find.text('Spend. We Handle the Rest.'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('onboarding_indicator_1')))
          .width,
      24,
    );

    await tester.tap(find.byKey(const ValueKey('onboarding_primary_cta')));
    await _finishTransition(tester);

    expect(
      find.byKey(const ValueKey('onboarding_illustration_2')),
      findsOneWidget,
    );
    expect(find.text('Your Money, Your Story'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Skip').hitTestable(), findsNothing);
  });

  testWidgets('rapid Continue taps cannot skip an onboarding page', (
    tester,
  ) async {
    await _pumpOnboarding(tester);

    final continueButton = find.byKey(const ValueKey('onboarding_primary_cta'));
    await tester.tap(continueButton);
    await tester.tap(continueButton);
    await _finishTransition(tester);

    expect(find.text('Spend. We Handle the Rest.'), findsOneWidget);
    expect(find.text('Your Money, Your Story'), findsNothing);
  });

  testWidgets('outgoing and incoming illustrations overlap mid-transition', (
    tester,
  ) async {
    await _pumpOnboarding(tester);

    await tester.tap(find.byKey(const ValueKey('onboarding_primary_cta')));
    await tester.pump(const Duration(milliseconds: 450));

    expect(
      find.byKey(const ValueKey('onboarding_illustration_0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('onboarding_illustration_1')),
      findsOneWidget,
    );
  });

  testWidgets('horizontal swipes preserve the existing page navigation', (
    tester,
  ) async {
    await _pumpOnboarding(tester);

    await tester.drag(
      find.byKey(const ValueKey('onboarding_gesture_surface')),
      const Offset(-300, 0),
    );
    await _finishTransition(tester);

    expect(find.text('Spend. We Handle the Rest.'), findsOneWidget);
  });

  testWidgets('Skip keeps the existing Auth destination', (tester) async {
    await _pumpOnboarding(tester, size: const Size(900, 1000));

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('Get Started keeps the existing Auth destination', (
    tester,
  ) async {
    await _pumpOnboarding(tester, size: const Size(900, 1000));

    for (var page = 0; page < 2; page++) {
      await tester.tap(find.byKey(const ValueKey('onboarding_primary_cta')));
      await _finishTransition(tester);
    }
    await tester.tap(find.byKey(const ValueKey('onboarding_primary_cta')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.byType(AuthScreen), findsOneWidget);
  });

  for (final size in const [
    Size(360, 640),
    Size(360, 800),
    Size(390, 844),
    Size(412, 915),
  ]) {
    testWidgets('layout stays overflow-free at ${size.width}x${size.height}', (
      tester,
    ) async {
      await _pumpOnboarding(tester, size: size);

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('onboarding_primary_cta')).hitTestable(),
        findsOneWidget,
      );
    });
  }

  testWidgets('reduced motion uses a short usable transition', (tester) async {
    await _pumpOnboarding(tester, reducedMotion: true);

    await tester.tap(find.byKey(const ValueKey('onboarding_primary_cta')));
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('Spend. We Handle the Rest.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding_primary_cta')).hitTestable(),
      findsOneWidget,
    );
  });
}
