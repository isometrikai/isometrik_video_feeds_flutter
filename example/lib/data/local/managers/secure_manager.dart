import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureManager {
  const SecureManager();

  final _storage = const FlutterSecureStorage();

  Future<String> get(
    String key, {
    String defaultValue = '',
  }) async {
    try {
      final value = await _storage.read(key: key);
      if (value == null || value.isEmpty) {
        return defaultValue;
      }
      return value;
    } catch (error) {
      return defaultValue;
    }
  }

  Future<void> save(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> clear() => _storage.deleteAll();
}
