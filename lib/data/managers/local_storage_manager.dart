import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:ism_video_reel_player/export.dart';

@lazySingleton
class LocalStorageManager {
  /// initialize flutter secure storage
  final _flutterSecureStorage = const FlutterSecureStorage();

  final _sharedPreferencesManager = kGetIt<SharedPreferencesManager>();

  /// Get data from secure storage
  Future<String> getSecuredValue(String key) async {
    try {
      var value = await _flutterSecureStorage.read(key: key);
      if (value == null || value.isEmpty) {
        value = '';
      }
      return value;
    } catch (error) {
      return '';
    }
  }

  /// Save data in secure storage
  void saveValueSecurely(String key, String value) {
    _flutterSecureStorage.write(key: key, value: value);
  }

  /// Delete data from secure storage
  void deleteSecuredValue(String key) {
    _flutterSecureStorage.delete(key: key);
  }

  /// Delete all data from secure storage
  void deleteAllSecuredValues() {
    _flutterSecureStorage.deleteAll();
  }

  //clear data
  void clearData() {
    _sharedPreferencesManager.clearData();
  }

  void saveValue(String key, dynamic value, SavedValueDataType saveValueDataType) {
    _sharedPreferencesManager.saveValue(key, value, saveValueDataType);
  }

  dynamic getValue(String key, SavedValueDataType saveValueDataType) =>
      _sharedPreferencesManager.getValue(key, saveValueDataType);

  void removeKey(String key) async {
    _sharedPreferencesManager.removeKey(key);
  }

  /// store the data
  void saveBooleanValue(String key, bool value) async {
    _sharedPreferencesManager.saveValue(key, value, SavedValueDataType.bool);
  }

  /// Method For Delete & Override from Secure Storage
  void deleteSaveSecureValue(String key, String value) async {
    try {
      await _flutterSecureStorage.delete(key: key);
      await _flutterSecureStorage.write(key: key, value: value);
    } catch (e, st) {
      Utility.debugCatchLog(error: e, stackTrace: st);
    }
  }
}
