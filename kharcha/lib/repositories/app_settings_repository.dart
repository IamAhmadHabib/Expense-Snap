import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../data/local_key_value_store.dart';
import '../models/app_settings.dart';

class AppSettingsRepository extends ChangeNotifier {
  static const _storageKey = 'kharcha.settings.v1';
  final LocalKeyValueStore store;
  AppSettings _settings = const AppSettings();

  AppSettingsRepository({required this.store});

  factory AppSettingsRepository.inMemory() {
    return AppSettingsRepository(store: MemoryLocalStore());
  }

  AppSettings get settings => _settings;

  Future<void> load() async {
    await store.reload();
    final raw = store.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      _settings = AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    notifyListeners();
  }

  Future<void> update(AppSettings settings) async {
    _settings = settings;
    await store.setString(_storageKey, jsonEncode(settings.toJson()));
    notifyListeners();
  }
}
