import 'package:injectable/injectable.dart';
import 'package:ism_video_reel_player/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class IsrSharedPreferencesManager {
  // Obtain shared preferences.
  SharedPreferences? sharedPreferences;

  /// initialize local database
  Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  void clearData() async {
    await sharedPreferences?.clear();
  }

  void removeKey(String key) async {
    await sharedPreferences?.remove(key);
  }

  /// store the value with type
  void saveValue(String key, dynamic value, SavedValueDataType saveValueDataType) async {
    if (saveValueDataType == SavedValueDataType.string) {
      await sharedPreferences?.setString(key, value == null ? '' : value as String);
    } else if (saveValueDataType == SavedValueDataType.int) {
      await sharedPreferences?.setInt(key, value == null ? 0 : value as int);
    } else if (saveValueDataType == SavedValueDataType.double) {
      await sharedPreferences?.setDouble(key, value == null ? 0.0 : value as double);
    } else if (saveValueDataType == SavedValueDataType.bool) {
      await sharedPreferences?.setBool(key, value == null ? false : value as bool);
    } else if (saveValueDataType == SavedValueDataType.stringList) {
      await sharedPreferences?.setStringList(key, value == null ? [] : value as List<String>);
    }
  }

  /// return value
  dynamic getValue(String key, SavedValueDataType? getValueDataType) {
    if (getValueDataType == SavedValueDataType.string) {
      return sharedPreferences?.getString(key) ??
          (key == LocalStorageKeys.language
              ? DefaultValues.defaultLanguage
              : key == LocalStorageKeys.currencySymbol
                  ? IsrVideoReelUtility.encodeChar(DefaultValues.defaultCurrencySymbol)
                  : key == LocalStorageKeys.currencyCode
                      ? DefaultValues.defaultCurrencyCode
                      : key == LocalStorageKeys.latitude
                          ? DefaultValues.defaultLatitude
                          : key == LocalStorageKeys.longitude
                              ? DefaultValues.defaultLongitude
                              : key == LocalStorageKeys.userIP
                                  ? DefaultValues.defaultIpAddress
                                  : key == LocalStorageKeys.countryId
                                      ? DefaultValues.defaultCountryId
                                      : '');
    } else if (getValueDataType == SavedValueDataType.int) {
      return sharedPreferences?.getInt(key) ?? 0;
    } else if (getValueDataType == SavedValueDataType.double) {
      return sharedPreferences?.getDouble(key) ?? 0;
    } else if (getValueDataType == SavedValueDataType.stringList) {
      return sharedPreferences?.getStringList(key) ?? <String>[];
    }
    return null;
  }
}
