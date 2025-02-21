import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';

class LocalStorageManager {
  LocalStorageManager(this._sharedPreferencesManager) {
    initializeStorage();
  }

  /// initialize flutter secure storage
  final _flutterSecureStorage = const FlutterSecureStorage();
  final SharedPreferencesManager _sharedPreferencesManager;
  bool _isInitialized = false;

  Future<void> initializeStorage() async {
    if (!_isInitialized) {
      await _sharedPreferencesManager.init();
      await checkFirstLaunch();
      _isInitialized = true;
    }
  }

  Future<void> checkFirstLaunch() async {
    try {
      // Check if the flag is set
      final isFirstLaunch = _sharedPreferencesManager.getValue(
        LocalStorageKeys.isFirstTimeVisit,
        SavedValueDataType.bool,
      ) as bool?;

      if (isFirstLaunch == null || isFirstLaunch == true) {
        // First launch, so app might have been reinstalled
        // Clean stored data (e.g., token) if needed
        await clearData();
        await deleteAllSecuredValues();
        final token = await getSecuredValue(LocalStorageKeys.accessToken);
        debugPrint('token....$token');

        // Set first launch flag to false
        await _sharedPreferencesManager.saveValue(
          LocalStorageKeys.isFirstTimeVisit,
          false,
          SavedValueDataType.bool,
        );
      }
    } catch (e, st) {
      Utility.debugCatchLog(error: e, stackTrace: st);
    }
  }

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
  Future<void> saveValueSecurely(String key, String value) async {
    await _flutterSecureStorage.write(key: key, value: value);
  }

  /// Delete data from secure storage
  void deleteSecuredValue(String key) {
    _flutterSecureStorage.delete(key: key);
  }

  /// Delete all data from secure storage
  Future<void> deleteAllSecuredValues() => _flutterSecureStorage.deleteAll();

  //clear data
  Future<void> clearData() async {
    final userId = await getSecuredValue(LocalStorageKeys.userId);
    // Retrieve the value you want to keep
    final preservedValue = _sharedPreferencesManager.getValue(userId, SavedValueDataType.string) as String;
    await _sharedPreferencesManager.clearData();
    await saveValue(userId, preservedValue, SavedValueDataType.string);
  }

  Future<T?> getValue<T>(String key, SavedValueDataType saveValueDataType) async {
    await initializeStorage(); // Ensure initialization before access
    return _sharedPreferencesManager.getValue(key, saveValueDataType) as T?;
  }

  Future<void> saveValue(String key, dynamic value, SavedValueDataType saveValueDataType) async {
    await initializeStorage(); // Ensure initialization before access
    await _sharedPreferencesManager.saveValue(key, value, saveValueDataType);
  }

  void removeKey(String key) async {
    await _sharedPreferencesManager.removeKey(key);
  }

  /// store the data
  void saveBooleanValue(String key, bool value) async {
    await _sharedPreferencesManager.saveValue(key, value, SavedValueDataType.bool);
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
