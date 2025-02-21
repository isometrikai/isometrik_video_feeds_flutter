import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/res/res.dart';
import 'package:ism_video_reel_player/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IsrSharedPreferencesManager {
  // Obtain shared preferences.
  SharedPreferences? sharedPreferences;

  /// initialize local database
  Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  Future<void> clearData() async {
    await sharedPreferences?.clear();
  }

  void removeKey(String key) async {
    await sharedPreferences?.remove(key);
  }

  /// store the value with type
  Future<void> saveValue(String key, dynamic value, SavedValueDataType saveValueDataType) async {
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
          (key == IsrLocalStorageKeys.language
              ? DefaultValues.defaultLanguage
              : key == IsrLocalStorageKeys.currencySymbol
                  ? IsrVideoReelUtility.encodeChar(DefaultValues.defaultCurrencySymbol)
                  : key == IsrLocalStorageKeys.currencyCode
                      ? DefaultValues.defaultCurrencyCode
                      : key == IsrLocalStorageKeys.latitude
                          ? DefaultValues.defaultLatitude
                          : key == IsrLocalStorageKeys.longitude
                              ? DefaultValues.defaultLongitude
                              : key == IsrLocalStorageKeys.userIP
                                  ? DefaultValues.defaultIpAddress
                                  : key == IsrLocalStorageKeys.countryId
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
