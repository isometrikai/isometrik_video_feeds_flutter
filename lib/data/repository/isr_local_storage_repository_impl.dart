import 'package:ism_video_reel_player/data/data.dart';
import 'package:ism_video_reel_player/domain/domain.dart';
import 'package:ism_video_reel_player/utils/utils.dart';

class IsrLocalStorageRepositoryImpl implements IsrLocalStorageRepository {
  IsrLocalStorageRepositoryImpl(this._localStorageManager);

  final LocalStorageManager _localStorageManager;

  Future<dynamic> getValue(String key, SavedValueDataType saveValueDataType) async {
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

  void saveValue(String key, dynamic value, SavedValueDataType savedValueDataType) {
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
      await _localStorageManager.getSecuredValue(LocalStorageKeys.userId);

  @override
  Future<String> getEmail() async =>
      await _localStorageManager.getSecuredValue(LocalStorageKeys.email);

  @override
  Future<bool> isLoggedIn() async =>
      await _localStorageManager.getValue(LocalStorageKeys.isLoggedIn, SavedValueDataType.bool)
          as bool;

  @override
  Future<String> getCurrencyCode() async =>
      await _localStorageManager.getSecuredValue(LocalStorageKeys.currencyCode);

  @override
  Future<String> getCurrencySymbol() async =>
      await _localStorageManager.getSecuredValue(LocalStorageKeys.currencySymbol);

  // Implementations for all keys
  @override
  Future<String> getLanguage() async =>
      await getValue(LocalStorageKeys.language, SavedValueDataType.string) as String;

  @override
  Future<String> getAccessToken() async => await getSecuredValue(LocalStorageKeys.accessToken);

  @override
  Future<String> getRefreshToken() async => await getSecuredValue(LocalStorageKeys.refreshToken);

  @override
  Future<String> getPhoneNumber() async => await getSecuredValue(LocalStorageKeys.phoneNumber);

  @override
  Future<String> getFirstName() async =>
      await getValue(LocalStorageKeys.firstName, SavedValueDataType.string) as String;

  @override
  Future<String> getLastName() async =>
      await getValue(LocalStorageKeys.lastName, SavedValueDataType.string) as String;

  @override
  Future<String> getProfilePic() async =>
      await getValue(LocalStorageKeys.profilePic, SavedValueDataType.string) as String;

  @override
  Future<String> getUserInfo() async =>
      await getValue(LocalStorageKeys.userInfo, SavedValueDataType.string) as String;

  // Implementations for setters
  @override
  void saveLanguage(String value) =>
      saveValue(LocalStorageKeys.language, value, SavedValueDataType.string);

  @override
  void saveIsLoggedIn(bool value) =>
      saveValue(LocalStorageKeys.isLoggedIn, value, SavedValueDataType.bool);

  @override
  void saveAccessToken(String value) => saveSecuredValue(LocalStorageKeys.accessToken, value);

  @override
  void saveRefreshToken(String value) => saveSecuredValue(LocalStorageKeys.refreshToken, value);

  @override
  void savePhoneNumber(String value) => saveSecuredValue(LocalStorageKeys.phoneNumber, value);

  @override
  void saveFirstName(String value) =>
      saveValue(LocalStorageKeys.firstName, value, SavedValueDataType.string);

  @override
  void saveLastName(String value) =>
      saveValue(LocalStorageKeys.lastName, value, SavedValueDataType.string);

  @override
  void saveProfilePic(String value) =>
      saveValue(LocalStorageKeys.profilePic, value, SavedValueDataType.string);

  @override
  void saveEmail(String value) {
    saveValue(LocalStorageKeys.email, value, SavedValueDataType.string);
  }
}
