import 'package:flutter/widgets.dart';
import '../services/app_services.dart';
import 'app_settings_repository.dart';
import 'transaction_repository.dart';

class RepositoryScope extends InheritedWidget {
  final TransactionRepository transactions;
  final AppSettingsRepository settings;
  final AppServices services;

  const RepositoryScope({
    super.key,
    required this.transactions,
    required this.settings,
    required this.services,
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
        services != oldWidget.services;
  }
}
