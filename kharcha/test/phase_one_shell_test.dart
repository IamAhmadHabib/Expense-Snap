import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/features/dashboard/dashboard_screen.dart';
import 'package:kharcha/features/transactions/add_transaction_sheet.dart';
import 'package:kharcha/theme/app_theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Future<void> _pumpDashboard(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: const DashboardScreen(
        initialBudget: 25000,
        userName: 'Ahmad',
        currencySymbol: 'Rs',
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

    for (final tab in ['Analytics', 'History', 'Profile']) {
      await tester.tap(find.text(tab).last);
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

    await tester.tap(find.byIcon(PhosphorIcons.plus(PhosphorIconsStyle.bold)));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Microphone Access'), findsOneWidget);
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

    await tester.tap(find.text('Home'));
    await tester.pump(const Duration(milliseconds: 500));

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

  testWidgets('profile switch state survives bottom navigation changes', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 1200));

    final darkModeSwitch = find.byType(Switch).last;
    await tester.ensureVisible(darkModeSwitch);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(darkModeSwitch);
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.widget<Switch>(darkModeSwitch).value, isTrue);

    await tester.tap(find.text('Home'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(tester.widget<Switch>(find.byType(Switch).last).value, isTrue);
  });

  testWidgets('profile Log Out opens its confirmation sheet', (tester) async {
    await _pumpDashboard(tester);

    await tester.tap(find.text('Profile'));
    await tester.pump(const Duration(milliseconds: 1200));

    final logOut = find.text('Log Out');
    await tester.ensureVisible(logOut);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(logOut);
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Log out of Kharcha?'), findsOneWidget);
  });
}
