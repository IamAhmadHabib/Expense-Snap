import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalKeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> reload() async {}
}

class SharedPreferencesLocalStore implements LocalKeyValueStore {
  final SharedPreferences preferences;

  const SharedPreferencesLocalStore(this.preferences);

  @override
  String? getString(String key) => preferences.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await preferences.setString(key, value);
  }

  @override
  Future<void> reload() async {
    await preferences.reload();
  }
}

class MemoryLocalStore implements LocalKeyValueStore {
  final Map<String, String> _values = {};

  @override
  String? getString(String key) => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> reload() async {}
}
