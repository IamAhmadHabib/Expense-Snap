import 'package:flutter/widgets.dart';
import '../services/app_services.dart';
import '../services/app_sync_coordinator.dart';
import 'app_settings_repository.dart';
import 'transaction_repository.dart';

class RepositoryScope extends InheritedWidget {
  final TransactionRepository transactions;
  final AppSettingsRepository settings;
  final AppServices services;
  final AppSyncCoordinator? sync;

  const RepositoryScope({
    super.key,
    required this.transactions,
    required this.settings,
    required this.services,
    this.sync,
    required super.child,
  });

  static RepositoryScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope != null, 'RepositoryScope is missing above this context.');
    return scope!;
  }

  static RepositoryScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RepositoryScope>();
  }

  @override
  bool updateShouldNotify(RepositoryScope oldWidget) {
    return transactions != oldWidget.transactions ||
        settings != oldWidget.settings ||
        services != oldWidget.services ||
        sync != oldWidget.sync;
  }
}
