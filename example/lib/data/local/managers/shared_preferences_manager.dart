import 'package:flutter/cupertino.dart';
import 'package:ism_video_reel_player_example/data/data.dart';
import 'package:ism_video_reel_player_example/res/res.dart';
import 'package:ism_video_reel_player_example/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesManager {
  SharedPreferences? _sharedPreferences;

  /// initialize local database
  Future<void> init() async {
    if (_sharedPreferences == null) {
      _sharedPreferences = await SharedPreferences.getInstance();
      debugPrint('SharedPreferences initialized: $_sharedPreferences');
    }
  }

  bool get isInitialized => _sharedPreferences != null;

  Future<void> clearData() async {
    await _sharedPreferences?.clear();
  }

  Future<void> removeKey(String key) async {
    await _sharedPreferences?.remove(key);
  }

  /// store the value with type
  Future<void> saveValue(
      String key, dynamic value, SavedValueDataType saveValueDataType) async {
    if (!isInitialized) {
      await init();
    }

    switch (saveValueDataType) {
      case SavedValueDataType.string:
        await _sharedPreferences?.setString(key, value?.toString() ?? '');
        break;
      case SavedValueDataType.int:
        await _sharedPreferences?.setInt(key, value as int? ?? 0);
        break;
      case SavedValueDataType.double:
        await _sharedPreferences?.setDouble(key, value as double? ?? 0.0);
        break;
      case SavedValueDataType.bool:
        await _sharedPreferences?.setBool(key, value as bool? ?? false);
        break;
      case SavedValueDataType.stringList:
        await _sharedPreferences?.setStringList(
            key, value as List<String>? ?? []);
        break;
    }
  }

  /// return value
  dynamic getValue(String key, SavedValueDataType? getValueDataType) async {
    if (!isInitialized) {
      await init();
    }

    switch (getValueDataType) {
      case SavedValueDataType.string:
        return _sharedPreferences?.getString(key) ??
            _getDefaultStringValue(key);
      case SavedValueDataType.int:
        return _sharedPreferences?.getInt(key) ?? 0;
      case SavedValueDataType.double:
        return _sharedPreferences?.getDouble(key) ??
            _getDefaultDoubleValue(key);
      case SavedValueDataType.bool:
        return _sharedPreferences?.getBool(key) ?? _getDefaultBoolValue(key);
      case SavedValueDataType.stringList:
        return _sharedPreferences?.getStringList(key) ?? <String>[];
      default:
        return null;
    }
  }

  String _getDefaultStringValue(String key) {
    switch (key) {
      case LocalStorageKeys.language:
        return DefaultValues.defaultLanguage;
      case LocalStorageKeys.currencySymbol:
        return Utility.encodeChar(DefaultValues.defaultCurrencySymbol);
      case LocalStorageKeys.currencyCode:
        return DefaultValues.defaultCurrencyCode;
      case LocalStorageKeys.userIP:
        return DefaultValues.defaultIpAddress;
      case LocalStorageKeys.countryId:
        return DefaultValues.defaultCountryId;
      default:
        return '';
    }
  }

  double _getDefaultDoubleValue(String key) {
    switch (key) {
      case LocalStorageKeys.latitude:
        return DefaultValues.defaultLatitude;
      case LocalStorageKeys.longitude:
        return DefaultValues.defaultLongitude;
      default:
        return 0.0;
    }
  }

  bool _getDefaultBoolValue(String key) =>
      key == LocalStorageKeys.isFirstTimeVisit;
}
