import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/isr_utils.dart';

class IsrLocalStorageRepositoryImpl implements IsrLocalStorageRepository {
  IsrLocalStorageRepositoryImpl(this._localStorageManager);

  final IsrLocalStorageManager _localStorageManager;

  Future<dynamic> getValue(
      String key, SavedValueDataType saveValueDataType) async {
    final value = await _localStorageManager.getValue(key, saveValueDataType);
    return value == null
        ? null
        : saveValueDataType == SavedValueDataType.string
            ? value as String
            : saveValueDataType == SavedValueDataType.double
                ? value as double
                : saveValueDataType == SavedValueDataType.int
                    ? value as int
                    : saveValueDataType == SavedValueDataType.stringList
                        ? value as List<String>
                        : value as bool;
  }

  Future<String> getSecuredValue(String key) async =>
      await _localStorageManager.getSecuredValue(key);

  void saveValue(
      String key, dynamic value, SavedValueDataType savedValueDataType) {
    _localStorageManager.saveValue(key, value, savedValueDataType);
  }

  void saveSecuredValue(String key, String value) {
    _localStorageManager.saveValueSecurely(key, value);
  }

  @override
  void clearLocalData() {
    _localStorageManager.clearData();
  }

  @override
  void deleteAllSecuredValues() {
    _localStorageManager.deleteAllSecuredValues();
  }

  @override
  void deleteSecuredValue(String key) {
    _localStorageManager.deleteSecuredValue(key);
  }

  @override
  void deleteValue(String key) {
    _localStorageManager.removeKey(key);
  }

  @override
  void clearSession() {}

  @override
  Future<String> getUserId() async =>
      await _localStorageManager.getSecuredValue(IsrLocalStorageKeys.userId);

  @override
  Future<String> getEmail() async =>
      await _localStorageManager.getSecuredValue(IsrLocalStorageKeys.email);

  @override
  Future<bool> isLoggedIn() async => await _localStorageManager.getValue(
      IsrLocalStorageKeys.isLoggedIn, SavedValueDataType.bool) as bool;

  @override
  Future<String> getCurrencyCode() async => await _localStorageManager
      .getSecuredValue(IsrLocalStorageKeys.currencyCode);

  @override
  Future<String> getCurrencySymbol() async => await _localStorageManager
      .getSecuredValue(IsrLocalStorageKeys.currencySymbol);

  // Implementations for all keys
  @override
  Future<String> getLanguage() async =>
      await getValue(IsrLocalStorageKeys.language, SavedValueDataType.string)
          as String;

  @override
  Future<String> getAccessToken() async =>
      await getSecuredValue(IsrLocalStorageKeys.accessToken);

  @override
  Future<String> getRefreshToken() async =>
      await getSecuredValue(IsrLocalStorageKeys.refreshToken);

  @override
  Future<String> getPhoneNumber() async =>
      await getSecuredValue(IsrLocalStorageKeys.phoneNumber);

  @override
  Future<String> getFirstName() async =>
      await getValue(IsrLocalStorageKeys.firstName, SavedValueDataType.string)
          as String;

  @override
  Future<String> getLastName() async =>
      await getValue(IsrLocalStorageKeys.lastName, SavedValueDataType.string)
          as String;

  @override
  Future<String> getProfilePic() async =>
      await getValue(IsrLocalStorageKeys.profilePic, SavedValueDataType.string)
          as String;

  @override
  Future<String> getUserInfo() async =>
      await getValue(IsrLocalStorageKeys.userInfo, SavedValueDataType.string)
          as String;

  // Implementations for setters
  @override
  void saveLanguage(String value) =>
      saveValue(IsrLocalStorageKeys.language, value, SavedValueDataType.string);

  @override
  void saveIsLoggedIn(bool value) =>
      saveValue(IsrLocalStorageKeys.isLoggedIn, value, SavedValueDataType.bool);

  @override
  void saveAccessToken(String value) =>
      saveSecuredValue(IsrLocalStorageKeys.accessToken, value);

  @override
  void saveRefreshToken(String value) =>
      saveSecuredValue(IsrLocalStorageKeys.refreshToken, value);

  @override
  void savePhoneNumber(String value) =>
      saveSecuredValue(IsrLocalStorageKeys.phoneNumber, value);

  @override
  void saveFirstName(String value) => saveValue(
      IsrLocalStorageKeys.firstName, value, SavedValueDataType.string);

  @override
  void saveLastName(String value) =>
      saveValue(IsrLocalStorageKeys.lastName, value, SavedValueDataType.string);

  @override
  void saveProfilePic(String value) => saveValue(
      IsrLocalStorageKeys.profilePic, value, SavedValueDataType.string);

  @override
  void saveEmail(String value) {
    saveValue(IsrLocalStorageKeys.email, value, SavedValueDataType.string);
  }
}
