import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/features/dashboard/dashboard_screen.dart';
import 'package:kharcha/features/transactions/add_transaction_sheet.dart';
import 'package:kharcha/models/transaction.dart';
import 'package:kharcha/models/transaction_draft.dart';
import 'package:kharcha/repositories/app_settings_repository.dart';
import 'package:kharcha/repositories/repository_scope.dart';
import 'package:kharcha/repositories/transaction_repository.dart';
import 'package:kharcha/services/app_services.dart';
import 'package:kharcha/theme/app_theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Future<void> _pumpDashboard(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  TransactionRepository? transactions,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: RepositoryScope(
        transactions: transactions ?? TransactionRepository.inMemory(),
        settings: AppSettingsRepository.inMemory(),
        services: AppServices.local(),
        child: const DashboardScreen(
          initialBudget: 25000,
          userName: 'Ahmad',
          currencySymbol: 'Rs',
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 2300));
}

void main() {
  testWidgets('manual form keeps Save Expense visible without scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: AddTransactionSheet(initialTab: AddTransactionTab.manual),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final formScroll = find
        .descendant(
          of: find.byKey(const ValueKey('form_view')),
          matching: find.byType(Scrollable),
        )
        .first;
    expect(tester.state<ScrollableState>(formScroll).position.pixels, 0);

    expect(find.text('Save Expense').hitTestable(), findsOneWidget);
  });

  testWidgets('system back from each non-Home tab returns to Dashboard', (
    tester,
  ) async {
    await _pumpDashboard(tester, size: const Size(900, 1000));

    for (final index in [1, 2, 3]) {
      await tester.tap(find.byKey(ValueKey('dock_tab_$index')));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Good morning,'), findsOneWidget);
    }
  });

  testWidgets('dashboard avatar opens the Profile tab', (tester) async {
    await _pumpDashboard(tester);

    await tester.tap(
      find.byIcon(PhosphorIcons.user(PhosphorIconsStyle.light)).first,
    );
    await tester.pump(const Duration(milliseconds: 1200));

    expect(find.text('Personal Info'), findsOneWidget);
  });

  testWidgets('dashboard bell opens Notifications and back returns home', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    await tester.tap(find.byIcon(PhosphorIcons.bell(PhosphorIconsStyle.light)));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text("You're all caught up"), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Good morning,'), findsOneWidget);
  });

  testWidgets('center add button opens Add Transaction on Voice', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    await tester.tap(find.byKey(const ValueKey('dock_add_button')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Microphone Access'), findsOneWidget);
  });

  testWidgets('dock expands only the selected destination around a fixed Add', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    final addButton = find.byKey(const ValueKey('dock_add_button'));
    final addCenterBefore = tester.getCenter(addButton);
    final home = find.byKey(const ValueKey('dock_tab_0'));
    final analytics = find.byKey(const ValueKey('dock_tab_1'));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Analytics'), findsNothing);
    expect(find.text('History'), findsNothing);
    expect(find.text('Profile'), findsNothing);
    expect(
      tester.getSize(home).width,
      greaterThan(tester.getSize(analytics).width),
    );

    await tester.tap(analytics);
    await tester.pump(const Duration(milliseconds: 180));

    expect(find.text('Home'), findsOneWidget);
    expect(tester.getCenter(addButton), addCenterBefore);

    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('Home'), findsNothing);
    expect(find.text('Analytics'), findsOneWidget);
    expect(
      tester.getSize(analytics).width,
      greaterThan(tester.getSize(home).width),
    );
    expect(tester.getCenter(addButton), addCenterBefore);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dock handles rapid tab changes without snapping or overflow', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    for (final index in [1, 3, 2, 0, 3]) {
      await tester.tap(find.byKey(ValueKey('dock_tab_$index')));
      await tester.pump(const Duration(milliseconds: 45));
    }
    await tester.pump(const Duration(milliseconds: 360));

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Analytics'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(390, 844),
    const Size(412, 915),
    const Size(430, 932),
  ]) {
    testWidgets(
      'dock stays responsive at ${size.width.toInt()} logical pixels',
      (tester) async {
        await _pumpDashboard(tester, size: size);

        expect(
          tester.getCenter(find.byKey(const ValueKey('dock_add_button'))).dx,
          closeTo(size.width / 2, 0.1),
        );
        for (var index = 0; index < 4; index++) {
          expect(
            tester.getSize(find.byKey(ValueKey('dock_tab_$index'))).width,
            greaterThanOrEqualTo(44),
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('dock remains accessible with reduced motion enabled', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpDashboard(tester, reduceMotion: true);

    final homeTab = find.byKey(const ValueKey('dock_tab_0'));
    final analyticsTab = find.byKey(const ValueKey('dock_tab_1'));
    final analyticsSemantics = tester.getSemantics(analyticsTab);
    final homeSemantics = tester.getSemantics(homeTab);

    expect(homeSemantics.getSemanticsData().label, 'Home');
    expect(
      analyticsSemantics.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(
      tester.getSize(homeTab).width,
      greaterThan(tester.getSize(analyticsTab).width),
    );
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Analytics'), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('dashboard quick actions open their matching capture modes', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    await tester.tap(find.text('Manual'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('How much did you spend?'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Scan'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Camera Access'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Voice'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Microphone Access'), findsOneWidget);
  });

  testWidgets('dashboard dead controls route to their related screens', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    await tester.tap(find.byKey(const ValueKey('weekly_velocity_menu')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Activity Matrix'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('dock_tab_0')));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -220));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('top_spending_see_all')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('History'), findsWidgets);
  });

  testWidgets('top spending is a static list in the page scroll', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    expect(
      find.byKey(const ValueKey('top_spending_vertical_swiper')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('top_spending_static_list')),
      findsOneWidget,
    );
  });

  testWidgets('weekly velocity card handles a full-height spending bar', (
    tester,
  ) async {
    final transactions = TransactionRepository.inMemory();
    await transactions.saveDraft(
      TransactionDraft(
        merchant: 'Medicine',
        category: 'Health',
        amount: 2300,
        date: DateTime.now(),
        method: 'Cash',
        source: TransactionSource.manual,
      ),
    );

    await _pumpDashboard(tester, transactions: transactions);

    expect(tester.takeException(), isNull);
  });

  testWidgets('profile switch state survives bottom navigation changes', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    await tester.tap(find.byKey(const ValueKey('dock_tab_3')));
    await tester.pump(const Duration(milliseconds: 1200));

    final darkModeSwitch = find.byType(Switch).last;
    await tester.ensureVisible(darkModeSwitch);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(darkModeSwitch);
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.widget<Switch>(darkModeSwitch).value, isTrue);

    await tester.tap(find.byKey(const ValueKey('dock_tab_0')));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const ValueKey('dock_tab_3')));
    await tester.pump(const Duration(milliseconds: 350));

    expect(tester.widget<Switch>(find.byType(Switch).last).value, isTrue);
  });

  testWidgets('profile Log Out opens its confirmation sheet', (tester) async {
    await _pumpDashboard(tester);

    await tester.tap(find.byKey(const ValueKey('dock_tab_3')));
    await tester.pump(const Duration(milliseconds: 1200));

    final logOut = find.text('Log Out');
    await tester.ensureVisible(logOut);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(logOut);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Log out of Kharcha?'), findsOneWidget);
  });
}
